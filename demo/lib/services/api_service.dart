import 'dart:convert';
import 'dart:io';
import 'package:demo/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class ApiService {
  static const String baseApiUrl = "http://10.0.2.2:8000/api";
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _cachedToken;

  var _currentUserId;

  int? get currentUserId => _currentUserId;

  // Add method to get auth headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Centralized authenticated request handler
  Future<http.Response> makeAuthenticatedRequest({
    required String url,
    required String method,
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final String? token = await getAccessToken();

    if (token == null) {
      throw Exception("User is not authenticated. No token found.");
    }

    // Prepare the headers
    final Map<String, String> requestHeaders = {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
      ...?headers,
    };

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          return await http.get(Uri.parse(url), headers: requestHeaders);
        case 'POST':
          return await http.post(Uri.parse(url),
              headers: requestHeaders, body: jsonEncode(body));
        case 'PUT':
          return await http.put(Uri.parse(url),
              headers: requestHeaders, body: jsonEncode(body));
        case 'PATCH':
          return await http.patch(Uri.parse(url),
              headers: requestHeaders, body: jsonEncode(body));
        case 'DELETE':
          return await http.delete(Uri.parse(url), headers: requestHeaders);
        default:
          throw Exception("Unsupported HTTP method: $method");
      }
    } catch (e) {
      throw Exception("Error making authenticated request: $e");
    }
  }

  // Token Management
  Future<String?> getAccessToken() async {
    if (_cachedToken != null) {
      return _cachedToken;
    }

    String? token = await _storage.read(key: "access_token");
    if (token == null) return null;

    // Decode and check expiration
    final parts = token.split('.');
    if (parts.length == 3) {
      final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload["exp"];
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (exp != null && exp < currentTime) {
        await refreshAccessToken();
        token = await _storage.read(key: "access_token");
      }
    }
    _cachedToken = token;
    return token;
  }

  Future<void> refreshAccessToken() async {
    final String? refreshToken = await _storage.read(key: "refresh_token");
    if (refreshToken == null) {
      throw Exception("No refresh token available");
    }

    const String url = "$baseApiUrl/token/refresh/";
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh": refreshToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storage.write(key: "access_token", value: data["access"]);
      _cachedToken = data["access"];
    } else {
      throw Exception("Failed to refresh token: ${response.body}");
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: "access_token");
    await _storage.delete(key: "refresh_token");
    await _storage.delete(key: "current_user_id");
    _cachedToken = null;
    _currentUserId = null;
    print("Logged out successfully.");
  }

  // Posts
  Future<List<Post>> fetchPosts() async {
    final response = await makeAuthenticatedRequest(
      url: "$baseApiUrl/posts/",
      method: 'GET',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print("Fetched Posts Response: $data"); // Log the full response
      return data.map((json) => Post.fromJson(json)).toList();
    } else {
      print("Error fetching posts: ${response.body}");
      throw Exception("Failed to fetch posts: ${response.body}");
    }
  }

  Future<Post> fetchPostDetail(int postId) async {
    final String url = "$baseApiUrl/posts/$postId/";

    try {
      // Make an authenticated GET request to fetch post details
      final response = await makeAuthenticatedRequest(
        url: url,
        method: 'GET',
      );

      if (response.statusCode == 200) {
        // Parse the response into a Post object
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return Post.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to fetch post detail. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception("Error fetching post detail: $e");
    }
  }

  Future<Map<String, dynamic>> updatePostLikes(int postId) async {
    final response = await makeAuthenticatedRequest(
      url: '$baseApiUrl/posts/$postId/like/',
      method: 'POST',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to update likes: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> updateCommentLikes(int commentId) async {
    final response = await makeAuthenticatedRequest(
      url: "$baseApiUrl/comments/$commentId/like/",
      method: 'POST',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to update likes: ${response.body}");
    }
  }

  // Comments
  Future<List<Comment>> fetchComments(int postId) async {
    final response = await makeAuthenticatedRequest(
      url: "$baseApiUrl/posts/$postId/comments/",
      method: 'GET',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Comment.fromJson(json)).toList();
    } else {
      throw Exception("Failed to fetch comments: ${response.body}");
    }
  }

  Future<Comment> addComment({
    required int postId,
    String? content,
    int? replyTo,
    String? imagePath,
  }) async {
    const String url = "$baseApiUrl/comments/";

    if (imagePath != null) {
      print("Image path provided: $imagePath");

      // Send as multipart/form-data
      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields['post'] = postId.toString()
        ..headers['Authorization'] = 'Bearer ${await getAccessToken()}';

      if (content != null && content.isNotEmpty) {
        request.fields['content'] = content;
      }
      if (replyTo != null) {
        request.fields['reply_to'] = replyTo.toString();
      }
      print('commentImagePath: $imagePath');
      request.files.add(await http.MultipartFile.fromPath(
        'comment_image',
        imagePath,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return Comment.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to add comment with image: ${response.body}");
      }
    } else {
      // Send as JSON
      final response = await makeAuthenticatedRequest(
        url: url,
        method: 'POST',
        body: {
          'post': postId.toString(),
          if (content != null) 'content': content,
          if (replyTo != null) 'reply_to': replyTo.toString(),
        },
      );

      if (response.statusCode == 201) {
        return Comment.fromJson(jsonDecode(response.body));
      } else {
        throw Exception("Failed to add comment: ${response.body}");
      }
    }
  }

  // User Management
  Future<bool> login(String username, String password) async {
    const String url = "$baseApiUrl/token/";

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storage.write(key: "access_token", value: data["access"]);
      await _storage.write(key: "refresh_token", value: data["refresh"]);
      _cachedToken = data["access"];

      // Fetch and store user info after successful login
      try {
        final userInfo = await getUserInfo();
        if (userInfo != null) {
          _currentUserId = userInfo['id'];
          await _storage.write(
              key: "current_user_id", value: _currentUserId.toString());
        }
      } catch (e) {
        print("Error fetching user info after login: $e");
      }

      return true;
    } else {
      return false;
    }
  }

  Future<void> initializeCurrentUser() async {
    if (_currentUserId == null) {
      // Try to get from storage first
      final storedId = await _storage.read(key: "current_user_id");
      if (storedId != null) {
        _currentUserId = int.parse(storedId);
      } else {
        // If not in storage, try to fetch from API
        try {
          final userInfo = await getUserInfo();
          if (userInfo != null) {
            _currentUserId = userInfo['id'];
            await _storage.write(
                key: "current_user_id", value: _currentUserId.toString());
          }
        } catch (e) {
          print("Error initializing current user: $e");
        }
      }
    }
  }

  Future<Map<String, dynamic>?> getUserInfo() async {
    final response = await makeAuthenticatedRequest(
      url: "$baseApiUrl/users/me/",
      method: 'GET',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch user info: ${response.body}");
    }
  }

  Future<Map<String, dynamic>?> getUserProfileById(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseApiUrl/users/$userId'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to fetch user profile');
    } catch (e) {
      print("Error getting user profile: $e");
      throw Exception('Failed to fetch user profile');
    }
  }

  static Future<String?> registerAUser({
    required String username,
    required String email,
    required String password,
    String? bio,
    String? profileImagePath,
  }) async {
    const String url = "$baseApiUrl/register/";
    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..fields['username'] = username
      ..fields['email'] = email
      ..fields['password'] = password;

    if (bio != null) request.fields['bio'] = bio;
    if (profileImagePath != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'profile_picture',
        profileImagePath,
      ));
    }

    final response = await request.send();
    if (response.statusCode == 201) {
      return null; // Registration successful
    } else {
      final responseBody = await response.stream.bytesToString();
      final Map<String, dynamic> responseData = jsonDecode(responseBody);
      return responseData['error'] ?? 'Unknown error occurred';
    }
  }

  Future<void> updatePostSaves(int postId, bool isSaved) async {
    final response = await makeAuthenticatedRequest(
      url: '$baseApiUrl/posts/$postId/save/',
      method: 'POST',
      body: {'is_saved': isSaved}, // Pass the save status in the request body
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update saves: ${response.body}");
    }
  }

  // In ApiService class
  Future<Map<String, dynamic>> followUser(int userId) async {
    try {
      final response = await makeAuthenticatedRequest(
        url: '$baseApiUrl/users/$userId/follow/',
        method: 'POST',
        body: {}, // Add empty body to ensure proper POST request
      );

      print("Follow response status: ${response.statusCode}"); // Debug print
      print("Follow response body: ${response.body}"); // Debug print

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to follow user: ${response.body}');
      }
    } catch (e) {
      print("Follow error: $e"); // Debug print
      rethrow;
    }
  }

  Future<List<User>> fetchUserFollowers(int userId) async {
    final response = await makeAuthenticatedRequest(
      url: '$baseApiUrl/users/$userId/followers/',
      method: 'GET',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch followers');
    }
  }

  Future<List<User>> fetchUserFollowing(int userId) async {
    try {
      print(
          'Making request to: $baseApiUrl/users/$userId/following/'); // Debug URL
      final response = await makeAuthenticatedRequest(
        url: '$baseApiUrl/users/$userId/following/',
        method: 'GET',
      );

      print('Response status: ${response.statusCode}'); // Debug status
      print('Raw response body: ${response.body}'); // Debug response

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Print the parsed data
        print('Parsed data: $data');

        // Make sure User.fromJson can handle both URL formats
        return data.map((json) {
          // If the profile picture URL doesn't have the base URL, add it
          if (json['profile_picture_url'] != null &&
              !json['profile_picture_url'].toString().startsWith('http')) {
            json['profile_picture_url'] =
                '${ApiService.baseApiUrl}${json['profile_picture_url']}';
          }
          return User.fromJson(json);
        }).toList();
      } else {
        throw Exception('Failed to fetch following users: ${response.body}');
      }
    } catch (e) {
      print('Error in fetchUserFollowing: $e'); // Debug error
      rethrow; // Use rethrow to preserve the stack trace
    }
  }

  // Add this to api_service.dart
  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    final response = await makeAuthenticatedRequest(
      url: "$baseApiUrl/users/$userId/",
      method: 'GET',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch user profile: ${response.body}");
    }
  }

  Future<Map<String, List<User>>> fetchFollowData(int userId) async {
    try {
      print('Fetching following for user $userId'); // Debug print
      final following = await fetchUserFollowing(userId);
      print('Following response: $following'); // Debug print

      print('Fetching followers for user $userId'); // Debug print
      final followers = await fetchUserFollowers(userId);
      print('Followers response: $followers'); // Debug print

      return {
        'following': following,
        'followers': followers,
      };
    } catch (e) {
      print('Original error: $e'); // Debug print
      throw Exception('Error fetching follow data: $e');
    }
  }

  // Add this method to check follow status
  Future<Map<String, dynamic>> checkFollowStatus(int userId) async {
    try {
      final response = await makeAuthenticatedRequest(
        url: '$baseApiUrl/users/$userId/',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'is_following': data['is_following'] ?? false,
        };
      } else {
        throw Exception('Failed to check follow status: ${response.body}');
      }
    } catch (e) {
      print('Error checking follow status: $e');
      rethrow;
    }
  }

  // Add this as an alternative way to follow/unfollow (if needed)
  Future<Map<String, dynamic>> toggleFollowUser(int userId) async {
    return followUser(userId); // Reuse your existing followUser method
  }

  Future<void> createPost(String title, String content, String? imagePath) async {
    const String url = "$baseApiUrl/posts/";
    // get current user information
    final userInfo = await getUserInfo();
    if (userInfo == null) {
      throw Exception('User not logged in');
    }

    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..headers['Authorization'] = 'Bearer ${await getAccessToken()}'
      ..fields['user'] = jsonEncode(userInfo)
      ..fields['title'] = title
      ..fields['content'] = content;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      var postId = jsonDecode(response.body)['id'];
      print('Post created successfully: ${jsonDecode(response.body)['id']}');

      if (imagePath != null) {
        createImage(postId, imagePath);
      }
    } else {
      throw Exception('Failed to create post: ${response.reasonPhrase}');
    }
  }

  Future<void> createImage(int postId, String imagePath) async {
    print('creating image');
    String url = "$baseApiUrl/posts/$postId/images/";
    final request = http.MultipartRequest('POST', Uri.parse(url))
    ..headers['Authorization'] = 'Bearer ${await getAccessToken()}'
    ..fields['post'] = postId.toString();

    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imagePath,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      print('success upload image: ${response.reasonPhrase}');
    } else {
      throw Exception('Failed to create post: ${response.reasonPhrase}');
    }
  }
}

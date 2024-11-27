import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class ApiService {
  static const String baseApiUrl = "http://10.0.2.2:8000/api";
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _cachedToken;

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
    _cachedToken = null;
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

  Future<void> addComment(
      {required int postId, required String content}) async {
    await makeAuthenticatedRequest(
      url: "$baseApiUrl/comments/",
      method: 'POST',
      body: {"post": postId, "content": content},
    );
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
      return true;
    } else {
      return false;
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
}

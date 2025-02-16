import 'dart:convert';
import 'package:demo/models/user_model.dart';
import 'package:demo/services/notification_service.dart';
import 'package:demo/services/notification_state.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
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

// Token Management, log in, log out
  Future<String?> getAccessToken() async {
    if (_cachedToken != null) {
      print('🔐 Using cached token');
      return _cachedToken;
    }

    String? token = await _storage.read(key: "access_token");
    if (token == null) {
      print('❌ No access token found');
      return null;
    }

    print('🔍 Token details:');
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = jsonDecode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));

        print('Token Payload: $payload');
        final exp = payload["exp"];
        final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        print('Expiration: $exp');
        print('Current Time: $currentTime');

        if (exp != null && exp < currentTime) {
          print('🕰️ Token expired, refreshing...');
          await refreshAccessToken();
          token = await _storage.read(key: "access_token");
        }
      }
    } catch (e) {
      print('❌ Error parsing token: $e');
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

  Future<bool> login(String username, String password) async {
    const String url = "$baseApiUrl/token/";
    final NotificationService notificationService = NotificationService();

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

        await notificationService.fetchNotifications();
      } catch (e) {
        print("Error fetching user info after login: $e");
      }

      return true;
    } else {
      return false;
    }
  }

  Future<void> logout() async {
    NotificationService().reset();
    var notificationState = NotificationState();
    notificationState.setUnreadStatus(false);
    await _storage.delete(key: "access_token");
    await _storage.delete(key: "refresh_token");
    await _storage.delete(key: "current_user_id");
    _cachedToken = null;
    _currentUserId = null;
    print("Logged out successfully.");
  }

// Fetch data section
  Future<List<Post>> fetchPosts({
    List<String>? travelTypes,
    List<String>? periods,
  }) async {
    String? url = "$baseApiUrl/posts/";

    // Add travel types and periods as query parameters
    final queryParams = <String>[];
    if (travelTypes != null && travelTypes.isNotEmpty) {
      queryParams.add("travel_types=${travelTypes.join(',')}");
    }
    if (periods != null && periods.isNotEmpty) {
      queryParams.add("periods=${periods.join(',')}");
    }

    if (queryParams.isNotEmpty) {
      url += "?${queryParams.join('&')}";
    }

    print("Request URL: $url"); // Debug the URL

    final response = await makeAuthenticatedRequest(
      url: url,
      method: 'GET',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // print("Fetched Posts Response: $data"); // Log the full response

      final posts = data.map((json) => Post.fromJson(json)).toList();

      // 🔥 Force UI update with childPosts if they were null before
      // for (var post in posts) {
      //   if (post.period == "multipleday" && post.childPosts!.isEmpty) {
      //     print("❌ Missing childPosts in Post ID: ${post.id}");
      //   } else {
      //     print(
      //         "✅ Post ID: ${post.id} has ${post.childPosts!.length} child posts");
      //   }
      // }
      return posts;
    } else {
      // print("Error fetching posts: ${response.body}");
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

      print("✅ Raw API Response: ${response.body}"); // Debugging Step

      if (response.statusCode == 200) {
        // Parse the response into a Post object
        if (response.body.isEmpty) {
          throw Exception("Empty response from the server");
        }
        final Map<String, dynamic> jsonData = jsonDecode(response.body);

        // ✅ Debug childPosts before parsing
        print("📌 Child Posts Data: ${jsonData['childPosts']}");

        print("Fetched post: ${response.body}");

        // Process the childPosts if they exist
        if (jsonData['childPosts'] != null) {
          jsonData['childPosts'] = (jsonData['childPosts'] as List)
              .map((childJson) => Post.fromJson(childJson))
              .toList();
        } else {
          jsonData['childPosts'] = (jsonData['childPosts'] as List?)
                  ?.map((childJson) => Post.fromJson(childJson))
                  .toList() ??
              [];
        }

        return Post.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to fetch post detail. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception("Error fetching post detail: $e");
    }
  }

//Update post detail section
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

  Future<Map<String, dynamic>> updatePostSaves(int postId) async {
    final response = await makeAuthenticatedRequest(
      url: '$baseApiUrl/posts/$postId/save/',
      method: 'POST',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to update saves: ${response.body}");
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

// Comment section
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

// Profile section
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

// Create post section
  Future<void> createPost({
    required String title,
    required String? category,
    List<String>? imagePaths,
    required String locationName,
    double? latitude,
    double? longitude,
    String? content,
    required String period,
    List<Map<String, dynamic>>? multiDayTrips,
  }) async {
    const String url = "$baseApiUrl/posts/";

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));

      request.headers['Authorization'] = 'Bearer ${await getAccessToken()}';

      if (locationName.isEmpty) {
        throw Exception('Location name cannot be empty');
      }
      final locationData = {
        'place_id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
        'name': locationName,
        'address': locationName,
        'latitude': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
      };

      // ✅ Print Location Data for Debugging
      print("📍 Constructed Location Data: ${jsonEncode(locationData)}");

      // Common fields
      request.fields['title'] = title;
      request.fields['location'] = jsonEncode(locationData);
      request.fields['category'] = category ?? '';
      request.fields['status'] = 'published';
      request.fields['visibility'] = 'public';
      request.fields['period'] = period;
      request.fields['content'] = '';

      print('API - period: ${period}');

      // ✅ Print Multi-Day Trips Debug Info
      if (multiDayTrips != null) {
        print("📤 Sending Multi-Day Trips to Backend:");
        for (var trip in multiDayTrips) {
          print("Day: ${jsonEncode(trip)}");
        }
      } else {
        print("❌ No Multi-Day Trips Found!");
      }

      if (period == 'multipleday') {
        // Multi-Day specific fields
        request.fields['child_posts'] = jsonEncode(multiDayTrips ?? []);
      } else {
        // Single-Day specific fields
        request.fields['content'] = content ?? '';
      }

      // Add images if provided
      if (imagePaths != null) {
        for (String path in imagePaths) {
          request.files.add(await http.MultipartFile.fromPath('image', path));
        }
      }

      // ✅ Attach Child Post Images
      if (multiDayTrips != null) {
        for (var i = 0; i < multiDayTrips.length; i++) {
          var day = multiDayTrips[i];
          var imageList = day['imagePaths'] as List<String>?;

          if (imageList != null) {
            print(
                "📸 Attaching ${imageList.length} images for child post $i...");
            for (String imagePath in imageList) {
              print("✅ Attaching Image Path: $imagePath"); // Debugging print
              request.files.add(
                await http.MultipartFile.fromPath('childImages_$i', imagePath),
              );
            }
          }
        }
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // ✅ Debugging response
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode != 201) {
        throw Exception('Failed to create post: ${response.body}');
      }

      // ✅ Fetch post details again to ensure `childPosts` are included
      final responseData = jsonDecode(response.body);
      int parentPostId = responseData['post']['id'];

      // Fetch the post again to ensure childPosts are present
      await Future.delayed(
          Duration(seconds: 1)); // Give backend time to process
      await fetchPostDetail(parentPostId);

      print('Post created successfully: ${response.body}');
    } catch (e) {
      print('Error creating post: $e');
      throw Exception('Failed to create post: $e');
    }
  }

  Future<List<Post>> fetchPostsByLocation(String locationName) async {
    final response = await http.get(
      Uri.parse(
          '$baseApiUrl/posts/by-location/?name=${Uri.encodeComponent(locationName)}'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((post) => Post.fromJson(post)).toList();
    } else {
      throw Exception('Failed to load posts for this location');
    }
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

// Get current Location
  Future<Position> getCurrentLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    // Check if we have permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<List<Post>> fetchNearbyPosts({
    required double latitude,
    required double longitude,
    double radius = 5,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
        'limit': limit.toString(),
      };

      final String url =
          '$baseApiUrl/posts/nearby/?${Uri(queryParameters: queryParams).query}';
      print('🔍 Fetching nearby posts from: $url');

      final response = await makeAuthenticatedRequest(
        url: url,
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Found ${data['posts'].length} nearby posts');
        return (data['posts'] as List)
            .map((json) => Post.fromJson(json))
            .toList();
      } else {
        print('❌ Error fetching nearby posts: ${response.body}');
        throw Exception('Failed to fetch nearby posts: ${response.body}');
      }
    } catch (e) {
      print('❌ Error in fetchNearbyPosts: $e');
      throw Exception('Failed to fetch nearby posts');
    }
  }

// Notifications

  Future<void> registerDeviceToken({int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        FirebaseMessaging messaging = FirebaseMessaging.instance;
        String? token = await messaging.getToken();

        if (token == null) {
          print("❌ Failed to get FCM Token.");
          continue;
        }

        print("🔥 FCM Token: $token");

        String? accessToken = await getAccessToken();
        if (accessToken == null) {
          print("❌ User is not authenticated. Cannot register device.");
          return;
        }

        final response = await http.post(
          Uri.parse("$baseApiUrl/register-device/"),
          headers: {
            "Authorization": "Bearer $accessToken",
            "Content-Type": "application/json"
          },
          body: jsonEncode({
            "token": token,
            "device_type": "android", // Add device type
            "app_version": "1.0.0" // Add app version
          }),
        );

        if (response.statusCode == 200) {
          print("✅ Device registered successfully: ${response.body}");
          return; // Success, exit the function
        } else {
          print("⚠️ Failed to register device. Status: ${response.statusCode}");
          print("⚠️ Response: ${response.body}");
          if (i < retryCount - 1) {
            await Future.delayed(
                Duration(seconds: 2 * (i + 1))); // Exponential backoff
          }
        }
      } catch (e) {
        print("❌ Error registering device: $e");
        if (i < retryCount - 1) {
          await Future.delayed(Duration(seconds: 2 * (i + 1)));
        }
      }
    }

    print("❌ Failed to register device after $retryCount attempts");
  }
}

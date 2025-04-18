import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:demo/models/user_model.dart';
import 'package:demo/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../models/message_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() {
    return _instance;
  }
  ApiService._internal() {
    print("🔧 Creating new ApiService instance");
  }
  //Deployment
  // static const String baseApiUrl = "http://10.0.2.2:8000/api";
  static const String baseApiUrl = "http://54.89.74.130:8000/api";
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String? _cachedToken;

  var _currentUserId;

  int? get currentUserId => _currentUserId;
  LatLng? _lastKnownLocation;

// Add method to get auth headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

// Token Management, log in, log out
  Future<String?> getAccessToken() async {
    if (_cachedToken != null) {
      print('🔐 Using cached token: ${_cachedToken!.substring(0, 20)}...');
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
    return _cachedToken;
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
    print("🔐 Logging in as: $username");

    // Ensure complete logout before logging in a new user
    await logout();

    const String url = "$baseApiUrl/token/";
    final NotificationService notificationService = NotificationService();

    try {
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

            print("✅ Login successful for user ID: $_currentUserId");

            // Initialize notification service AFTER user is confirmed
            await notificationService.initialize(userId: _currentUserId);
            await notificationService.fetchNotifications();
          }
        } catch (e) {
          print("Error fetching user info after login: $e");
        }

        return true;
      } else {
        print("❌ Login failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Login error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    print("🔴 Logging out...");

    // Step 1: Reset notification service FIRST
    NotificationService().reset();

    // Step 2: Ensure Firebase Auth is signed out
    try {
      await FirebaseAuth.instance.signOut();
      print("✅ FirebaseAuth: User signed out.");
    } catch (e) {
      print("⚠️ FirebaseAuth signout error: $e");
    }

    // Step 3: Unregister FCM token on backend
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        print('🔄 Unregistering FCM token on logout...');
        try {
          final token = await getAccessToken();
          if (token != null) {
            final response = await http.post(
              Uri.parse('${ApiService.baseApiUrl}/register-device/'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({"token": fcmToken, "unregister": true}),
            );

            if (response.statusCode == 200) {
              print('✅ Device unregistered successfully');
            } else {
              print(
                  '⚠️ Failed to unregister device. Response: ${response.body}');
            }
          }
        } catch (e) {
          print('⚠️ Failed to unregister device: $e');
        }
      }
    } catch (e) {
      print("⚠️ FCM token error: $e");
    }

    // Step 4: Delete FCM token locally
    try {
      await FirebaseMessaging.instance.deleteToken();
      print("✅ FCM token deleted.");
    } catch (e) {
      print("⚠️ Error deleting FCM token: $e");
    }

    // Step 5: Clear all local storage
    try {
      await _storage.deleteAll();
      _cachedToken = null;
      _currentUserId = null;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print("✅ Local storage cleared.");
    } catch (e) {
      print("⚠️ Error clearing storage: $e");
    }

    // Final verification
    print("✅ Logout completed. User ID is now: $_currentUserId");
  }

  Future<T> retryWithBackoff<T>({
    required Future<T> Function() operation,
    required String operationName,
    int maxRetries = 3,
    Duration initialBackoff = const Duration(seconds: 1),
  }) async {
    int retryCount = 0;
    Duration backoff = initialBackoff;

    while (true) {
      try {
        if (retryCount > 0) {
          print('🔄 Retry attempt #$retryCount for $operationName');
        }

        // For nearby posts, use a more aggressive timeout strategy
        if (operationName.contains("nearby")) {
          // Use a timeout that scales based on retry count
          final timeout = Duration(seconds: 15 + (retryCount * 2));
          return await operation().timeout(timeout);
        } else {
          return await operation();
        }
      } on TimeoutException catch (e) {
        if (retryCount >= maxRetries) {
          print('❌ Max retries reached for $operationName');
          rethrow;
        }

        print(
            '⏱️ Operation $operationName timed out. Retrying in ${backoff.inSeconds}s...');
        retryCount++;
        await Future.delayed(backoff);

        // Exponential backoff but with a cap
        backoff = Duration(
            milliseconds:
                min(backoff.inMilliseconds * 2, 5000)); // Cap at 5 seconds
      } catch (e) {
        // For other errors, don't retry
        print('❌ Error in $operationName: $e');
        rethrow;
      }
    }
  }

  Future<List<Post>> fetchPostsBySource({
    required String source,
    double? latitude,
    double? longitude,
    double radius = 5,
    int limit = 20,
    List<String>? travelTypes,
    List<String>? periods,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    // For nearby posts, use a more aggressive caching strategy
    if (source == 'nearby') {
      // Check if we have cached nearby posts that are less than 5 minutes old
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final cachedTimestamp = prefs.getInt('nearby_cache_timestamp');

      // If we have a recent cache (less than 5 minutes old)
      if (cachedTimestamp != null &&
          DateTime.now().millisecondsSinceEpoch - cachedTimestamp < 300000) {
        final cachedData = prefs.getString('nearby_cache_data');

        if (cachedData != null) {
          try {
            final dynamic data = jsonDecode(cachedData);
            List<dynamic> postsList;

            if (data is List) {
              postsList = data;
            } else if (data is Map && data.containsKey('posts')) {
              // Some responses might wrap posts in a map with 'posts' key
              postsList = data['posts'] as List;
            } else {
              // For any other format, just skip cache
              throw FormatException('Invalid cache format');
            }

            final cachedPosts = postsList
                .map((json) => Post.fromJson(json as Map<String, dynamic>))
                .toList();

            print('✅ Using cached nearby posts: ${cachedPosts.length}');

            // Start a background refresh of the cache
            _refreshNearbyPostsCache(
                latitude, longitude, radius, travelTypes, periods);

            return cachedPosts;
          } catch (e) {
            print('❌ Error parsing cached posts: $e');
            // Continue with normal fetch if cache parsing fails
          }
        }
      }
    }

    return retryWithBackoff<List<Post>>(
      operationName: "Fetch $source posts",
      operation: () async {
        try {
          String url = '$baseApiUrl/posts/'; // Default to 'explore'

          // Handle different sources
          if (source == 'nearby') {
            if (latitude == null || longitude == null) {
              throw Exception(
                  'Latitude and Longitude are required for nearby posts');
            }
            url =
                '$baseApiUrl/posts/nearby/?latitude=$latitude&longitude=$longitude&radius=$radius';
          } else if (source == 'follow') {
            url = '$baseApiUrl/posts/follow/';
          }

          // Attach filters dynamically
          final Map<String, String> queryParams = {
            if (travelTypes != null && travelTypes.isNotEmpty)
              'travel_types': travelTypes.join(','),
            if (periods != null && periods.isNotEmpty)
              'periods': periods.join(','),
            'limit': limit.toString(),
          };

          // Ensure URL formatting is correct
          if (queryParams.isNotEmpty) {
            final queryString = Uri(queryParameters: queryParams).query;
            url += url.contains('?') ? '&$queryString' : '?$queryString';
          }

          print('🔍 Fetching $source posts from: $url');

          final response = await makeAuthenticatedRequest(
            url: url,
            method: 'GET',
            timeout: timeout,
          );

          if (response.statusCode == 200) {
            final String responseBody = response.body;

            // Debug response body (prints first 200 characters)
            print(
                "✅ API Response: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}");

            final dynamic data = jsonDecode(responseBody);

            // If this is a nearby request, cache the results
            if (source == 'nearby') {
              _cacheNearbyPosts(responseBody);
            }

            // Handling LIST response (if API returns a list of posts directly)
            if (data is List) {
              final List<Post> posts = data
                  .map((json) => Post.fromJson(json as Map<String, dynamic>))
                  .toList();
              print('✅ Found ${posts.length} $source posts');
              return posts;
            }

            // Handling MAP response (if API wraps posts inside a key)
            else if (data is Map<String, dynamic> &&
                data.containsKey('posts') &&
                data['posts'] is List) {
              final List<Post> posts = (data['posts'] as List)
                  .map((json) => Post.fromJson(json as Map<String, dynamic>))
                  .toList();
              print('✅ Found ${posts.length} $source posts');
              return posts;
            } else {
              print('❌ Unexpected API response structure: $data');
              throw Exception('Unexpected API response format');
            }
          } else {
            print('❌ Error fetching $source posts: ${response.body}');
            throw Exception('Failed to fetch $source posts: ${response.body}');
          }
        } on TimeoutException catch (e) {
          print('⏱️ Timeout fetching $source posts: $e');
          rethrow; // Rethrow timeout exception to trigger retry
        } catch (e) {
          print('❌ Error in fetchPostsBySource: $e');
          rethrow; // Rethrow to allow the retry mechanism to work properly
        }
      },
      maxRetries: source == 'nearby' ? 2 : 3, // Fewer retries for nearby
      initialBackoff: const Duration(seconds: 1),
    );
  }

  Future<void> _cacheNearbyPosts(String responseBody) async {
    try {
      // Before saving, verify the format is correct
      final dynamic data = jsonDecode(responseBody);

      if (!(data is List || (data is Map && data.containsKey('posts')))) {
        print('⚠️ Skipping cache: unexpected data format');
        return;
      }
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('nearby_cache_data', responseBody);
      await prefs.setInt(
          'nearby_cache_timestamp', DateTime.now().millisecondsSinceEpoch);
      print('✅ Cached nearby posts successfully');
    } catch (e) {
      print('❌ Error caching nearby posts: $e');
    }
  }

// Helper method to refresh the cache in the background
  Future<void> _refreshNearbyPostsCache(double? latitude, double? longitude,
      double radius, List<String>? travelTypes, List<String>? periods) async {
    // Don't await this - let it run in background
    try {
      String url =
          '$baseApiUrl/posts/nearby/?latitude=$latitude&longitude=$longitude&radius=$radius';

      // Add filters
      final Map<String, String> queryParams = {
        if (travelTypes != null && travelTypes.isNotEmpty)
          'travel_types': travelTypes.join(','),
        if (periods != null && periods.isNotEmpty) 'periods': periods.join(','),
      };

      if (queryParams.isNotEmpty) {
        final queryString = Uri(queryParameters: queryParams).query;
        url += url.contains('?') ? '&$queryString' : '?$queryString';
      }

      final response = await makeAuthenticatedRequest(
        url: url,
        method: 'GET',
        timeout: const Duration(
            seconds: 30), // Longer timeout for background refresh
      );

      if (response.statusCode == 200) {
        _cacheNearbyPosts(response.body);
      }
    } catch (e) {
      print('⚠️ Background cache refresh failed: $e');
      // Silently fail - this is just a background refresh
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
        // print("📌 Child Posts Data: ${jsonData['childPosts']}");

        // print("Fetched post: ${response.body}");

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

  static Future<Map<String, dynamic>?> registerAUser({
    required String username,
    required String email,
    required String password,
    String? bio,
    String? profileImagePath,
  }) async {
    const String url = "$baseApiUrl/register/";

    try {
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

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return responseData; // ✅ Return full response as Map
      } else {
        print("❌ Registration failed: ${response.body}");

        // Handle nested error format
        if (responseData.containsKey('error')) {
          final errors = responseData['error'];

          if (errors is Map<String, dynamic>) {
            // This matches your specific error format
            return {"error": errors};
          } else {
            return {"error": errors.toString()};
          }
        }

        return {"error": responseData['error'] ?? 'Unknown error occurred'};
      }
    } catch (e) {
      print("❌ Registration exception: $e");
      return {"error": "Connection error: $e"};
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
      return {
        'following': [],
        'followers': [],
      };
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

  Future<Position> getCurrentLocation(
      {Duration timeout = const Duration(seconds: 10)}) async {
    try {
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

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        // Cache the last known position so we can use it if we timeout
        cacheLocation(lastKnown.latitude, lastKnown.longitude);
      }

      // Get current position with timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.medium, // Use medium accuracy for faster results
      ).timeout(timeout, onTimeout: () {
        // If we have a last known position, use it instead of crashing
        if (lastKnown != null) {
          print('✅ Location request timed out, using last known position');
          return lastKnown;
        }
        throw TimeoutException(
            'Location request timed out after ${timeout.inSeconds} seconds');
      });
    } catch (e) {
      print('❌ Error in getCurrentLocation: $e');
      rethrow;
    }
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: "access_token", value: token);
    _cachedToken = token;
  }

// Messenger
  Future<int?> getCurrentUserId() async {
    try {
      // Always get the fresh user ID from the token first
      final String? token = await getAccessToken();
      if (token != null) {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = jsonDecode(
              utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));

          if (payload.containsKey('user_id')) {
            final tokenUserId = payload['user_id'];
            // Update cache with the value from token
            _currentUserId = tokenUserId;
            await _storage.write(
                key: "current_user_id", value: tokenUserId.toString());
            print('📝 User ID from token: $tokenUserId');
            return tokenUserId;
          }
        }
      }

      // If we couldn't get it from token, use cached value as fallback
      if (_currentUserId != null) {
        print('🔍 Using cached current user ID: $_currentUserId');
        return _currentUserId;
      }

      // Last resort: check storage
      String? storedId = await _storage.read(key: "current_user_id");
      if (storedId != null) {
        _currentUserId = int.tryParse(storedId);
        if (_currentUserId != null) {
          print('🔐 Retrieved current user ID from storage: $_currentUserId');
          return _currentUserId;
        }
      }

      // If we still don't have an ID, fetch from API
      print('🌐 Fetching current user ID from API...');
      final response = await makeAuthenticatedRequest(
        url: "$baseApiUrl/users/me/",
        method: "GET",
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('id')) {
          _currentUserId = data['id'];
          await _storage.write(
              key: "current_user_id", value: _currentUserId.toString());
          print('✅ Successfully fetched user ID from API: $_currentUserId');
          return _currentUserId;
        }
      }

      return null;
    } catch (e) {
      print('❌ Error determining current user ID: $e');
      return null;
    }
  }

  // **1. Fetch Messages Between Users**
  Future<List<dynamic>> fetchConversations() async {
    try {
      print('🌐 Requesting conversations from backend...');

      final response = await makeAuthenticatedRequest(
        url: "$baseApiUrl/messages/conversations/",
        method: "GET",
      );

      print(
          '📥 Raw API Response (Status: ${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('✅ Successfully loaded conversations: ${data.length}');
        return data;
      } else {
        print('❌ Failed to fetch conversations. Error: ${response.body}');
        throw Exception("Failed to load conversations");
      }
    } catch (e) {
      print('❌ Exception in fetchConversations: $e');
      rethrow;
    }
  }

  // **2. Fetch Messages with a User**
  Future<List<Message>> fetchMessages(int otherUserId) async {
    final response = await makeAuthenticatedRequest(
      url: '$baseApiUrl/messages/?other_user_id=$otherUserId',
      method: 'GET',
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception("Failed to load messages");
    }
  }

  // **2. Send a Message**
  Future<void> sendMessage(int receiverId, String content) async {
    final response = await makeAuthenticatedRequest(
      url: '$baseApiUrl/messages/send/',
      method: 'POST',
      body: {
        "receiver": receiverId,
        "content": content,
      },
    );

    if (response.statusCode != 201) {
      throw Exception("Failed to send message");
    }
  }

  // **3. Mark a Message as Read**
  Future<void> markMessageAsRead(int messageId) async {
    final response = await makeAuthenticatedRequest(
      url: '$baseApiUrl/messages/$messageId/mark-read/',
      method: 'PATCH',
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to mark message as read");
    }
  }

  Future<void> registerDeviceToken(String token) async {
    final response = await makeAuthenticatedRequest(
      url: '$baseApiUrl/register-device/',
      method: 'POST',
      body: {"token": token},
    );

    if (response.statusCode == 200) {
      print('✅ Device token registered successfully');
    } else {
      print('❌ Failed to register device token: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchUserProfile(int userId) async {
    try {
      final response = await makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/users/$userId/',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('❌ Error fetching user profile: $e');
    }
    return {};
  }

  //S3 uploading
  String transformS3Url(String? url) {
    if (url == null || url.isEmpty) {
      return '';
    }

    try {
      // print('🔍 S3 URL before transform: $url');

      String transformedUrl = url;

      // Handle .s3.amazonaws.com format without region
      if (url.contains('.s3.amazonaws.com')) {
        transformedUrl = url.replaceFirst(
            '.s3.amazonaws.com', '.s3.us-east-1.amazonaws.com');
      }

      // print('✅ S3 URL after transform: $transformedUrl');
      return transformedUrl;
    } catch (e) {
      print('❌ Error transforming S3 URL: $e');
      return '';
    }
  }

  Future<http.Response> makeAuthenticatedRequest({
    required String url,
    required String method,
    Map<String, String>? headers,
    dynamic body,
    Duration timeout =
        const Duration(seconds: 15), // Add timeout parameter with default value
  }) async {
    // Check if this is an S3 URL - if so, don't add auth headers
    final bool isS3Url = url.contains('amazonaws.com');

    // Prepare the headers - no auth for S3
    final Map<String, String> requestHeaders;

    if (isS3Url) {
      // For S3, don't include auth headers
      requestHeaders = {
        "Content-Type": "application/json",
        ...?headers,
      };
    } else {
      // For regular API endpoints, include auth
      final String? token = await getAccessToken();
      if (token == null) {
        throw Exception("User is not authenticated. No token found.");
      }

      requestHeaders = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        ...?headers,
      };
    }

    try {
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(Uri.parse(url), headers: requestHeaders)
              .timeout(timeout); // Add timeout
          break;
        case 'POST':
          response = await http
              .post(
                Uri.parse(url),
                headers: requestHeaders,
                body: jsonEncode(body),
              )
              .timeout(timeout); // Add timeout
          break;
        case 'PUT':
          response = await http
              .put(
                Uri.parse(url),
                headers: requestHeaders,
                body: jsonEncode(body),
              )
              .timeout(timeout); // Add timeout
          break;
        case 'PATCH':
          response = await http
              .patch(
                Uri.parse(url),
                headers: requestHeaders,
                body: jsonEncode(body),
              )
              .timeout(timeout); // Add timeout
          break;
        case 'DELETE':
          response = await http
              .delete(Uri.parse(url), headers: requestHeaders)
              .timeout(timeout); // Add timeout
          break;
        default:
          throw Exception("Unsupported HTTP method: $method");
      }

      return response;
    } on TimeoutException {
      throw TimeoutException(
          "Request to $url timed out after ${timeout.inSeconds} seconds");
    } catch (e) {
      throw Exception("Error making authenticated request: $e");
    }
  }

  Future<LatLng?> getCachedLocation() async {
    try {
      // First try to get the in-memory cached location
      if (_lastKnownLocation != null) {
        print('✅ Using in-memory cached location');
        return _lastKnownLocation;
      }

      // Then try to get from device's last known position (fast, no network needed)
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        print('✅ Using device last known position');
        return LatLng(lastPosition.latitude, lastPosition.longitude);
      }

      // If both failed, try from shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('cached_location_lat');
      final lng = prefs.getDouble('cached_location_lng');

      if (lat != null && lng != null) {
        print('✅ Using stored cached location');
        return LatLng(lat, lng);
      }

      print('❌ No cached location available');
      return null;
    } catch (e) {
      print('❌ Error getting cached location: $e');
      return null;
    }
  }

  Future<void> cacheLocation(double lat, double lng) async {
    print('💾 Caching location: $lat, $lng');
    _lastKnownLocation = LatLng(lat, lng);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('cached_location_lat', lat);
      await prefs.setDouble('cached_location_lng', lng);
      print('✅ Location cached successfully');
    } catch (e) {
      print('⚠️ Error caching location: $e');
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:demo/models/comment_model.dart';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseApiUrl = "http://10.0.2.2:8000/api";
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Fetch posts
  Future<List<Post>> fetchPosts() async {
    final String url = "$baseApiUrl/posts/";

    // Get the access token from secure storage
    String? token = await getAccessToken();

    print('Fetching posts from: $url'); // Debugging URL
    print('Access Token: $token'); // Debugging token

    try {
      // Make the GET request with Authorization header
      final response = await http.get(
        Uri.parse(url),
        headers: {
          if (token != null) "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Check if the response status code indicates success
      if (response.statusCode == 200) {
        // Decode the JSON response
        List<dynamic> data = json.decode(response.body);

        // // Log the response body for debugging purposes
        // print('Response status: ${response.statusCode}');
        // print('API Response: ${response.body}');

        // Map the JSON data to a list of Post objects
        List<Post> posts = data.map((json) => Post.fromJson(json)).toList();

        // Log each post title and number of comments for debugging
        for (var post in posts) {
          print(
              'Post: ${post.title}, Comments: ${post.detailedComments.length}');
        }

        return posts;
      } else {
        // Throw an exception if the server response is not successful
        throw Exception(
            'Failed to load posts. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // Log the error and return an empty list
      print('Error fetching posts: $e');
      return [];
    }
  }

  Future<List<Comment>> fetchComments(int postId) async {
    final String url = "$baseApiUrl/posts/$postId/comments/";

    // Get the access token from secure storage
    String? token = await getAccessToken();

    print('Fetching comments from: $url'); // Debugging URL
    print('Access Token: $token'); // Debugging token

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          if (token != null) "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        // Map the JSON data to a list of Comment objects
        return data.map((json) => Comment.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load comments. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching comments: $e');
      return [];
    }
  }

  // Add comment
  Future<http.Response> addComment({
    required int postId,
    required String content,
  }) async {
    final String url = "$baseApiUrl/comments/";

    String? token = await getAccessToken();
    if (token == null) {
      throw Exception("User is not authenticated. No token found.");
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "post": postId,
          "content": content,
        }),
      );

      return response;
    } catch (e) {
      print("Error adding comment: $e");
      rethrow;
    }
  }

  // Update likes for a post
  Future<void> updatePostLikes(int postId, bool isLiked) async {
    final String url = "$baseApiUrl/posts/$postId/like/";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'is_liked': isLiked}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update likes');
      }
    } catch (e) {
      print('Error updating likes: $e');
    }
  }

  // Update saves for a post
  Future<void> updatePostSaves(int postId, bool isSaved) async {
    final String url = "$baseApiUrl/posts/$postId/save/";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'is_saved': isSaved}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update saves');
      }
    } catch (e) {
      print('Error updating saves: $e');
    }
  }

  // Update comments count
  Future<void> updateCommentsCount(int postId, int newCount) async {
    final String url = "$baseApiUrl/posts/$postId/comments_count/";

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'comments_count': newCount}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update comments count');
      }
    } catch (e) {
      print('Error updating comments count: $e');
    }
  }

  // Register a new user
  static Future<String?> registerAUser({
    required String username,
    required String email,
    required String password,
    String? bio,
    String? profileImagePath,
  }) async {
    const String url = "$baseApiUrl/register/";

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['username'] = username;
      request.fields['email'] = email;
      request.fields['password'] = password;

      if (bio != null) {
        request.fields['bio'] = bio;
      }

      if (profileImagePath != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'profile_picture',
          profileImagePath,
        ));
      }

      var response = await request.send();

      if (response.statusCode == 201) {
        return null; // Registration successful
      } else if (response.statusCode == 400) {
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> responseData = jsonDecode(responseBody);
        if (responseData.containsKey('error')) {
          return responseData['error'].toString();
        }
        return 'Unknown error occurred';
      } else {
        throw Exception('Unexpected error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Login function to get tokens
  Future<bool> login(String username, String password) async {
    const String url = "$baseApiUrl/token/";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: "access_token", value: data["access"]);
        await _storage.write(key: "refresh_token", value: data["refresh"]);
        return true; // Login successful
      } else {
        return false; // Login failed
      }
    } catch (e) {
      throw Exception("Failed to login: $e");
    }
  }

  // Get stored access token
  Future<String?> getAccessToken() async {
    String? token = await _storage.read(key: "access_token");
    if (token == null) {
      print("No access token found.");
      return null;
    }

    // Decode token to check expiration
    final parts = token.split('.');
    if (parts.length == 3) {
      final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload["exp"];
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (exp != null && exp < currentTime) {
        print("Access token expired, refreshing...");
        await refreshAccessToken();
        token = await _storage.read(key: "access_token");
      }
    }

    print("Retrieved access token: $token");
    return token;
  }

  // Get stored refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: "refresh_token");
  }

  // Refresh access token
  Future<void> refreshAccessToken() async {
    final String? refreshToken = await getRefreshToken();

    if (refreshToken == null) {
      throw Exception("No refresh token available");
    }

    const String url = "$baseApiUrl/token/refresh/";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "refresh": refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: "access_token", value: data["access"]);
      } else {
        throw Exception("Failed to refresh token");
      }
    } catch (e) {
      throw Exception("Token refresh error: $e");
    }
  }

  // Logout by clearing all tokens
  Future<void> logout() async {
    await _storage.delete(key: "access_token");
    await _storage.delete(key: "refresh_token");
    print("Tokens cleared successfully.");
  }

  // Get user Info
  Future<Map<String, dynamic>?> getUserInfo() async {
    final String url = "$baseApiUrl/users/me/";

    print("Getting user info is called ");

    // Get the access token from secure storage
    String? token = await getAccessToken();

    if (token == null) {
      print("User is not authenticated.");
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        // Return the parsed user info as a map
        return json.decode(response.body);
      } else {
        print("Failed to fetch user info: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error fetching user info: $e");
      return null;
    }
  }
}

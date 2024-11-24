import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';

class ApiService {
  static const String baseApiUrl = "http://10.0.2.2:8000/api";

  // Fetch posts
  Future<List<Post>> fetchPosts() async {
    final String url = "$baseApiUrl/posts/";

    try {
      // Make the GET request
      final response = await http.get(Uri.parse(url));

      // Check if the response status code indicates success
      if (response.statusCode == 200) {
        // Decode the JSON response
        List<dynamic> data = json.decode(response.body);

        // Log the response body for debugging purposes
        print('API Response: ${response.body}');

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

  // Add comment
  Future<http.Response> addComment({
    required int postId,
    required int userId,
    required String content,
    int? parentId,
  }) async {
    final String url = "$baseApiUrl/comments/";

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(url),
    );

    request.fields['post'] = postId.toString();
    request.fields['user'] = userId.toString();
    request.fields['content'] = content;
    if (parentId != null) {
      request.fields['parent'] = parentId.toString();
    }

    final response = await request.send();
    return http.Response.fromStream(response);
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
}

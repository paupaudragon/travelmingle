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
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('API Response: ${response.body}');
        final posts = data.map((json) => Post.fromJson(json)).toList();
        posts.forEach((post) =>
            print('Post: ${post.title}, Comments: ${post.comments.length}'));

        return posts;
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
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
}

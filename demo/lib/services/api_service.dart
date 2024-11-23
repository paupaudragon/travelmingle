import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';

class ApiService {
  // final String apiUrl = 'http://localhost:8000/api/posts';
  final String apiUrl = 'http://10.0.2.2:8000/api/posts/';

  Future<List<Post>> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print('API Response: ${response.body}');
        final posts = data.map((json) => Post.fromJson(json)).toList();
        posts.forEach((post) =>
            print('Post: ${post.title}, Comments: ${post.comments.length}'));

        // data.forEach((json) => print('Post JSON: $json'));
        return posts;
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      // print('Error fetching posts: $e');
      return [];
    }
  }

  // http.MultipartRequest createMultipartRequest({
  //   required String endpoint,
  //   required Map<String, String> fields,
  //   required String fileField,
  //   required String? filePath,
  // }) {
  //   final uri = Uri.parse('http://10.0.2.2:8000/api/$endpoint');
  //   final request = http.MultipartRequest('POST', uri);

  //   fields.forEach((key, value) {
  //     if (value.isNotEmpty) {
  //       request.fields[key] = value;
  //     }
  //   });

  //   if (filePath != null) {
  //     request.files.add(
  //       http.MultipartFile.fromBytes(
  //         fileField,
  //         File(filePath).readAsBytesSync(),
  //         filename: filePath.split('/').last,
  //       ),
  //     );
  //   }

  //   return request;
  // }

  Future<http.Response> addComment({
    required int postId,
    required int userId,
    required String content,
    int? parentId,
    // File? image,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://127.0.0.1:8000/api/comments/'),
    );

    request.fields['post'] = postId.toString();
    request.fields['user'] = userId.toString();
    request.fields['content'] = content;
    if (parentId != null) {
      request.fields['parent'] = parentId.toString();
    }

    // if (image != null) {
    //   request.files.add(await http.MultipartFile.fromPath('image', image.path));
    // }

    final response = await request.send();
    return http.Response.fromStream(response);
  }

// Update likes for a post
  Future<void> updatePostLikes(int postId, bool isLiked) async {
    final url = Uri.parse('$apiUrl$postId/like/');

    try {
      final response = await http.post(
        url,
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
    final url = Uri.parse('$apiUrl$postId/save/');

    try {
      final response = await http.post(
        url,
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

  // Update comments count (not necessary if handled during comment creation)
  Future<void> updateCommentsCount(int postId, int newCount) async {
    final url = Uri.parse('$apiUrl$postId/comments_count/');

    try {
      final response = await http.patch(
        url,
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

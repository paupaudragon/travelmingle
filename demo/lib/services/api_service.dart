import 'dart:convert';
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
        posts.forEach((post) => print('Post: ${post.title}, Comments: ${post.comments.length}'));

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

  // Future<List<Comment>> fetchComments(int postId) async {
  //   try {
  //     final response = await http.get(Uri.parse("http://10.0.2.2:8000/api/comments/?post_id=$postId"));
  //     if (response.statusCode == 200) {
  //       List<dynamic> data = json.decode(response.body);
  //       return data.map((json) => Comment.fromJson(json)).toList();
  //     } else {
  //       throw Exception('Failed to load comments');
  //     }
  //   } catch (e) {
  //     return [];
  //   }
  // } 
}

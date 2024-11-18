import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';

class ApiService {
  // final String apiUrl = 'http://localhost:8000/api/posts';
  final String apiUrl = 'http://10.0.2.2:8000/api/posts';

  Future<List<Post>> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        // print
        // data.forEach((json) => print('Post JSON: $json'));
        return data.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      // print('Error fetching posts: $e');
      return [];
    }
  }
}

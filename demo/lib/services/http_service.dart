import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HttpService {
  // Replace with your actual API base URL
  final String baseUrl = "http://10.0.2.2:8000/api";

  // Get the token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Helper method to build headers with authentication
  Future<Map<String, String>> _getHeaders() async {
    String? token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw HttpException('${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error in GET request: $e');
      rethrow;
    }
  }

  // POST request
  Future<dynamic> post(String endpoint, dynamic data) async {
    print(endpoint);
    print(data);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw HttpException('${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error in POST request: $e');
      rethrow;
    }
  }

  // PUT request
  Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw HttpException('${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error in PUT request: $e');
      rethrow;
    }
  }

  // DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        throw HttpException('${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error in DELETE request: $e');
      rethrow;
    }
  }

  // PATCH request
  Future<dynamic> patch(String endpoint, dynamic data) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw HttpException('${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error in PATCH request: $e');
      rethrow;
    }
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => message;
}

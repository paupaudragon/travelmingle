import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HttpService {
  // Deployment
  // final String baseUrl = "http://10.0.2.2:8000/api";
  final String baseUrl = "http://54.89.74.130:8000/api";

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

// Also update your HttpService class in http_service.dart
  Future<dynamic> get(String endpoint) async {
    try {
      // Determine if this is a full URL (like an S3 URL) or a relative endpoint
      final bool isFullUrl = endpoint.startsWith('http');
      final String url = isFullUrl ? endpoint : '$baseUrl$endpoint';

      // Check if this is an S3 URL
      final bool isS3Url = url.contains('amazonaws.com');

      // Get headers, but don't include auth for S3
      final Map<String, String> headers =
          isS3Url ? {'Content-Type': 'application/json'} : await _getHeaders();

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // For images or binary data from S3, return the raw bytes
        if (isS3Url) {
          final contentType = response.headers['content-type'] ?? '';
          if (contentType.startsWith('image/') ||
              contentType.contains('octet-stream')) {
            return response.bodyBytes;
          }
        }

        // Otherwise parse as JSON
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

  /// Transforms S3 URLs to ensure they have the correct region format
  String transformS3Url(String url) {
    // Check if this is an S3 URL without the region
    if (url.contains('.s3.amazonaws.com')) {
      // Add the us-east-1 region (update if your region is different)
      return url.replaceFirst(
          '.s3.amazonaws.com', '.s3.us-east-1.amazonaws.com');
    }
    return url;
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => message;
}

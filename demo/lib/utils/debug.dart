// Add this code to your project for debugging S3 connections

import 'package:http/http.dart' as http;
import 'dart:convert';

class S3Debugger {
  static Future<void> testImageAccess(String imageUrl) async {
    try {
      // Try to get the headers first to check permissions
      final headResponse = await http.head(Uri.parse(imageUrl));
      print('HEAD Response for $imageUrl:');
      print('Status code: ${headResponse.statusCode}');
      print('Headers: ${headResponse.headers}');

      if (headResponse.statusCode == 403) {
        print(
            'Permission denied (403 Forbidden). Likely an S3 policy or ACL issue.');
      } else if (headResponse.statusCode == 404) {
        print(
            'Resource not found (404). Check if the file exists in the bucket.');
      }

      // Try an actual GET request for more details
      final getResponse = await http.get(Uri.parse(imageUrl));
      print('\nGET Response for $imageUrl:');
      print('Status code: ${getResponse.statusCode}');
      print('Response size: ${getResponse.bodyBytes.length} bytes');

      // Print error body if exists
      if (getResponse.statusCode >= 400) {
        print('Error response body:');
        try {
          // Try to parse as XML (AWS typically returns XML errors)
          print(getResponse.body);

          // If the response is XML, extract the message
          if (getResponse.body.contains('<Message>')) {
            final messageStart = getResponse.body.indexOf('<Message>') + 9;
            final messageEnd = getResponse.body.indexOf('</Message>');
            if (messageStart > 0 && messageEnd > 0) {
              final errorMessage =
                  getResponse.body.substring(messageStart, messageEnd);
              print('AWS Error Message: $errorMessage');
            }
          }
        } catch (e) {
          print('Failed to parse error response: $e');
        }
      }
    } catch (e) {
      print('Exception during S3 access test: $e');
    }
  }

  // Test the bucket policy and permissions
  static Future<void> testBucketPermissions(
      String bucketName, String region) async {
    try {
      // Try to access the bucket list (this will likely fail if not using AWS credentials)
      final url = 'https://$bucketName.s3.$region.amazonaws.com/';
      final response = await http.get(Uri.parse(url));

      print('Bucket access test for $url:');
      print('Status code: ${response.statusCode}');

      if (response.statusCode == 403) {
        print(
            'Access to bucket listing is denied - this is normal for public buckets');
        print(
            'Individual objects may still be accessible if properly configured');
      } else if (response.statusCode == 200) {
        print('Bucket listing is publicly accessible!');
      }
    } catch (e) {
      print('Exception during bucket test: $e');
    }
  }

  // Usage example:
  static Future<void> runFullDiagnostics() async {
    // Test the specific images from your error logs
    await testImageAccess(
        'https://travelmingle-media.s3.amazonaws.com/media/postImages/scaled_1000000033.jpg');
    await testImageAccess(
        'https://travelmingle-media.s3.amazonaws.com/media/profile_pictures/default.png');

    // Test the bucket itself
    await testBucketPermissions(
        'travelmingle-media', 'us-east-1'); // Update region if different
  }
}

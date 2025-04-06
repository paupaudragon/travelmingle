import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

class S3Helper {
  // Base URL without region (matches your S3 bucket format)
  static const String baseS3Url = 'https://travelmingle-media.s3.amazonaws.com';

  /// For direct image access - ensures no auth headers are added
  static String getImageUrl(String objectKey) {
    // If it's already a full URL, use it directly
    if (objectKey.startsWith('http')) {
      return objectKey;
    }

    // Otherwise, construct the full URL
    if (objectKey.startsWith('/')) {
      objectKey = objectKey.substring(1);
    }
    return '$baseS3Url/$objectKey';
  }

  /// Upload a file to S3 using a pre-signed URL
  static Future<bool> uploadFileWithPresignedUrl(
      File file, String presignedUrl) async {
    try {
      // Determine content type
      final String? mimeType = lookupMimeType(file.path);

      final response = await http.put(
        Uri.parse(presignedUrl),
        body: await file.readAsBytes(),
        headers: {
          'Content-Type': mimeType ?? 'application/octet-stream',
          // No auth headers for S3 pre-signed URLs
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error uploading file to S3: $e');
      return false;
    }
  }

  /// Generate a unique object key for S3
  static String generateUniqueObjectKey(String folder, File file) {
    final uuid = Uuid();
    final extension = path.extension(file.path).toLowerCase();
    return '$folder/${uuid.v4()}$extension';
  }
}

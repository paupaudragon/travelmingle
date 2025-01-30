import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class CustomCacheManager extends CacheManager {
  static const key = "customCachedImages";

  static final CustomCacheManager _instance = CustomCacheManager._internal();

  factory CustomCacheManager() {
    return _instance;
  }

  CustomCacheManager._internal()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 7), // keep 7 days
            maxNrOfCacheObjects: 500, // 200 images max
            repo: JsonCacheInfoRepository(databaseName: key),
            fileService: HttpFileService(),
          ),
        );

  /// **Download and compress image**
  Future<File> downloadAndCompressImage(String url) async {
    final File cacheFile = await getSingleFile(url); // Get the original image from cache
    if (!cacheFile.existsSync()) return cacheFile; // Return the original file path if the file does not exist

    final Directory tempDir = await getTemporaryDirectory(); // Get the temporary directory
    final String compressedPath = '${tempDir.path}/compressed_${url.hashCode}.jpg';

    XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
      cacheFile.path,
      compressedPath,
      quality: 80,
      minWidth: 800,
      minHeight: 600,
    );

    return compressedXFile != null ? File(compressedXFile.path) : cacheFile;
  }
}

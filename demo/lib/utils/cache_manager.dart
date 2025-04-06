import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomCacheManager {
  static final CustomCacheManager _instance = CustomCacheManager._internal();
  factory CustomCacheManager() => _instance;
  CustomCacheManager._internal();

  final CacheManager instance = CacheManager(
    Config(
      'optimizedImageCache',
      stalePeriod: const Duration(days: 14),
      maxNrOfCacheObjects: 100,
    ),
  );
}

class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedNetworkImage({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the original URL - do not transform
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      cacheManager: CustomCacheManager().instance,
      httpHeaders: {}, // Empty headers - no authorization for S3
      placeholder: (context, url) =>
          placeholder ??
          Container(
            color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator()),
          ),
      errorWidget: (context, url, error) {
        // Log the error for debugging
        print('Error loading image: $error');
        print('URL attempted: $url');

        // Return custom error widget or default error icon
        return errorWidget ??
            Container(
              color: Colors.grey[200],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.red[300]),
                    const SizedBox(height: 4),
                    const Text('Image unavailable'),
                  ],
                ),
              ),
            );
      },
    );
  }

  /// Preload an image into the cache
  static Future<void> preloadImage(BuildContext context, String imageUrl) {
    return precacheImage(
      CachedNetworkImageProvider(
        imageUrl,
        headers: {}, // Empty headers - no authorization for S3
      ),
      context,
    );
  }
}

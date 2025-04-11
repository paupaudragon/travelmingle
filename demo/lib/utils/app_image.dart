import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../services/api_service.dart'; // Assuming this is where transformS3Url is defined

/// A unified image cache manager for the entire app
class AppCacheManager {
  static final AppCacheManager _instance = AppCacheManager._internal();
  factory AppCacheManager() => _instance;
  AppCacheManager._internal();

  final CacheManager instance = CacheManager(
    Config(
      'appImageCache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
      // Increased to handle more images but not too much to cause memory issues
    ),
  );
}

/// A unified network image widget that properly handles mipmaps
/// and works with the Flutter Impeller renderer
class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool useS3Transform;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableRetry;

  const AppNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.useS3Transform = true,
    this.placeholder,
    this.errorWidget,
    this.enableRetry = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Handle null or empty URLs
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    // Process the URL if needed (S3 transform)
    final processedUrl =
        useS3Transform ? ApiService().transformS3Url(imageUrl) : imageUrl!;

    // For debugging
    // print('🖼️ Loading image: $processedUrl');

    return CachedNetworkImage(
      imageUrl: processedUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: AppCacheManager().instance,
      // Important: Set proper image quality settings for Impeller compatibility
      // Medium is safer than Low with mipmaps
      filterQuality: FilterQuality.medium,
      // Disable mipmapping explicitly through image provider settings
      imageBuilder: (context, imageProvider) {
        return Image(
          image: imageProvider,
          fit: fit,
          width: width,
          height: height,
          // This is important to prevent mipmapping issues with Impeller
          filterQuality: FilterQuality.medium,
        );
      },
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) {
        // Log error but don't flood console
        // print('❌ Image load error: $error for URL: $url');

        if (enableRetry) {
          return _buildRetryWidget(context, processedUrl);
        } else {
          return errorWidget ?? _buildDefaultErrorWidget();
        }
      },
      // Don't use authorization headers - S3 URLs should be public
      httpHeaders: const {},
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Center(
        child: FittedBox(
          // 👈 Add this
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_not_supported, color: Colors.grey[600]),
              const SizedBox(height: 4),
              Text(
                'Image unavailable',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetryWidget(BuildContext context, String url) {
    return GestureDetector(
      onTap: () {
        // Clear the cache for this specific URL
        AppCacheManager().instance.removeFile(url);

        // Force image reload by refreshing the widget tree
        // Note: This is a simple approach; for more complex scenarios
        // you might want to use a state management solution
        if (context.mounted) {
          DefaultCacheManager().removeFile(url);
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
        }
      },
      child: Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh, color: Colors.grey[700]),
              const SizedBox(height: 8),
              Text(
                'Tap to retry',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  /// Preload an image into the cache
  static Future<void> preloadImage(
      BuildContext context, String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;

    final String processedUrl = ApiService().transformS3Url(imageUrl);

    try {
      await precacheImage(
        CachedNetworkImageProvider(
          processedUrl,
          // Don't use headers here
          headers: const {},
          // CachedNetworkImageProvider doesn't accept filterQuality directly
          maxWidth: 1000, // Reasonable max size
        ),
        context,
      );
    } catch (e) {
      // Silently handle preloading errors
      // print('⚠️ Error preloading image: $e');
    }
  }
}

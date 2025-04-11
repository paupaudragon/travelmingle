import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';

class S3ImageWithRetry extends StatefulWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  const S3ImageWithRetry({
    Key? key,
    required this.imageUrl,
    this.width = double.infinity,
    this.height = 200,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  State<S3ImageWithRetry> createState() => _S3ImageWithRetryState();
}

class _S3ImageWithRetryState extends State<S3ImageWithRetry> {
  late String processedUrl;
  bool isLoading = true;
  bool hasError = false;
  int retryCount = 0;
  final int maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _processUrl();
  }

  @override
  void didUpdateWidget(S3ImageWithRetry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _processUrl();
    }
  }

  void _processUrl() {
    setState(() {
      isLoading = true;
      hasError = false;
      retryCount = 0;
    });

    // Use the enhanced URL transformer
    processedUrl = ApiService().transformS3Url(widget.imageUrl);
    print('🖼️ Processed image URL: $processedUrl');
  }

  void _retryLoading() {
    if (retryCount < maxRetries) {
      setState(() {
        retryCount++;
        hasError = false;
        // Add a cache buster to force reload
        processedUrl = '$processedUrl?retry=$retryCount';
      });
      print(
          '🔄 Retrying image load (${retryCount}/$maxRetries): $processedUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (processedUrl.isEmpty) {
      return _buildPlaceholder();
    }

    return Stack(
      children: [
        CachedNetworkImage(
          imageUrl: processedUrl,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          placeholder: (context, url) => _buildLoadingIndicator(),
          errorWidget: (context, url, error) {
            print('❌ Image load error: $error');
            return _buildErrorWidget();
          },
        ),
        if (hasError)
          Positioned.fill(
            child: GestureDetector(
              onTap: _retryLoading,
              child: Container(
                color: Colors.black38,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        'Tap to retry',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.grey[200],
      child: Center(
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

  Widget _buildErrorWidget() {
    // Set error state
    if (!hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          hasError = true;
        });
      });
    }

    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}

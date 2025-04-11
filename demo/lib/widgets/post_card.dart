import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:demo/main.dart';
import 'package:demo/models/post_model.dart';
import 'package:demo/utils/app_image.dart'; // Updated import for our new unified image loader
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onLikePressed;

  const PostCard({
    Key? key,
    required this.post,
    required this.onLikePressed,
  }) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  Size? _cachedImageSize;
  bool _isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    // Pre-calculate image dimensions if post has images
    if (widget.post.images.isNotEmpty) {
      _preloadAndCalculateImageSize(widget.post.images[0].imageUrl);
    }
  }

  Future<void> _preloadAndCalculateImageSize(String imageUrl) async {
    try {
      // Preload the image
      await AppNetworkImage.preloadImage(context, imageUrl);

      // Calculate dimensions - use a simplified approach that's less likely to cause issues
      final imageProvider = CachedNetworkImageProvider(
        imageUrl,
        headers: const {},
        // CachedNetworkImageProvider doesn't accept filterQuality directly
      );

      // Use a standard approach to get image dimensions
      final completer = Completer<Size>();

      final ImageStream stream = imageProvider.resolve(ImageConfiguration());
      final listener = ImageStreamListener(
        (ImageInfo info, bool _) {
          if (!completer.isCompleted) {
            final Size size = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            );
            completer.complete(size);

            if (mounted) {
              setState(() {
                _cachedImageSize = size;
                _isImageLoaded = true;
              });
            }
          }
        },
        onError: (dynamic exception, StackTrace? stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(exception, stackTrace);

            if (mounted) {
              setState(() {
                _isImageLoaded = false;
              });
            }
          }
        },
      );

      stream.addListener(listener);

      // Set a timeout to prevent hanging
      Future.delayed(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          stream.removeListener(listener);
          completer.completeError(TimeoutException('Image load timed out'));
        }
      });

      await completer.future;
    } catch (e) {
      // Handle errors gracefully
      if (mounted) {
        setState(() {
          _isImageLoaded = false;
        });
      }
    }
  }

  String formatNumber(int number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 1000000) {
      double result = number / 1000;
      return "${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)}K";
    } else {
      double result = number / 1000000;
      return "${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)}M";
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 2.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.images.isNotEmpty)
            _buildPostImage()
          else
            Container(
              height: 180,
              color: Colors.grey[300],
              child: Center(
                child: Icon(Icons.photo_outlined, color: Colors.grey[600]),
              ),
            ),

          // Post Title & Content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Location name
                if (post.location.address != null &&
                    post.location.address!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0, bottom: 4.0),
                    child: Text(
                      post.location.address!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 4),

                // Content preview (if any)
                if (post.content != null && post.content!.isNotEmpty)
                  Text(
                    post.content!,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 8),

                // User info & stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // User avatar and username
                    Row(
                      children: [
                        // Use our unified image loader for the avatar too
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: ClipOval(
                            child: AppNetworkImage(
                              imageUrl: post.user.profilePictureUrl,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.user.username,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Like count
                    Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onLikePressed,
                          child: SvgPicture.asset(
                            post.isLiked
                                ? 'assets/icons/heart_filled.svg'
                                : 'assets/icons/heart.svg',
                            width: 18,
                            height: 18,
                            colorFilter: ColorFilter.mode(
                              post.isLiked ? colorLiked : iconColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          formatNumber(post.likesCount),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage() {
    if (widget.post.images.isEmpty) {
      return Container(); // No image
    }

    final imageUrl = widget.post.images[0].imageUrl;

    // If we have cached dimensions, use them for the aspect ratio
    if (_cachedImageSize != null && _isImageLoaded) {
      double width = _cachedImageSize!.width;
      double height = _cachedImageSize!.height;

      // Ensure we have positive values for both dimensions
      if (width <= 0) width = 1.0;
      if (height <= 0) height = 1.0;

      // Calculate aspect ratio with safety checks
      double aspectRatio = width / height;

      // Apply safety checks
      if (!aspectRatio.isFinite || aspectRatio <= 0) {
        aspectRatio = 16 / 9; // Default to 16:9 if calculation fails
      } else {
        // Clamp to reasonable limits to prevent extreme aspect ratios
        aspectRatio = aspectRatio.clamp(0.5, 2.0);
      }

      return AspectRatio(
        aspectRatio: aspectRatio,
        child: AppNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
        ),
      );
    }

    // Fallback fixed height approach when dimensions aren't available
    return AppNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      height: 180, // Fixed height as fallback
      width: double.infinity,
    );
  }
}

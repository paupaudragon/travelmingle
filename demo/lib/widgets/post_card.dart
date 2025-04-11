import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:demo/main.dart';
import 'package:demo/models/post_model.dart';
import 'package:demo/utils/cache_manager.dart';
import 'package:demo/widgets/s3_image_with_retry.dart';
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

  @override
  void initState() {
    super.initState();
    // Pre-calculate image dimensions if post has images
    if (widget.post.images.isNotEmpty) {
      _calculateImageSize(widget.post.images[0].imageUrl);
    }
  }

  Future<void> _calculateImageSize(String imageUrl) async {
    try {
      final imageProvider = CachedNetworkImageProvider(imageUrl);
      final completer = Completer<Size>();

      imageProvider.resolve(ImageConfiguration()).addListener(
            ImageStreamListener((ImageInfo info, bool _) {
              if (mounted) {
                setState(() {
                  _cachedImageSize = Size(
                    info.image.width.toDouble(),
                    info.image.height.toDouble(),
                  );
                });
              }
              completer.complete(_cachedImageSize);
            }, onError: (exception, stackTrace) {
              print('Error loading image: $exception');
              completer.completeError(exception);
            }),
          );

      await completer.future;
    } catch (e) {
      print('Error calculating image size: $e');
    }
  }

  Widget _buildPostImage() {
    if (widget.post.images.isEmpty) {
      return Container(); // No image
    }

    final imageUrl = widget.post.images[0].imageUrl;

    // If we have cached dimensions, use them for the aspect ratio
    if (_cachedImageSize != null) {
      double width = _cachedImageSize!.width;
      double height = _cachedImageSize!.height;

      if (height <= 0) height = 1.0;
      if (width <= 0) width = 1.0;

      double aspectRatio = width / height;

      if (!aspectRatio.isFinite) {
        aspectRatio =
            1.0; // Default to square aspect ratio if calculation fails
      } else {
        // Clamp to reasonable limits
        aspectRatio = aspectRatio.clamp(0.5, 1.5);
      }

      return AspectRatio(
        aspectRatio: aspectRatio,
        child: OptimizedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
        ),
      );
    }

    // Fallback fixed height approach
    return OptimizedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      height: 200,
      width: double.infinity,
    );
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
          if (post.images.isNotEmpty) _buildPostImage(),

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
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: CachedNetworkImageProvider(
                            post.user.profilePictureUrl,
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
}

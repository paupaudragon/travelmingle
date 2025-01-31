import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../screens/profile_page.dart';
import 'dart:async';
import 'package:demo/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/cache_manager.dart';
import 'dart:io';
import 'dart:ui';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onLikePressed;

  const PostCard({
    Key? key,
    required this.post,
    this.onLikePressed,
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  File? _cachedImage;
  Size? _imageSize;
  bool _isLoadingImage = true;

  @override
  void initState() {
    super.initState();

    if (widget.post.images.isNotEmpty || widget.post.period == "multipleday") {
      _loadAndCacheImage();
    } else {
      _isLoadingImage = false; // No need to load if there are no images
    }
  }

  // Download & compress image
  Future<void> _loadAndCacheImage() async {
    String? imageUrl;

    // Check if the post is a multiple-day post and has child posts
    if (widget.post.childPosts == null) {
      print("❌ ERROR: childPosts is NULL in Post_Card");
    } else {
      print(
          "✅ childPosts exists in Post_Card: ${widget.post.childPosts!.length} items");
    }
    if (widget.post.period == "multipleday" &&
        widget.post.childPosts != null &&
        widget.post.childPosts!.isNotEmpty) {
      // Retrieve the first image of Day 1
      final day1 = widget.post.childPosts!.first;
      if (day1.images.isNotEmpty) {
        imageUrl = day1.images.first.imageUrl;
        print("Multiple-day post - Day 1 image URL: $imageUrl"); // Debug print
      }
    } else if (widget.post.images.isNotEmpty) {
      // Retrieve the first image for single-day posts
      imageUrl = widget.post.images.first.imageUrl;
      print("Single-day post image URL: $imageUrl"); // Debug print
    }

    if (imageUrl != null) {
      try {
        // Cache and resize the image
        final resizedImage =
            await CustomCacheManager().downloadAndCompressImage(imageUrl);

        if (resizedImage.existsSync()) {
          final size = await _getImageDimension(resizedImage);

          if (mounted) {
            setState(() {
              _cachedImage = resizedImage;
              _imageSize = _clampAspectRatio(size);
              _isLoadingImage = false;
            });
          }
        }
      } catch (e) {
        print("Error loading image: $e");
        setState(() {
          _isLoadingImage = false;
        });
      }
    } else {
      setState(() {
        _isLoadingImage = false; // No image available
      });
    }
  }

  // Get image dimensions
  Future<Size> _getImageDimension(File imageFile) async {
    final Image image = Image.file(imageFile);
    final Completer<Size> completer = Completer<Size>();

    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );
    return completer.future;
  }

  // Clamp aspect ratio between 4:3 and 5:7
  Size _clampAspectRatio(Size size) {
    const double minAspectRatio = 5 / 7;
    const double maxAspectRatio = 4 / 3;

    double aspectRatio = size.width / size.height;
    aspectRatio = aspectRatio.clamp(minAspectRatio, maxAspectRatio);

    return Size(size.width, size.width / aspectRatio);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFFfafafa),
      margin: const EdgeInsets.all(3.0),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Photo
          if (widget.post.images.isNotEmpty ||
              (widget.post.period == "multipleday" &&
                  widget.post.childPosts != null &&
                  widget.post.childPosts!.isNotEmpty &&
                  widget.post.childPosts!.first.images.isNotEmpty))
            _cachedImage != null
                ? Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: AspectRatio(
                      aspectRatio: _imageSize!.width / _imageSize!.height,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8), // Top left corner 8
                          topRight: Radius.circular(8), // Top right corner 8
                          bottomLeft:
                              Radius.circular(2), // Bottom left corner 2
                          bottomRight:
                              Radius.circular(2), // Bottom right corner 2
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Use cached image
                            Image.file(
                              _cachedImage!,
                              fit: BoxFit.cover,
                            ),

                            // Display location information on the image
                            if (widget.post.location.name.isNotEmpty)
                              if (widget.post.location.name.isNotEmpty)
                                Positioned(
                                  top: 0, // Position adjustment
                                  left: 0,
                                  right: 0,
                                  child: Stack(
                                    children: [
                                      // Blurred background, but does not affect text
                                      ClipRRect(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(4),
                                        ),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: 2,
                                              sigmaY: 4), // Slight blur
                                          child: Container(
                                            height:
                                                25, // Limit blur height to reduce impact
                                            color: Colors
                                                .transparent, // Transparent background
                                          ),
                                        ),
                                      ),

                                      // Foreground layer, display text & gradient
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(
                                            4, 2, 4, 8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black.withOpacity(
                                                  0.4), // Start with 40% transparent black
                                              Colors.black.withOpacity(0.2),
                                              Colors
                                                  .transparent, // Gradually become transparent
                                            ],
                                            stops: [0.0, 0.5, 1.0],
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.location_on_rounded,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            Expanded(
                                              child: Text(
                                                ' ${widget.post.location.name}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  )

                // Show Loading Indicator if the image is loading
                : Container(
                    height: 120, // Reserve space
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(),
                  ),

          // Reserve fixed space for pure text post

          // if (widget.post.images.isEmpty)
          //   SizedBox(height: 8), // Add some spacing

          // Post title
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// **始终显示标题**
                Text(
                  widget.post.title.isNotEmpty ? widget.post.title : 'No Title',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                ),

                /// **如果没有图片，显示内容**
                if ((widget.post.images.isEmpty &&
                        (widget.post.period != "multipleday" ||
                            widget.post.childPosts == null ||
                            widget.post.childPosts!.isEmpty)) &&
                    widget.post.content != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0), // 标题和内容之间的间距
                    child: Text(
                      widget.post.content!, // 展示内容
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54, // 让内容颜色稍微淡一些
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis, // 超出部分省略
                    ),
                  ),
              ],
            ),
          ),

          // Username & Like button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Username
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfilePage(userId: widget.post.user.id),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 6.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage:
                            NetworkImage(widget.post.user.profilePictureUrl),
                        radius: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.post.user.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // Like button
              Padding(
                padding: const EdgeInsets.only(right: 12.0), // Adjust right padding to bring the elements closer
                child: Row(
                  mainAxisSize: MainAxisSize
                      .min, // Prevent Row from taking up the entire space
                  children: [
                    IconButton(
                      icon: Icon(
                        widget.post.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.post.isLiked ? colorLiked : colorLike,
                      ),
                      iconSize: 20,
                      visualDensity:
                          VisualDensity.compact, // Make IconButton more compact
                      padding: EdgeInsets.zero, // Remove default padding
                      constraints: const BoxConstraints(), // Remove extra space
                      onPressed: widget.onLikePressed,
                    ),
                    Text(
                      '${widget.post.likesCount}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

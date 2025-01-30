import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../screens/profile_page.dart';
import 'dart:async';
import 'package:demo/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/cache_manager.dart';
import 'dart:io';

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
    if (widget.post.images.isNotEmpty) {
      _loadAndCacheImage();
    } else {
      _isLoadingImage = false; // No need to load if there are no images
    }
  }

  // Download & compress image
  Future<void> _loadAndCacheImage() async {
    final resizedImage = await CustomCacheManager()
        .downloadAndCompressImage(widget.post.images.first.imageUrl);

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
      margin: const EdgeInsets.all(1.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Photo
          if (widget.post.images.isNotEmpty)
            _cachedImage != null
                ? Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: AspectRatio(
                      aspectRatio: _imageSize!.width / _imageSize!.height,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3), // Rounded corners
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
                              Positioned(
                                bottom: 0, // Distance from the bottom
                                left: 0, // Align left
                                right: 0, // Optional: keep text within bounds
                                child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(4, 8, 4, 0),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        const Color.fromARGB(255, 116, 116, 116)
                                            .withOpacity(0.6),
                                        const Color.fromARGB(255, 116, 116, 116)
                                            .withOpacity(0.6),
                                        const Color.fromARGB(255, 116, 116, 116)
                                            .withOpacity(0.5),
                                        const Color.fromARGB(255, 116, 116, 116)
                                            .withOpacity(0.4),
                                        const Color.fromARGB(255, 116, 116, 116)
                                            .withOpacity(0.2),
                                        const Color.fromARGB(255, 116, 116, 116)
                                            .withOpacity(0.1),
                                        const Color.fromARGB(255, 116, 116, 116)
                                            .withOpacity(0.05),
                                      ],
                                      stops: [
                                        0.0,
                                        0.2,
                                        0.4,
                                        0.55,
                                        0.8,
                                        0.9,
                                        1.0
                                      ],
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
          if (widget.post.images.isEmpty)
            SizedBox(height: 8), // Add some spacing

          // Post title
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: Text(
              widget.post.title.isNotEmpty ? widget.post.title : 'No Title',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.start,
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
                      const SizedBox(width: 6),
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
                padding: const EdgeInsets.only(right: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        widget.post.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.post.isLiked ? Colors.red : Colors.grey,
                      ),
                      iconSize: 20,
                      onPressed: widget.onLikePressed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.post.likesCount}',
                      style: const TextStyle(fontSize: 14),
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

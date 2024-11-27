import 'package:flutter/material.dart';
import '../models/post_model.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onLikePressed; // Callback for like button

  const PostCard({
    super.key,
    required this.post,
    this.onLikePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(4.0), // Reduced margin for a tighter layout
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Info
          Padding(
            padding: const EdgeInsets.all(4.0), // Reduced padding
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(post.user.profilePictureUrl),
                  radius: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    post.user.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14, // Slightly smaller font
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Cover Photo
          if (post.images.isNotEmpty)
            AspectRatio(
              aspectRatio: 16 / 9, // Standard aspect ratio for photos
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  post.images.first.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          const SizedBox(height: 4),

          // Title Preview and Like Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0), // Reduced horizontal padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title.isNotEmpty
                      ? post.title.length > 30
                          ? '${post.title.substring(0, 30)}...'
                          : post.title
                      : 'No Title',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16, // Slightly smaller font size
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        color: post.isLiked ? Colors.red : Colors.grey,
                      ),
                      onPressed: onLikePressed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likesCount}',
                      style: const TextStyle(fontSize: 14), // Smaller text size
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

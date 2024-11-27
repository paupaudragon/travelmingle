import 'package:demo/widgets/comment_list.dart';
import 'package:flutter/material.dart';
import '../models/comment_model.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;

  const CommentTile({
    Key? key,
    required this.comment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                comment.user.profilePictureUrl ?? 'https://via.placeholder.com/150',
              ),
            ),
            title: Text(
              comment.user.username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(comment.content),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.favorite, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${comment.likesCount} likes'),
            ],
          ),
          // Nested Replies
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: CommentsList(comments: comment.replies),
            ),
        ],
      ),
    );
  }
}

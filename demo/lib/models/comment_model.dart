import 'user_model.dart';

class Comment {
  final int id;
  final int postId;
  final User user;
  final String? content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? replyTo;
  final List<Comment> replies;
  int likesCount;
  bool isLiked; // New field
  final String? commentPictureUrl; // New field

  Comment({
    required this.id,
    required this.postId,
    required this.user,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.replyTo,
    required this.replies,
    required this.likesCount,
    required this.isLiked, // New field
    this.commentPictureUrl, // New field
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['post'],
      user: User.fromJson(json['user']),
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      replyTo: json['reply_to'],
      replies: (json['replies'] as List? ?? [])
          .map((reply) => Comment.fromJson(reply))
          .toList(),
      likesCount: json['likes_count'] ?? 0,
      isLiked: json['is_liked'] ?? false, // Parse from backend response
      commentPictureUrl: json['comment_image_url'], // Map the new field
    );
  }
}

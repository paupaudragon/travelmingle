import 'user_model.dart';

class Comment {
  final int id;
  final int postId;
  final User user;
  final String? content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? replyTo; // This help to generate the comment tree
  final List<Comment> replies; // This help to generate the comment tree
  int likesCount;
  bool isLiked; 
  final String? commentPictureUrl; // store image Url when commenting

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
    required this.isLiked, 
    this.commentPictureUrl, 
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
      isLiked: json['is_liked'] ?? false, 
      commentPictureUrl: json['comment_image_url'], 
    );
  }
}

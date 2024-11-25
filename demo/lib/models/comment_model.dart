import 'user_model.dart';

class Comment {
  final int id;
  final int postId;
  final User user;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? replyTo;
  final List<Comment> replies;
  final int likesCount;
  final List<int> mentionedUsers;

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
    required this.mentionedUsers,
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
      replies: (json['replies'] as List)
          .map((reply) => Comment.fromJson(reply))
          .toList(),
      likesCount: json['likes_count'] ?? 0,
      mentionedUsers: List<int>.from(json['mentioned_users'] ?? []),
    );
  }
}

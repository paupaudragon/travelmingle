import 'user_model.dart';
import 'comment_model.dart';
import 'postImage_model.dart';

class Post {
  final int id;
  final User user;
  final String title;
  final String content;
  final String location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final String visibility;
  final List<Comment> detailedComments;
  final List<PostImage> images;
  int likesCount;
  int savesCount;
  bool isLiked; // New field
  bool isSaved; // New field

  Post({
    required this.id,
    required this.user,
    required this.title,
    required this.content,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.visibility,
    required this.likesCount,
    required this.savesCount,
    required this.detailedComments,
    required this.images,
    required this.isLiked, // New field
    required this.isSaved, // New field
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      user: User.fromJson(json['user']),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      location: json['location'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      status: json['status'],
      visibility: json['visibility'],
      likesCount: json['likes_count'] ?? 0,
      savesCount: json['saves_count'] ?? 0,
      detailedComments: (json['detailed_comments'] as List? ?? [])
          .map((comment) => Comment.fromJson(comment))
          .toList(),
      images: (json['images'] as List? ?? [])
          .map((image) => PostImage.fromJson(image))
          .toList(),
      isLiked: json['is_liked'] ?? false, // Parse from backend response
      isSaved: json['is_saved'] ?? false, // Parse from backend response
    );
  }
}

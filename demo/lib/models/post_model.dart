import 'user_model.dart';
import 'comment_model.dart';
import 'postImage_model.dart';

import 'package:demo/models/location_model.dart';

class Post {
  final int id;
  final User user;
  final String title;
  final String? content;
  final LocationData location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final String visibility;
  final List<Comment> detailedComments;
  final List<PostImage> images; // store a list of images
  final String category;
  final String period;
  final String? hashtags;
  final int? parentPostId; // Reference to parent post for child posts
  final List<Post>? childPosts; // Store child posts for multi-day posts
  int likesCount;
  int savesCount;
  bool isLiked;
  bool isSaved;

  Post({
    required this.id,
    required this.user,
    required this.title,
    this.content,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.visibility,
    required this.likesCount,
    required this.savesCount,
    required this.detailedComments,
    required this.images,
    required this.isLiked,
    required this.isSaved,
    required this.category,
    required this.period,
    this.hashtags,
    this.parentPostId, // Reference to parent post
    this.childPosts, // Initialize child posts
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      user: User.fromJson(json['user']),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      location: LocationData(
        placeId: json['location']['place_id'],
        name: json['location']['name'],
        address: json['location']['address'],
        latitude:
            double.tryParse(json['location']['latitude'].toString()) ?? 0.0,
        longitude:
            double.tryParse(json['location']['longitude'].toString()) ?? 0.0,
      ),

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
      isLiked: json['is_liked'] ?? false,
      isSaved: json['is_saved'] ?? false,
      category: json['category'] ?? '', // Parse category from JSON
      period: json['period'] ?? '', // Parse period from JSON
      hashtags: json['hashtags'], // Parse optional hashtags from JSON
      parentPostId: json['parent_post'], // Parse parent post ID if provided
      childPosts: (json['child_posts'] as List? ?? []) // Parse child posts
          .map((childPost) => Post.fromJson(childPost))
          .toList(),
    );
  }
}

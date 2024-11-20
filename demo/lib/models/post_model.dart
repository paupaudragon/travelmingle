class User {
  final int id;
  final String username;
  final String email;
  final String bio;
  final String? profilePicture; // Make this field nullable
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.bio,
    this.profilePicture, // Update constructor
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      bio: json['bio'],
      profilePicture: json['profile_picture'], // Ensure correct field name
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

///
class Comment {
  final int id;
  final User user; // Changed from `int userId` to `User user`
  final String content;
  final DateTime createdAt;
  final int? parentId; // For nested comments

  Comment({
    required this.id,
    required this.user,
    required this.content,
    required this.createdAt,
    this.parentId,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    print('Parsing Comment: $json'); // Debug print

    return Comment(
      id: json['id'],
      user: User.fromJson(json['user']), // Parse nested user object
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      parentId: json['parent'],
    );
  }
}

class Post {
  final int id;
  final User user;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  ///
  final List<Comment> comments;

  Post({
    required this.id,
    required this.user,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,

    ///
    this.comments = const [],
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final comments = (json['comments'] as List<dynamic>?)
        ?.map((commentJson) => Comment.fromJson(commentJson))
        .toList() ?? [];
    print('Parsed Post: ${json['title']}, Comments: ${comments.length}');
    return Post(
      id: json['id'],
      user: User.fromJson(json['user']),
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      comments: comments,
    );
  }
}


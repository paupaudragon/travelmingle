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

class Post {
  final int id;
  final User user;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Post({
    required this.id,
    required this.user,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      user: User.fromJson(json['user']),
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

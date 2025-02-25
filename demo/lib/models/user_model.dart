class User {
  final int id;
  final String username;
  final String email;
  final String bio;
  final String profilePictureUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  bool isFollowing;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.bio,
    required this.profilePictureUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isFollowing = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      bio: json['bio'] ?? ' ',
      profilePictureUrl: json['profile_picture_url'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isFollowing: json['is_following'] ?? false,
    );
  }
}

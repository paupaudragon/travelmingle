class PostImage {
  final int id;
  final int postId;
  final String imageUrl;
  final DateTime createdAt;

  PostImage({
    required this.id,
    required this.postId,
    required this.imageUrl,
    required this.createdAt,
  });

  factory PostImage.fromJson(Map<String, dynamic> json) {
    return PostImage(
      id: json['id'],
      postId: json['post'],
      imageUrl: json['image'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

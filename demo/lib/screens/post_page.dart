import 'dart:convert';
import 'package:demo/models/comment_model.dart';
import 'package:flutter/material.dart';
import 'package:demo/services/api_service.dart';
import 'package:demo/models/post_model.dart';

class PostPage extends StatefulWidget {
  final Post post;

  const PostPage({Key? key, required this.post}) : super(key: key);

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final TextEditingController _commentController = TextEditingController();
  late Future<List<Comment>> commentsFuture;
  bool isLiked = false;
  bool isSaved = false;
  int totalLikes = 0;

  @override
  void initState() {
    super.initState();
    commentsFuture = fetchComments();
    totalLikes = widget.post.likesCount ?? 0;
    isLiked = false; // Update this based on user-specific likes.
  }

  Future<List<Comment>> fetchComments() async {
    return await ApiService().fetchComments(widget.post.id);
  }

  void toggleLike() async {
    setState(() {
      isLiked = !isLiked;
      totalLikes += isLiked ? 1 : -1;
    });

    try {
      await ApiService().updatePostLikes(widget.post.id, isLiked);
    } catch (e) {
      setState(() {
        isLiked = !isLiked;
        totalLikes += isLiked ? -1 : 1;
      });
      print("Error toggling like: $e");
    }
  }

  void addComment() async {
    final commentContent = _commentController.text.trim();
    if (commentContent.isEmpty) return;

    try {
      // Call the updated addComment method
      final response = await ApiService().addComment(
        postId: widget.post.id,
        content: commentContent,
      );

      if (response.statusCode == 201) {
        _commentController.clear();
        setState(() {
          commentsFuture = fetchComments();
        });
      } else {
        print("Failed to add comment: ${response.body}");
      }
    } catch (e) {
      print("Error adding comment: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      appBar: AppBar(
        title: Text(post.title ?? "Post Details"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.images != null && post.images!.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.images!.length,
                  itemBuilder: (context, index) {
                    final imageUrl = post.images![index].imageUrl;
                    return Image.network(imageUrl, fit: BoxFit.cover);
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title ?? "Untitled Post",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(post.content ?? "No content available."),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                            ),
                            onPressed: toggleLike,
                          ),
                          Text("$totalLikes likes"),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? Colors.blue : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            isSaved = !isSaved;
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  FutureBuilder<List<Comment>>(
                    future: commentsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text(
                            "Error loading comments: ${snapshot.error}");
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text("No comments yet.");
                      }

                      final comments = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                comment.user.profilePictureUrl ??
                                    'https://via.placeholder.com/150',
                              ),
                            ),
                            title: Text(comment.user.username),
                            subtitle: Text(comment.content),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: "Write a comment...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: addComment,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

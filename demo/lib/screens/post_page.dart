import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';

class PostPage extends StatefulWidget {
  final int postId;
  final void Function(Post updatedPost)? onPostUpdated; // Add callback

  const PostPage({super.key, required this.postId, this.onPostUpdated});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final FocusNode _commentFocusNode = FocusNode();
  final TextEditingController _commentController = TextEditingController();
  late Future<Post> postFuture;
  late Future<List<Comment>> commentsFuture;
  final ApiService apiService = ApiService();

  final Map<int, bool> expandedComments = {};
  int? activeReplyToCommentId;
  String? replyingToUsername;

  @override
  void initState() {
    super.initState();
    postFuture = fetchPostDetail();
    commentsFuture = fetchComments();
  }

  Future<Post> fetchPostDetail() async {
    return await apiService.fetchPostDetail(widget.postId);
  }

  Future<List<Comment>> fetchComments() async {
    return await apiService.fetchComments(widget.postId);
  }

  void togglePostLike(Post post) async {
    try {
      final response = await apiService.updatePostLikes(post.id);
      setState(() {
        post.isLiked = response['is_liked'];
        post.likesCount = response['likes_count'];
      });
      if (widget.onPostUpdated != null) {
        widget.onPostUpdated!(post); // Notify FeedPage of the updated post
      }
    } catch (e) {
      print("Error toggling post like: $e");
    }
  }

  void toggleCommentLike(Comment comment) async {
    try {
      final response = await apiService.updateCommentLikes(comment.id);

      setState(() {
        comment.isLiked = response['is_liked'];
        comment.likesCount = response['likes_count'];
      });
    } catch (e) {
      print("Error toggling comment like: $e");
    }
  }

  void toggleSave(Post post) async {
    setState(() {
      post.isSaved = !post.isSaved; // Optimistic UI update
    });

    try {
      await apiService.updatePostSaves(post.id, post.isSaved);
    } catch (e) {
      print("Error toggling save: $e");
      setState(() {
        post.isSaved = !post.isSaved; // Revert if there's an error
      });
    }
  }

  void addComment(int postId) async {
    final commentContent = _commentController.text.trim();
    if (commentContent.isEmpty) return;

    final prefixedContent = replyingToUsername != null
        ? '@$replyingToUsername $commentContent'
        : commentContent;

    try {
      await apiService.addComment(
        postId: postId,
        content: prefixedContent,
      );
      _commentController.clear();
      cancelReply();
      setState(() {
        commentsFuture = fetchComments();
      });
    } catch (e) {
      print("Error adding comment: $e");
    }
  }

  void activateReplyTo(int commentId, String username) {
    setState(() {
      activeReplyToCommentId = commentId;
      replyingToUsername = username;
    });
    _commentController.clear();
    _commentFocusNode.requestFocus(); // Focus on the comment box
  }

  void cancelReply() {
    setState(() {
      activeReplyToCommentId = null;
      replyingToUsername = null;
    });
  }

  void toggleExpand(int commentId) {
    setState(() {
      expandedComments[commentId] = !(expandedComments[commentId] ?? false);
    });
  }

  void pickImage() {}

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.month}-${date.day}';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Post>(
          future: postFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text("Post Details");
            final post = snapshot.data!;
            return Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(post.user.profilePictureUrl),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.user.username,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formatDate(post.createdAt),
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          // Main content
          Expanded(
            child: FutureBuilder<Post>(
              future: postFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData) {
                  return const Center(child: Text("Post not found"));
                }

                final post = snapshot.data!;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.images.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: post.images.length,
                            itemBuilder: (context, index) {
                              final imageUrl = post.images[index].imageUrl;
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
                              post.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post.content),
                                const SizedBox(height: 10),
                                Text(
                                  formatDate(post.createdAt),
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    post.isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color:
                                        post.isLiked ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: () => togglePostLike(post),
                                ),
                                Text("${post.likesCount} likes"),
                                const SizedBox(width: 10),
                                IconButton(
                                  icon: Icon(
                                    post.isSaved
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: post.isSaved
                                        ? const Color.fromARGB(255, 255, 193, 7)
                                        : Colors.grey,
                                  ),
                                  onPressed: () => toggleSave(post),
                                ),
                              ],
                            ),
                            const Divider(),
                            const Text(
                              "Comments",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            FutureBuilder<List<Comment>>(
                              future: commentsFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                } else if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      "Error loading comments: ${snapshot.error}",
                                    ),
                                  );
                                } else if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return const Text("No comments yet.");
                                }

                                final comments = snapshot.data!;
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: comments.length,
                                  itemBuilder: (context, index) {
                                    final comment = comments[index];
                                    final subComments = comments
                                        .where((c) => c.replyTo == comment.id)
                                        .toList();
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ListTile(
                                          title: Text(comment.user.username),
                                          subtitle: Text(comment.content),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                  comment.isLiked
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color: comment.isLiked
                                                      ? Colors.red
                                                      : Colors.grey,
                                                ),
                                                onPressed: () =>
                                                    toggleCommentLike(comment),
                                              ),
                                              Text("${comment.likesCount}"),
                                            ],
                                          ),
                                          onTap: () => activateReplyTo(
                                            comment.id,
                                            comment.user.username,
                                          ),
                                        ),
                                        if (expandedComments[comment.id] ==
                                            true)
                                          for (var subComment in subComments)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 40.0),
                                              child: ListTile(
                                                title: Text(
                                                    subComment.user.username),
                                                subtitle:
                                                    Text(subComment.content),
                                              ),
                                            ),
                                        if (subComments.isNotEmpty)
                                          TextButton(
                                            onPressed: () =>
                                                toggleExpand(comment.id),
                                            child: Text(expandedComments[
                                                        comment.id] ==
                                                    true
                                                ? "Hide replies"
                                                : "View ${subComments.length} replies"),
                                          ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Fixed footer
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                if (activeReplyToCommentId != null)
                  Container(
                    color: Colors.grey[200],
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Replying to @$replyingToUsername',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel),
                          onPressed: cancelReply,
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _commentFocusNode,
                        decoration: InputDecoration(
                          hintText: activeReplyToCommentId == null
                              ? "Say something..."
                              : "Reply to @$replyingToUsername...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color.fromARGB(135, 245, 245, 245),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.image),
                      onPressed: pickImage, // Pick image from the gallery
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => addComment(widget.postId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

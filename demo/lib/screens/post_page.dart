import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
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
  List<Comment>? commentsCache;
  final Map<int, bool> expandedComments = {};
  int? activeReplyToCommentId;
  String? replyingToUsername;

  // Controller for the PageView
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    postFuture = fetchPostDetail();
    commentsFuture = fetchComments().then((comments) {
      commentsCache = comments;
      return comments;
    });
  }

  @override
  void dispose() {
    _pageController.dispose(); // Dispose of the PageController
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

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

  void toggleExpand(int commentId) {
    setState(() {
      expandedComments[commentId] = !(expandedComments[commentId] ?? false);
    });
  }

  void pickImage() {}

  void activateReplyTo(int commentId, String username) {
    setState(() {
      activeReplyToCommentId = commentId;
      replyingToUsername = username;
    });
    _commentFocusNode.requestFocus();
  }

  void cancelReply() {
    setState(() {
      activeReplyToCommentId = null;
      replyingToUsername = null;
    });
  }

  Comment? findTopLevelComment(List<Comment> comments, int commentId) {
    for (var comment in comments) {
      if (comment.id == commentId) {
        // If the comment is a top-level comment (replyTo is null), return it
        if (comment.replyTo == null) {
          return comment;
        } else {
          // Otherwise, recursively find the top-level comment
          return findTopLevelComment(comments, comment.replyTo!);
        }
      }
      // If not found, search in its replies
      final foundInReplies = findTopLevelComment(comment.replies, commentId);
      if (foundInReplies != null) {
        return foundInReplies;
      }
    }
    return null; // Not found
  }

  void addComment(int postId) async {
    final commentContent = _commentController.text.trim();
    if (commentContent.isEmpty) return;

    final prefixedContent = replyingToUsername != null
        ? '@$replyingToUsername $commentContent'
        : commentContent;

    try {
      // Call the API to add the comment
      await apiService.addComment(
        postId: postId,
        content: prefixedContent,
        replyTo: activeReplyToCommentId, // Pass replyTo for nested replies
      );

      // Clear the input field and cancel reply mode
      _commentController.clear();
      cancelReply();

      // Refresh the comments by re-fetching from the backend
      setState(() {
        commentsFuture = fetchComments().then((comments) {
          commentsCache = comments; // Update the local cache
          return comments;
        });
      });
    } catch (e) {
      print("Error adding comment: $e");
    }
  }

  Widget buildPostHeader(Future<Post> postFuture) {
    return FutureBuilder<Post>(
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
              ],
            ),
          ],
        );
      },
    );
  }

  Widget buildPostContent(Post post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (post.images.isNotEmpty)
          Column(
            children: [
              // Swipeable image carousel
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: post.images.length,
                  itemBuilder: (context, index) {
                    final imageUrl = post.images[index].imageUrl;
                    return Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              // Dot indicator for the image carousel
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Center(
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: post.images.length,
                    effect: const WormEffect(
                      dotHeight: 8.0,
                      dotWidth: 8.0,
                      activeDotColor: Colors.blue,
                      dotColor: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
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
              Text(post.content),
              const SizedBox(height: 10),
              Text(
                formatDate(post.createdAt),
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildPostActions(Post post) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            post.isLiked ? Icons.favorite : Icons.favorite_border,
            color: post.isLiked ? Colors.red : Colors.grey,
          ),
          onPressed: () => togglePostLike(post),
        ),
        Text("${post.likesCount}"),
        IconButton(
          icon: Icon(
            post.isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: post.isSaved
                ? const Color.fromARGB(255, 255, 193, 7)
                : Colors.grey,
          ),
          onPressed: () => toggleSave(post),
        ),
        Text("${post.likesCount}"),
      ],
    );
  }

  Widget buildCommentsSection() {
    return FutureBuilder<List<Comment>>(
      future: commentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text("Error loading comments: ${snapshot.error}"),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text("No comments yet.");
        }

        final comments = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            return buildCommentTree(comments[index]);
          },
        );
      },
    );
  }

  Widget buildCommentTree(Comment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0), // Add space between comments
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Render the main comment
          InkWell(
            onTap: () => activateReplyTo(comment.id, comment.user.username),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Align at the top
              children: [
                // Avatar
                CircleAvatar(
                  backgroundImage: NetworkImage(comment.user.profilePictureUrl),
                ),
                const SizedBox(width: 10), // Space between avatar and content
                // Comment content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username
                      Text(
                        comment.user.username,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight:
                              FontWeight.w600, // Makes the text semi-bold
                        ),
                      ),
                      const SizedBox(
                          height: 2), // Small space between username and text
                      // Comment text
                      Text(
                        comment.content,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                      const SizedBox(
                          height: 2), // Space between text and metadata
                      // Date and Reply Row
                      Row(
                        children: [
                          Text(
                            formatDate(comment.createdAt),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => activateReplyTo(
                                comment.id, comment.user.username),
                            child: const Text(
                              "Reply",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color.fromARGB(255, 120, 120, 120),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Likes and Like Button
                Column(
                  mainAxisAlignment:
                      MainAxisAlignment.start, // Align with the top
                  children: [
                    IconButton(
                      icon: Icon(
                        comment.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: comment.isLiked ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => toggleCommentLike(comment),
                    ),
                    Text(
                      "${comment.likesCount}",
                      style: const TextStyle(fontSize: 10, color: Colors.black),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // If the comment has replies, show "View # replies" button
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 45.0), // Indent replies
              child: TextButton(
                onPressed: () {
                  toggleExpand(comment.id);
                },
                child: Text(expandedComments[comment.id] == true
                    ? 'Hide replies'
                    : 'View ${comment.replies.length} replies'),
              ),
            ),
          // If replies are expanded, display them
          if (expandedComments[comment.id] == true)
            Padding(
              padding: const EdgeInsets.only(left: 45.0), // Indent replies
              child: Column(
                children: comment.replies.map(buildCommentTree).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildCommentInput() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          if (activeReplyToCommentId != null)
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                icon: const Icon(Icons.send),
                onPressed: () => addComment(widget.postId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: buildPostHeader(postFuture), // Header without padding
      ),
      body: Column(
        children: [
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
                      buildPostContent(
                          post), // Post content (images and main text)
                      buildPostActions(
                          post), // Reactions section (like, save, etc.)
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.0), // Add padding to comments header
                        child: Text(
                          'Comments',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal:
                                16.0), // Add padding to comments section
                        child: buildCommentsSection(),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            ),
          ),
          buildCommentInput(), // Comment input box (excluded from padding)
        ],
      ),
    );
  }
}

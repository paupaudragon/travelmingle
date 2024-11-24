import 'dart:io';
import 'package:demo/services/api_service.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import 'package:image_picker/image_picker.dart';

class PostPage extends StatefulWidget {
  final Post post;
  final User adminUser; // Pass the "admin" user to the page

  const PostPage({Key? key, required this.post, required this.adminUser})
      : super(key: key);

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final Map<int, bool> expandedComments = {};
  final TextEditingController _commentController = TextEditingController();
  int? activeReplyToCommentId;
  String? replyingToUsername; // Tracks the username being replied to
  File? selectedImage; // Holds the selected image

  final ImagePicker _picker = ImagePicker();

  int totalLikes = 0;
  int totalSaves = 0;
  int totalComments = 0;
  bool isLiked = false;
  bool isSaved = false;

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
  void initState() {
    super.initState();
    totalLikes = widget.post.likes;
    totalSaves = widget.post.saves;
    totalComments = widget.post.comments.length;
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
      print("Image selected: ${pickedFile.path}");
    }
  }

  void toggleLike() async {
    setState(() {
      isLiked = !isLiked;
      totalLikes += isLiked ? 1 : -1;
    });

    try {
      await ApiService().updatePostLikes(widget.post.id, isLiked);
      print('Likes updated successfully');
    } catch (e) {
      print('Failed to update likes: $e');
      setState(() {
        isLiked = !isLiked;
        totalLikes += isLiked ? -1 : 1;
      });
    }
  }

  void toggleSave() async {
    setState(() {
      isSaved = !isSaved;
      totalSaves += isSaved ? 1 : -1;
    });

    try {
      await ApiService().updatePostSaves(widget.post.id, isSaved);
      print('Saves updated successfully');
    } catch (e) {
      print('Failed to update saves: $e');
      setState(() {
        isSaved = !isSaved;
        totalSaves += isSaved ? -1 : 1;
      });
    }
  }

  void toggleExpand(int commentId) {
    setState(() {
      expandedComments[commentId] = !(expandedComments[commentId] ?? false);
    });
  }

  void addComment() async {
    final newCommentText = _commentController.text.trim();
    if (newCommentText.isEmpty && selectedImage == null) return;

    final prefixedText = replyingToUsername != null
        ? '@$replyingToUsername $newCommentText'
        : newCommentText;

    print(
        'Adding comment with: postId=${widget.post.id}, userId=${widget.adminUser.id}, content=$prefixedText, parentId=$activeReplyToCommentId');

    try {
      final response = await ApiService().addComment(
        postId: widget.post.id,
        userId: widget.adminUser.id,
        content: prefixedText,
        parentId: activeReplyToCommentId,
      );

      if (response.statusCode == 201) {
        setState(() {
          totalComments++;
          widget.post.comments.add(
            Comment(
              id: DateTime.now().millisecondsSinceEpoch, // Temporary unique ID
              user: widget.adminUser,
              content: prefixedText,
              createdAt: DateTime.now(),
              parentId: activeReplyToCommentId,
              imagePath: selectedImage?.path,
            ),
          );
          _commentController.clear();
          cancelReply();
          selectedImage = null;
        });

        await ApiService().updateCommentsCount(widget.post.id, totalComments);
      } else {
        print('Failed to add comment: ${response.body}');
      }
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  void activateReplyTo(int? commentId, String username) {
    setState(() {
      activeReplyToCommentId = commentId;
      replyingToUsername = username;
    });
    _commentController.text = "";
  }

  void cancelReply() {
    setState(() {
      activeReplyToCommentId = null;
      replyingToUsername = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = formatDate(widget.post.createdAt);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.post.user.profilePicture != null &&
                      widget.post.user.profilePicture!.isNotEmpty
                  ? AssetImage(widget.post.user.profilePicture!)
                  : const AssetImage('assets/default_profile.png'),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.user.username,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/cover.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 250,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.post.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.post.content,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Comments',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (widget.post.comments.isEmpty)
                    const Text(
                      'No comments available for this post.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.post.comments
                          .where((c) => c.parentId == null)
                          .length,
                      itemBuilder: (context, index) {
                        final topComments = widget.post.comments
                            .where((c) => c.parentId == null)
                            .toList();
                        final comment = topComments[index];
                        final subComments = widget.post.comments
                            .where((c) => c.parentId == comment.id)
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Render the top-level comment
                            ListTile(
                              leading: CircleAvatar(
                                backgroundImage: comment.user.profilePicture !=
                                        null
                                    ? AssetImage(comment.user.profilePicture!)
                                    : const AssetImage(
                                        'assets/default_profile.png'),
                              ),
                              title: Text(comment.user.username),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(comment.content),
                                  if (comment.imagePath !=
                                      null) // Check if there's an image to display
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Image.file(
                                        File(comment
                                            .imagePath!), // Display the selected image
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  Text(
                                    formatDate(comment.createdAt),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              onTap: () => activateReplyTo(
                                  comment.id, comment.user.username),
                            ),

                            // Render the nested sub-comments
                            if (expandedComments[comment.id] == true)
                              for (var subComment in subComments)
                                Padding(
                                  padding: const EdgeInsets.only(left: 40.0),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage: subComment
                                                  .user.profilePicture !=
                                              null
                                          ? AssetImage(
                                              subComment.user.profilePicture!)
                                          : const AssetImage(
                                              'assets/default_profile.png'),
                                    ),
                                    title: Text(subComment.user.username),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(subComment.content),
                                        Text(
                                          formatDate(subComment.createdAt),
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    onTap: () => activateReplyTo(subComment.id,
                                        subComment.user.username),
                                  ),
                                ),
                            // Expand/collapse button for sub-comments
                            if (subComments.isNotEmpty &&
                                expandedComments[comment.id] != true)
                              Padding(
                                padding: const EdgeInsets.only(left: 40.0),
                                child: TextButton(
                                  onPressed: () {
                                    toggleExpand(comment.id);
                                  },
                                  child: Text(
                                      'View ${subComments.length} replies'),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: toggleLike,
                child: Row(
                  children: [
                    Icon(
                      isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isLiked
                          ? Color.fromARGB(255, 218, 10, 10)
                          : Color.fromARGB(255, 96, 96, 96),
                    ),
                    const SizedBox(width: 5),
                    Text('$totalLikes'),
                  ],
                ),
              ),
              GestureDetector(
                onTap: toggleSave,
                child: Row(
                  children: [
                    Icon(
                      isSaved ? Icons.star_rounded : Icons.star_border_rounded,
                      color: isSaved
                          ? const Color.fromARGB(255, 255, 193, 7)
                          : Color.fromARGB(255, 96, 96, 96),
                    ),
                    const SizedBox(width: 5),
                    Text('$totalSaves'),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.comment_rounded,
                      color: Color.fromARGB(255, 96, 96, 96)),
                  const SizedBox(width: 5),
                  Text('$totalComments'),
                ],
              ),
            ],
          ),
          if (activeReplyToCommentId != null) // Show when replying
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                if (selectedImage !=
                    null) // Show image preview if an image is selected
                  Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            selectedImage!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedImage = null; // Remove the selected image
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: activeReplyToCommentId == null
                              ? "Say something..."
                              : "Reply to @$replyingToUsername...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.image),
                      onPressed: pickImage, // Pick image from the gallery
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed:
                          addComment, // Submit comment with or without the image
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

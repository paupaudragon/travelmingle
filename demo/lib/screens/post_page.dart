import 'package:flutter/material.dart';
import '../models/post_model.dart';

class PostPage extends StatefulWidget {
  final Post post;

  const PostPage({Key? key, required this.post}) : super(key: key);

  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final Map<int, bool> expandedComments = {};

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  void toggleExpand(int commentId) {
    setState(() {
      expandedComments[commentId] = !(expandedComments[commentId] ?? false);
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                print("Follow button pressed");
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text("Follow"),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
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
                itemCount: widget.post.comments.where((c) => c.parentId == null).length,
                itemBuilder: (context, index) {
                  final topComments = widget.post.comments.where((c) => c.parentId == null).toList();
                  final comment = topComments[index];
                  final subComments = widget.post.comments.where((c) => c.parentId == comment.id).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top-level comment
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: comment.user.profilePicture != null
                              ? AssetImage(comment.user.profilePicture!)
                              : const AssetImage('assets/default_profile.png'),
                        ),
                        title: Text(comment.user.username),
                        subtitle: Text(comment.content),
                      ),
                      // Display all sub-comments if expanded
                      if (expandedComments[comment.id] == true)
                        for (var subComment in subComments)
                          Padding(
                            padding: const EdgeInsets.only(left: 40.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: subComment.user.profilePicture != null
                                    ? AssetImage(subComment.user.profilePicture!)
                                    : const AssetImage('assets/default_profile.png'),
                              ),
                              title: Text(subComment.user.username),
                              subtitle: Text(subComment.content),
                            ),
                          ),
                      // Show "View more replies" button
                      if (subComments.isNotEmpty && expandedComments[comment.id] != true)
                        Padding(
                          padding: const EdgeInsets.only(left: 40.0),
                          child: TextButton(
                            onPressed: () {
                              toggleExpand(comment.id);
                            },
                            child: Text('View ${subComments.length} replies'),
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

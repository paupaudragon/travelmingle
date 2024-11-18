import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Ensure this works after adding the package
import '../models/post_model.dart';

class PostPage extends StatelessWidget {
  final Post post;

  const PostPage({Key? key, required this.post}) : super(key: key);

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 1) {
      return DateFormat('MMM d, h:mm a').format(date); // Example: Nov 15, 3:45 PM
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = formatDate(post.createdAt);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: post.user.profilePicture != null &&
                      post.user.profilePicture!.isNotEmpty
                  ? AssetImage(post.user.profilePicture!)
                  : const AssetImage('assets/default_profile.png'),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.user.username,
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
                // Placeholder for follow functionality
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
            // Single Image Section
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/cover.png', // Replace with your actual path
                fit: BoxFit.cover,
                width: double.infinity,
                height: 250,
              ),
            ),
            const SizedBox(height: 20),

            // Title Section
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Content Section
            Text(
              post.content,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

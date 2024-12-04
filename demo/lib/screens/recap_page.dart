import 'dart:io';
import 'dart:typed_data';
import 'package:demo/screens/post_page.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';

class RecapPage extends StatelessWidget {
  final List<Post> posts;
  final Function(int) navigateToPost;

  RecapPage({required this.posts, required this.navigateToPost, Key? key})
      : super(key: key);

  final PageController _pageController = PageController();

  // Dedicated ScreenshotControllers for each page
  final ScreenshotController mostLikedController = ScreenshotController();
  final ScreenshotController mostCommentedController = ScreenshotController();
  final ScreenshotController mostSavedController = ScreenshotController();

  Post? getMostLikedPost() {
    if (posts.isEmpty) return null;
    int maxLikes =
        posts.map((post) => post.likesCount).reduce((a, b) => a > b ? a : b);
    return posts.firstWhere((post) => post.likesCount == maxLikes);
  }

  Post? getMostCommentedPost() {
    if (posts.isEmpty) return null;
    int maxComments = posts
        .map((post) => post.detailedComments.length)
        .reduce((a, b) => a > b ? a : b);
    return posts
        .firstWhere((post) => post.detailedComments.length == maxComments);
  }

  Post? getMostSavedPost() {
    if (posts.isEmpty) return null; // Return null if the list is empty
    int maxSaves =
        posts.map((post) => post.savesCount).reduce((a, b) => a > b ? a : b);
    return posts.firstWhere((post) => post.savesCount == maxSaves);
  }

  Future<void> shareRecap(
      BuildContext context, ScreenshotController screenshotController) async {
    try {
      // Capture the widget as an image
      final Uint8List? image = await screenshotController.capture();
      if (image == null) return;

      // Save the image temporarily
      final directory = await getTemporaryDirectory();
      final imagePath = File('${directory.path}/recap_image.png');
      await imagePath.writeAsBytes(image);

      // Share the image
      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: "Check out my popular post!",
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error sharing recap: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildRecapContent({
    required BuildContext context,
    required ScreenshotController controller,
    required Post? post,
    required String text,
    required String textTail, // New parameter for dynamic tail text
    required String metricValue,
    required Color metricColor,
    required Color backgroundColor,
    required Color buttonColor,
    required Color buttonTextColor,
    required Color shareButtonColor,
    required Color shareButtonTextColor,
    required Function() onSharePressed,
  }) {
    return Screenshot(
      controller: controller,
      child: Container(
        color: backgroundColor,
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.home),
                    onPressed: () {
                      Navigator.pushNamed(context, '/feed');
                    },
                  ),
                ],
              ),
            ),
            if (post != null)
              Padding(
                padding: const EdgeInsets.only(top: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PostPage(postId: post.id)),
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: PostCard(post: post),
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: text,
                        style: const TextStyle(
                          fontSize: 46,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: metricValue,
                            style: TextStyle(
                              color: metricColor,
                              fontSize: 46,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: " $textTail", // Append tail text dynamically
                            style: const TextStyle(
                              fontSize: 46,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text(
                    "No posts available",
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ),
            // Share Button
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: shareButtonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                ),
                onPressed: onSharePressed,
                icon: Icon(Icons.share_rounded, color: shareButtonTextColor),
                label: Text(
                  "Share",
                  style: TextStyle(
                    color: shareButtonTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mostLikedPost = getMostLikedPost();
    final mostCommentedPost = getMostCommentedPost();
    final mostSavedPost = getMostSavedPost();

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            children: [
              // First Recap: Most Liked Post
              buildRecapContent(
                context: context,
                controller: mostLikedController, // Use dedicated controller
                post: mostLikedPost,
                text: "Your most popular post got ",
                textTail: "likes", // Specify the tail text
                metricValue: "${mostLikedPost?.likesCount ?? 0}",
                metricColor: Colors.pinkAccent,
                backgroundColor: const Color.fromARGB(255, 82, 253, 244),
                buttonColor: Colors.black,
                buttonTextColor: Colors.pinkAccent,
                shareButtonColor: Colors.pinkAccent,
                shareButtonTextColor: Colors.black,
                onSharePressed: () =>
                    shareRecap(context, mostLikedController), // Use dedicated controller
              ),
              // Second Recap: Most Commented Post
              buildRecapContent(
                context: context,
                controller: mostCommentedController, // Use dedicated controller
                post: mostCommentedPost,
                text: "Your post with the most interactions got ",
                textTail: "comments", // Specify the tail text
                metricValue:
                    "${mostCommentedPost?.detailedComments.length ?? 0}",
                metricColor: const Color.fromARGB(255, 255, 242, 7),
                backgroundColor: const Color.fromARGB(255, 65, 252, 155),
                buttonColor: const Color.fromARGB(255, 255, 242, 7),
                buttonTextColor: Colors.black,
                shareButtonColor: const Color.fromARGB(255, 255, 242, 7),
                shareButtonTextColor: Colors.black,
                onSharePressed: () =>
                    shareRecap(context, mostCommentedController), // Use dedicated controller
              ),
              buildRecapContent(
                context: context,
                controller: mostSavedController, // Use dedicated controller
                post: mostCommentedPost,
                text: "Your post with the most saves got ",
                textTail: "saves", // Specify the tail text
                metricValue: "${mostSavedPost?.savesCount ?? 0}",
                metricColor: const Color.fromARGB(255, 251, 246, 163),
                backgroundColor: Colors.pinkAccent,
                buttonColor: const Color.fromARGB(255, 251, 246, 163),
                buttonTextColor: Colors.black,
                shareButtonColor: const Color.fromARGB(255, 251, 246, 163),
                shareButtonTextColor: Colors.black,
                onSharePressed: () =>
                    shareRecap(context, mostSavedController), // Use dedicated controller
              ),
            ],
          ),
          Positioned(
            right: 16.0,
            top: MediaQuery.of(context).size.height / 3 - 60,
            child: SmoothPageIndicator(
              controller: _pageController,
              count: 3,
              axisDirection: Axis.vertical,
              effect: const WormEffect(
                dotHeight: 6,
                dotWidth: 6,
                activeDotColor: Color.fromARGB(185, 57, 56, 56),
                dotColor: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

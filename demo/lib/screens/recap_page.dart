import 'dart:io';
import 'dart:typed_data';
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

  Post? getMostLikedPost() {
    if (posts.isEmpty) return null;
    int maxLikes =
        posts.map((post) => post.likesCount).reduce((a, b) => a > b ? a : b);
    return posts.firstWhere((post) => post.likesCount == maxLikes);
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

  Widget buildRecapContent(
      BuildContext context, ScreenshotController controller) {
    final Post? mostLikedPost = getMostLikedPost();
    final int maxLikes = mostLikedPost?.likesCount ?? 0;

    return Screenshot(
      controller: controller,
      child: Column(
        children: [
          // Top Navigation Bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context); // Go back to ProfilePage
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () {
                    Navigator.pushNamed(
                        context, '/feed'); // Navigate to FeedPage
                  },
                ),
              ],
            ),
          ),
          // Content Area
          if (mostLikedPost != null)
            Padding(
              padding: const EdgeInsets.only(
                  top: 32.0), // Adjustable padding from the nav bar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Centered horizontally PostCard
                  GestureDetector(
                    onTap: () => navigateToPost(mostLikedPost.id),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width *
                          0.8, // Adjust width
                      child: PostCard(post: mostLikedPost),
                    ),
                  ),
                  const SizedBox(
                      height: 16), // Padding between the card and text
                  // Likes Information
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: "Your most popular post got ",
                      style: const TextStyle(
                        fontSize: 46,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      children: [
                        TextSpan(
                          text: "$maxLikes",
                          style: const TextStyle(
                            color: Colors.pinkAccent,
                            fontSize: 46,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: " likes"),
                      ],
                    ),
                  ),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color.fromARGB(255, 82, 253, 244), // Cyan background
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            scrollDirection: Axis.vertical, // Swipe up and down
            children: [
              buildRecapContent(
                  context, ScreenshotController()), // Unique controller
              buildRecapContent(
                  context, ScreenshotController()), // Another unique controller
            ],
          ),
          // Vertical Dot Indicator
          Positioned(
            right: 16.0,
            top: MediaQuery.of(context).size.height / 2 - 60,
            child: SmoothPageIndicator(
              controller: _pageController,
              count: 2, // Update with the number of pages
              axisDirection: Axis.vertical,
              effect: const WormEffect(
                dotHeight: 6,
                dotWidth: 6,
                activeDotColor: Color.fromARGB(185, 57, 56, 56), // Dark gray for the active dot
                dotColor: Colors.grey, // Light gray for the inactive dots
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomCenter, // Center the button horizontally
        child: Padding(
          padding:
              const EdgeInsets.only(bottom: 16.0), // Small padding from bottom
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent, // Magenta color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0), // Rounded corners
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            ),
            onPressed: () => shareRecap(context, ScreenshotController()),
            icon: const Icon(Icons.share_rounded, color: Colors.black),
            label: const Text(
              "Share",
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }
}

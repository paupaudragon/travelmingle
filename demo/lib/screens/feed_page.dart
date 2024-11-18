import 'package:flutter/material.dart';
import '../widgets/header.dart'; // Import Header
import '../widgets/footer.dart'; // Import Footer
import '../services/api_service.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<Post> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    final apiService = ApiService();
    final fetchedPosts = await apiService.fetchPosts();
    setState(() {
      posts = fetchedPosts;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60), // Header height
        child: Header(
          onFollowPressed: () {
            print("Follow button pressed");
          },
          onExplorePressed: () {
            print("Explore button pressed");
          },
          onNearbyPressed: () {
            print("Nearby button pressed");
          },
          onMenuPressed: () {
            print("Menu button pressed");
          },
          onSearchPressed: () {
            print("Search button pressed");
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two columns
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.7, // Adjusted to show two rows on screen
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostCard(post: post); // Use PostCard for individual items
              },
            ),
      bottomNavigationBar: Footer(
        onHomePressed: () {
          print("Home button pressed");
        },
        onShopPressed: () {
          print("Shop button pressed");
        },
        onPlusPressed: () {
          print("+ button pressed");
        },
        onMessagesPressed: () {
          print("Messages button pressed");
        },
        onMePressed: () {
          print("Me button pressed");
        },
      ),
    );
  }
}

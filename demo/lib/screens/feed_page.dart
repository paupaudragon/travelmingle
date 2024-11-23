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

  // Define the "admin" user
  final User adminUser = User(
    id: 0,
    username: "admin",
    email: "admin@example.com",
    bio: "Admin of the platform",
    profilePicture: 'profiles/user0.png', // Path to admin's profile picture
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    final apiService = ApiService();
    final fetchedPosts = await apiService.fetchPosts();

    print('Fetched Posts: ${fetchedPosts.length}');
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
              padding: const EdgeInsets.all(8.0), // Padding around the entire grid
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two columns
                childAspectRatio: 0.7, // Adjusted to show two rows on screen
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];

                print('Rendering Post: ${post.title}');

                // Pass the "admin" user and post's user to PostCard
                return PostCard(post: post, adminUser: adminUser);
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

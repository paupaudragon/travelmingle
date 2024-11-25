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
  bool isLoggedIn = false; // Track user login state

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

  void requireLogin(BuildContext context) {
    if (!isLoggedIn) {
      Navigator.pushNamed(context, '/login'); // Redirect to Login Page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Header(
          onFollowPressed: () => requireLogin(context),
          onExplorePressed: () => requireLogin(context),
          onNearbyPressed: () => requireLogin(context),
          onMenuPressed: () => requireLogin(context),
          onSearchPressed: () => requireLogin(context),
          onCreateUserPressed: () {
            Navigator.pushNamed(
                context, '/register'); // Navigate to Register Page
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8, // Adjusted aspect ratio for better fit
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return GestureDetector(
                  onTap: () => requireLogin(context), // Trigger login on tap
                  child: PostCard(post: post),
                );
              },
            ),
      bottomNavigationBar: Footer(
        onHomePressed: () => print("Home button pressed"),
        onShopPressed: () => print("Shop button pressed"),
        onPlusPressed: () =>
            requireLogin(context), // Require login for + button
        onMessagesPressed: () => requireLogin(context),
        onMePressed: () => requireLogin(context),
      ),
    );
  }
}

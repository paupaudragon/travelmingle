import 'package:demo/screens/login_page.dart';
import 'package:demo/screens/post_page.dart';
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

  void onPostTap(Post post) async {
    // Fetch and print user info
    final apiService = ApiService();
    final userInfo = await apiService.getUserInfo();

    if (userInfo != null) {
      print("User Info:");
      print("Username: ${userInfo['username']}");
      print("Email: ${userInfo['email']}");
    } else {
      print("Failed to fetch user info.");
    }

    //Optionally, navigate to a detailed post page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostPage(post: post),
      ),
    );
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

  void requireLogin(BuildContext context, {Function? onSuccess}) async {
    final apiService = ApiService();
    final token = await apiService.getAccessToken();

    if (token == null) {
      Navigator.pushNamed(context, '/login'); // Redirect to Login Page
    } else {
      setState(() {
        isLoggedIn = true; // Update login state
      });

      if (onSuccess != null) {
        onSuccess(); // Execute the success callback
      }
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
                  onTap: () => onPostTap(post),
                  child: PostCard(post: post),
                );
              },
            ),
      bottomNavigationBar: Footer(
        onHomePressed: () => print("Home button pressed"),
        onLogoutPressed: () => handleLogout(context),
        onPlusPressed: () =>
            requireLogin(context), // Require login for + button
        onMessagesPressed: () => requireLogin(context),
        onMePressed: () => requireLogin(context),
      ),
    );
  }

  void handleLogout(BuildContext context) async {
    try {
      await ApiService().logout(); // Call the logout service
      print("Logged out successfully.");
      // Navigate to the login page after logout
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print("Error during logout: $e");
      // Optionally, show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to log out. Please try again.")),
      );
    }
  }
}

import 'package:demo/screens/post_page.dart';
import 'package:demo/screens/profile_page.dart';
import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../services/api_service.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import 'create_post.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final ApiService _apiService = ApiService();
  List<Post> posts = [];
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    fetchPosts();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      setState(() {
        isLoading = true;
      });

      final fetchedPosts = await _apiService.fetchPosts();

      setState(() {
        posts = fetchedPosts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading posts: $e');
    }
  }

  Future<void> checkLoginStatus() async {
    final token = await _apiService.getAccessToken();
    setState(() {
      isLoggedIn = token != null;
    });

    if (!isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Future<void> fetchPosts() async {
    try {
      final fetchedPosts = await _apiService.fetchPosts();
      setState(() {
        posts = fetchedPosts;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching posts: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void toggleLike(Post post) async {
    try {
      final result = await _apiService.updatePostLikes(post.id);
      setState(() {
        post.isLiked = result['is_liked'];
        post.likesCount = result['likes_count'];
      });
    } catch (e) {
      print("Error toggling like: $e");
    }
  }

  void navigateToPostDetail(Post post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostPage(
          postId: post.id,
          onPostUpdated: (updatedPost) {
            setState(() {
              final index = posts.indexWhere((p) => p.id == updatedPost.id);
              if (index != -1) {
                posts[index] = updatedPost;
              }
            });
          },
        ),
      ),
    );
  }

  void handleLogout(BuildContext context) async {
    try {
      await ApiService().logout();
      print("Logged out successfully.");
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print("Error during logout: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to log out. Please try again.")),
      );
    }
  }

  void requireLogin(BuildContext context, {Function? onSuccess}) async {
    final apiService = ApiService();
    final token = await apiService.getAccessToken();

    if (token == null) {
      Navigator.pushNamed(context, '/login');
    } else {
      setState(() {
        isLoggedIn = true;
      });

      if (onSuccess != null) {
        onSuccess();
      }
    }
  }

  // New method to handle create post navigation
  Future<void> _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreatePostPage()),
    );

    if (result == true) {
      await _loadPosts();
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
            Navigator.pushNamed(context, '/register');
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final childAspectRatio =
              constraints.maxWidth / (constraints.maxHeight / 1.5);

          return isLoading
              ? const Center(child: CircularProgressIndicator())
              : posts.isEmpty
                  ? const Center(child: Text("No posts available."))
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 4.0,
                          mainAxisSpacing: 4.0,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return GestureDetector(
                            onTap: () => navigateToPostDetail(post),
                            child: PostCard(
                              post: post,
                              onLikePressed: () => toggleLike(post),
                            ),
                          );
                        },
                      ),
                    );
        },
      ),
      bottomNavigationBar: Footer(
        onHomePressed: () => print("Home button pressed"),
        onLogoutPressed: () => handleLogout(context),
        onPlusPressed: () {
          requireLogin(context);
          _navigateToCreatePost(); // Use the new method
        },
        onMessagesPressed: () => requireLogin(context),
        onMePressed: () => requireLogin(context, onSuccess: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        }),
      ),
    );
  }
}

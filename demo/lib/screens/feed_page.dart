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

class _FeedPageState extends State<FeedPage> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  List<Post> posts = [];
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    checkLoginStatus();
    _loadPosts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPosts();
    }
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;

    try {
      setState(() {
        isLoading = true;
      });

      final fetchedPosts = await _apiService.fetchPosts();

      if (!mounted) return;

      setState(() {
        posts = fetchedPosts;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
      print('Error loading posts: $e');
    }
  }

  Future<void> checkLoginStatus() async {
    final token = await _apiService.getAccessToken();
    if (!mounted) return;

    setState(() {
      isLoggedIn = token != null;
    });

    if (!isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void toggleLike(Post post) async {
    try {
      final result = await _apiService.updatePostLikes(post.id);
      if (!mounted) return;

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
            if (!mounted) return;
            setState(() {
              final index = posts.indexWhere((p) => p.id == updatedPost.id);
              if (index != -1) {
                posts[index] = updatedPost;
              }
            });
          },
        ),
      ),
    ).then((_) => _loadPosts()); // Refresh when returning from post detail
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
      if (!mounted) return;
      setState(() {
        isLoggedIn = true;
      });

      if (onSuccess != null) {
        onSuccess();
      }
    }
  }

  Future<void> _navigateToCreatePost() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreatePostPage()),
    ).then((_) => _loadPosts()); // Refresh when returning from create post
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
        onHomePressed: () {
          _loadPosts(); // Refresh when home is pressed
        },
        onLogoutPressed: () => handleLogout(context),
        onPlusPressed: () {
          requireLogin(context);
          _navigateToCreatePost();
        },
        onMessagesPressed: () => requireLogin(context),
        onMePressed: () => requireLogin(context, onSuccess: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          ).then((_) => _loadPosts()); // Refresh when returning from profile
        }),
      ),
    );
  }
}

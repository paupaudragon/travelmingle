import 'package:demo/screens/post_page.dart';
import 'package:demo/widgets/loading_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../widgets/header.dart';
import '../services/api_service.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import 'package:demo/screens/post_page.dart';

class LocationPostsPage extends StatefulWidget {
  final String locationName;

  const LocationPostsPage({Key? key, required this.locationName})
      : super(key: key);

  @override
  _LocationPostsPageState createState() => _LocationPostsPageState();
}

class _LocationPostsPageState extends State<LocationPostsPage> {
  final ApiService _apiService = ApiService();
  final RefreshController _refreshController = RefreshController();
  List<Post> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _onRefresh() async {
    try {
      final fetchedPosts =
          await _apiService.fetchPostsByLocation(widget.locationName);
      if (!mounted) return;
      setState(() {
        posts = fetchedPosts;
      });
      _refreshController.refreshCompleted();
    } catch (e) {
      print('Error refreshing posts: $e');
      _refreshController.refreshFailed();
    }
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    try {
      setState(() {
        isLoading = true;
      });

      final fetchedPosts =
          await _apiService.fetchPostsByLocation(widget.locationName);
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

  void _toggleLike(Post post) async {
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

  void _navigateToPostDetail(Post post) async {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Explore",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              widget.locationName,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: LoadingAnimation())
          : posts.isEmpty
              ? const Center(
                  child: Text("No posts available for this location."))
              : SmartRefresher(
                  controller: _refreshController,
                  onRefresh: _onRefresh,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: MasonryGridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 4.0,
                      crossAxisSpacing: 4.0,
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return GestureDetector(
                          onTap: () => _navigateToPostDetail(post),
                          child: PostCard(
                            post: post,
                            onLikePressed: () => _toggleLike(post),
                          ),
                        );
                      },
                    ),
                  ),
                ),
    );
  }
}

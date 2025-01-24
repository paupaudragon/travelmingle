import 'package:demo/screens/post_page.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../widgets/header.dart';
import '../services/api_service.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Explore",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
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
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return isLoading
              ? const Center(child: CircularProgressIndicator())
              : posts.isEmpty
                  ? const Center(
                      child: Text("No posts available for this location."))
                  : SmartRefresher(
                      controller: _refreshController,
                      onRefresh: _onRefresh,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PostPage(postId: post.id),
                                  ),
                                );
                              },
                              child: PostCard(post: post),
                            );
                          },
                        ),
                      ),
                    );
        },
      ),
    );
  }
}

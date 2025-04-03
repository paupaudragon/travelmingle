import 'package:flutter/material.dart';
import 'package:demo/screens/post_page.dart';
import '../services/api_service.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ApiService _apiService = ApiService();
  List<Post> posts = [];
  List<Post> filteredPosts = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _searchController.addListener(_filterPosts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    try {
      final fetchedPosts = await _apiService.fetchPostsBySource(
        source: "explore",
      );
      setState(() {
        posts = fetchedPosts;
        filteredPosts = fetchedPosts;
      });
    } catch (e) {
      print('Error loading posts: $e');
    }
  }

  void _filterPosts() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredPosts = posts; // Show all posts if search is empty
      } else {
        filteredPosts = posts.where((post) {
          return post.title.toLowerCase().contains(query) ||
              post.content!.toLowerCase().contains(query) ||
              post.user.username.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search Posts"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search posts',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredPosts.isEmpty
                  ? const Center(child: Text("No posts found"))
                  : ListView.builder(
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) {
                        final post = filteredPosts[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostPage(
                                  postId: post.id,
                                  onPostUpdated: (updatedPost) {
                                    setState(() {
                                      final index = posts.indexWhere(
                                          (p) => p.id == updatedPost.id);
                                      if (index != -1) {
                                        posts[index] = updatedPost;
                                        _filterPosts();
                                      }
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          child: PostCard(
                            post: post,
                            onLikePressed: () async {
                              try {
                                final result =
                                    await _apiService.updatePostLikes(post.id);
                                setState(() {
                                  post.isLiked = result['is_liked'];
                                  post.likesCount = result['likes_count'];
                                  _filterPosts(); // Refresh the filtered list
                                });
                              } catch (e) {
                                print("Error toggling like: $e");
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

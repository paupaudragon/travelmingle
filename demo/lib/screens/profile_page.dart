import 'package:demo/screens/user_list_page.dart';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../widgets/post_card.dart';

class ProfilePage extends StatefulWidget {
  final int? userId; // Add userId parameter, null means current user

  const ProfilePage({
    super.key,
    this.userId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  Map<String, dynamic>? userInfo;
  List<Post> allPosts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    try {
      Map<String, dynamic>? userData;

      if (widget.userId == null) {
        // Fetch current user's profile
        userData = await _apiService.getUserInfo();
      } else {
        userData = await _apiService.getUserProfile(widget.userId!);
      }

      final posts = await _apiService.fetchPosts();

      setState(() {
        userInfo = userData;
        allPosts = posts;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Post> getUserPosts() {
    if (userInfo == null) return [];
    return allPosts.where((post) => post.user.id == userInfo!['id']).toList();
  }

  List<Post> getSavedPosts() {
    // Only show saved posts for the current user
    if (widget.userId != null) return [];
    return allPosts.where((post) => post.isSaved).toList();
  }

  List<Post> getLikedPosts() {
    // Only show liked posts for the current user
    if (widget.userId != null) return [];
    return allPosts.where((post) => post.isLiked).toList();
  }

  Widget _buildProfileHeader() {
    if (userInfo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: userInfo!['profile_picture_url'] != null
                    ? NetworkImage(
                        '${ApiService.baseApiUrl}${userInfo!['profile_picture_url']}')
                    : null,
                child: userInfo!['profile_picture_url'] == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userInfo!['username'] ?? '',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (userInfo!['bio'] != null &&
                        userInfo!['bio'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(userInfo!['bio']),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        InkWell(
                          // Following count
                          onTap: () {
                            if (userInfo != null && userInfo!['id'] != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FollowListPage(
                                    userId: userInfo!['id'],
                                    initialTabIndex: 0,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              '${userInfo!['following_count'] ?? 0} Following',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          // Followers count
                          onTap: () {
                            if (userInfo != null && userInfo!['id'] != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FollowListPage(
                                    // Use FollowListPage, not UserListItem
                                    userId: userInfo!['id'],
                                    initialTabIndex: 1,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              '${userInfo!['followers_count'] ?? 0} Followers',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ], // <-- End of Row children
                    ), // <-- End of Row
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostGrid(List<Post> posts) {
    return posts.isEmpty
        ? const Center(child: Text('No posts to display'))
        : GridView.builder(
            padding: const EdgeInsets.all(4.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
              childAspectRatio: 0.8,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/post',
                    arguments: post.id,
                  );
                },
                child: PostCard(
                  post: post,
                  onLikePressed: () async {
                    try {
                      final result = await _apiService.updatePostLikes(post.id);
                      setState(() {
                        post.isLiked = result['is_liked'];
                        post.likesCount = result['likes_count'];
                      });
                    } catch (e) {
                      print("Error toggling like: $e");
                    }
                  },
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(userInfo?['username'] ?? 'Profile'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProfileHeader(),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Posts'),
                    Tab(text: 'Collects'),
                    Tab(text: 'Likes'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostGrid(getUserPosts()),
                      _buildPostGrid(getSavedPosts()),
                      _buildPostGrid(getLikedPosts()),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

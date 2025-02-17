import 'package:demo/main.dart';
import 'package:demo/screens/post_page.dart';
import 'package:demo/screens/recap_page.dart';
import 'package:demo/screens/user_list_page.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../widgets/post_card.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class ProfilePage extends StatefulWidget {
  final int? userId;

  const ProfilePage({
    super.key,
    this.userId,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final RefreshController _refreshController = RefreshController();
  late TabController _tabController;
  Map<String, dynamic>? userInfo;
  List<Post> allPosts = [];
  bool isLoading = true;
  String? error;
  bool? isFollowing;
  bool isUpdatingFollow = false;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeUserData();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void navigateToProfile(int userId) {
    if (userId != widget.userId) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(userId: userId),
        ),
      ).then((_) => _onRefresh());
    }
  }

  void navigateToPost(int postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostPage(
          postId: postId,
          onPostUpdated: (updatedPost) {
            // Update the state of the saved posts list
            setState(() {
              // Update the specific post in `allPosts`
              final index =
                  allPosts.indexWhere((post) => post.id == updatedPost.id);
              if (index != -1) {
                allPosts[index] = updatedPost;
              }
            });
          },
        ),
      ),
    ).then((_) => _onRefresh());
  }

  Future<void> fetchUserData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      Map<String, dynamic>? userData;
      if (widget.userId == null) {
        userData = await _apiService.getUserInfo();
      } else {
        userData = await _apiService.getUserProfileById(widget.userId!);
        // Get follow status directly from the profile response
        if (mounted) {
          setState(() {
            isFollowing = userData?['is_following'] ?? false;
          });
        }
      }

      final posts = await _apiService.fetchPostsBySource(
        source: "explore",
      );

      if (mounted) {
        setState(() {
          userInfo = userData;
          allPosts = posts;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      if (mounted) {
        setState(() {
          error = "Failed to load profile";
          isLoading = false;
        });
      }
    }
  }

  Future<void> toggleFollow() async {
    if (isUpdatingFollow || widget.userId == null) return;

    try {
      setState(() {
        isUpdatingFollow = true;
      });

      final result = await _apiService.followUser(widget.userId!);

      if (mounted) {
        setState(() {
          isFollowing = result['is_following'];
          if (userInfo != null) {
            userInfo!['followers_count'] = result['followers_count'];
          }
          isUpdatingFollow = false;
        });

        // Show feedback to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isFollowing == true ? 'Following user' : 'Unfollowed user'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("Error toggling follow status: $e");
      if (mounted) {
        setState(() {
          isUpdatingFollow = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update follow status: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  List<Post> getUserPosts() {
    if (userInfo == null) return [];
    return allPosts.where((post) => post.user.id == userInfo!['id']).toList();
  }

  List<Post> getSavedPosts() {
    final bool isCurrentUser =
        widget.userId == null || widget.userId == currentUserId;
    if (!isCurrentUser) return [];
    return allPosts.where((post) => post.isSaved).toList();
  }

  List<Post> getLikedPosts() {
    final bool isCurrentUser =
        widget.userId == null || widget.userId == currentUserId;
    if (!isCurrentUser) return [];
    return allPosts.where((post) => post.isLiked).toList();
  }

  void _openMenuDrawer() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Stack(
                children: [
                  // Transparent background
                  Container(color: Colors.transparent),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: MediaQuery.of(context).size.height,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16.0),
                          bottomLeft: Radius.circular(16.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(-5, 0),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.history),
                              title: const Text('Recap'),
                              onTap: () {
                                Navigator.pop(context);
                                _showReacapPage();
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.logout),
                              title: const Text('Log Out'),
                              onTap: () {
                                _logOutUser(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showReacapPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecapPage(
          posts: getUserPosts(),
          navigateToPost: navigateToPost,
        ),
      ),
    ).then((_) => _onRefresh());
  }

  void _logOutUser(BuildContext context) async {
    try {
      await ApiService().logout();
      print("Logged out successfully.");
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print("Error during logout: $e");
      // Optionally, show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to log out. Please try again.")),
      );
    }
  }

  Widget _buildProfileHeader() {
    if (userInfo == null) return const SizedBox.shrink();

    String? profilePictureUrl = userInfo!['profile_picture_url'];
    String? finalUrl;

    if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
      if (!profilePictureUrl.startsWith('http')) {
        if (profilePictureUrl.startsWith('/media')) {
          finalUrl =
              ApiService.baseApiUrl.replaceAll('/api', '') + profilePictureUrl;
        } else {
          finalUrl = ApiService.baseApiUrl + profilePictureUrl;
        }
      } else {
        finalUrl = profilePictureUrl;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage:
                    finalUrl != null ? NetworkImage(finalUrl) : null,
                child: finalUrl == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            userInfo!['username'] ?? '',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (widget.userId != null &&
                            widget.userId != currentUserId) ...[
                          const SizedBox(width: 8),
                          isUpdatingFollow
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : ElevatedButton(
                                  onPressed: toggleFollow,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isFollowing == true
                                        ? Colors.grey[300]
                                        : Theme.of(context).primaryColor,
                                    foregroundColor: isFollowing == true
                                        ? Colors.black
                                        : Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: Text(
                                    isFollowing == true
                                        ? 'Following'
                                        : 'Follow',
                                  ),
                                ),
                        ],
                      ],
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
                              ).then((_) => _onRefresh());
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
                          onTap: () {
                            if (userInfo != null && userInfo!['id'] != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FollowListPage(
                                    userId: userInfo!['id'],
                                    initialTabIndex: 1,
                                  ),
                                ),
                              ).then((_) => _onRefresh());
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
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

Widget _buildPostGrid(List<Post> posts) {
  return posts.isEmpty
      ? const Center(child: Text('No posts to display'))
      : Container(
          color: gridBackgroundColor,
          padding: const EdgeInsets.all(4.0),
          child: MasonryGridView.builder(
            gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            mainAxisSpacing: 4.0,
            crossAxisSpacing: 4.0,
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return GestureDetector(
                onTap: () => navigateToPost(post.id),
                child: PostCard(
                  post: post,
                  onLikePressed: () => toggleLike(post),
                ),
              );
            },
          ),
        );
}

  Future<void> _handleRefresh() async {
    try {
      await _initializeUserData();
    } catch (e) {
      print("Error refreshing data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _initializeUserData() async {
    try {
      // First get current user's ID
      final currentUserInfo = await _apiService.getUserInfo();
      if (mounted && currentUserInfo != null && currentUserInfo['id'] != null) {
        setState(() {
          currentUserId = currentUserInfo['id'];
        });
      }

      // Then fetch the profile data
      await fetchUserData();

      // Update tab controller based on whether this is the current user's profile
      final bool isCurrentUser =
          widget.userId == null || widget.userId == currentUserId;
      if (_tabController.length != (isCurrentUser ? 3 : 1)) {
        _tabController.dispose();
        _tabController = TabController(
          length: isCurrentUser ? 3 : 1,
          vsync: this,
        );
      }
    } catch (e) {
      print("Error initializing user data: $e");
      if (mounted) {
        setState(() {
          error = "Failed to load profile";
          isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    try {
      await _initializeUserData();
      _refreshController.refreshCompleted();
    } catch (e) {
      print("Error refreshing data: $e");
      _refreshController.refreshFailed();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser =
        widget.userId == null || widget.userId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (isCurrentUser)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                _openMenuDrawer();
              },
            ),
        ],
      ),
      body: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text(error!))
                : Column(
                    children: [
                      _buildProfileHeader(),
                      TabBar(
                        controller: _tabController,
                        tabs: isCurrentUser
                            ? const [
                                Tab(text: 'Posts'),
                                Tab(text: 'Collects'),
                                Tab(text: 'Likes'),
                              ]
                            : const [
                                Tab(text: 'Posts'),
                              ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: isCurrentUser
                              ? [
                                  _buildPostGrid(getUserPosts()),
                                  _buildPostGrid(getSavedPosts()),
                                  _buildPostGrid(getLikedPosts()),
                                ]
                              : [
                                  _buildPostGrid(getUserPosts()),
                                ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

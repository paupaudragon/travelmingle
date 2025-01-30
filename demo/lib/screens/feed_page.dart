import 'package:demo/screens/map_page.dart';
import 'package:demo/screens/post_page.dart';
import 'package:demo/screens/profile_page.dart';
import 'package:demo/screens/search_page.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../services/api_service.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import 'create_post.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final RefreshController _refreshController = RefreshController();
  List<Post> posts = [];
  bool isLoading = true;
  bool isLoggedIn = false;

  //Category and period filter
  List<String> selectedTravelTypes = [];
  List<String> selectedPeriods = [];
  final List<String> travelTypes = [
    'Adventure',
    'Hiking',
    'Skiing',
    'Road Trip',
    'Food Tour',
    'Others',
  ];
  final List<String> periods = ['One Day', 'Multiple Day'];

//Manage state section
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
    _refreshController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPosts();
    }
  }

//Load, refesh, fetch posts section
  Future<void> _onRefresh() async {
    try {
      final fetchedPosts = await _apiService.fetchPosts();

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

  Future<void> _fetchPosts() async {
    if (!mounted) return;

    try {
      setState(() {
        isLoading = true;
      });
      // Ensure filters are properly formatted
      final travelFilters =
          selectedTravelTypes.map((type) => type.toLowerCase()).toList();
      final periodFilters = selectedPeriods
          .map((period) => period.toLowerCase().replaceAll(' ', ''))
          .toList();

      print(
          'Fetching posts with filters - Travel Types: $travelFilters, Periods: $periodFilters'); // Debug print

      // Fetch posts from the API
      final fetchedPosts = await _apiService.fetchPosts(
        travelTypes: travelFilters.isNotEmpty ? travelFilters : null,
        periods: periodFilters.isNotEmpty ? periodFilters : null,
      );

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

//Interaction section
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

//Navigation section
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
    ).then((_) => _onRefresh());
  }

  Future<void> navigateToCreatePost() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreatePostPage()),
    ).then((_) => _onRefresh());
  }

  void navigateToProfilePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    ).then((_) => _loadPosts());
  }

  void navigateToMapPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapTestScreen()),
    ).then((_) => _loadPosts());
  }

  void navigateToSearchPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    ).then((_) => _loadPosts());
  }

//Login section
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

//Create UI section
  void _showMultiSectionFilterDialog() {
    List<String> tempTravelTypes = List.from(selectedTravelTypes);
    List<String> tempPeriods = List.from(selectedPeriods);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Filter Posts"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Type of Traveling"),
                    ...travelTypes.map((type) {
                      final isSelected =
                          tempTravelTypes.contains(type.toLowerCase());

                      return CheckboxListTile(
                        title: Text(type),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              tempTravelTypes.add(type.toLowerCase());
                            } else {
                              tempTravelTypes.remove(type.toLowerCase());
                            }
                          });
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 20),
                    const Text("Period"),
                    ...periods.map((period) {
                      final isSelected =
                          tempPeriods.contains(period.toLowerCase());

                      return CheckboxListTile(
                        title: Text(period),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              tempPeriods.add(period.toLowerCase());
                            } else {
                              tempPeriods.remove(period.toLowerCase());
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  selectedTravelTypes = tempTravelTypes;
                  selectedPeriods = tempPeriods;
                });
                print('Selected Travel Types: $selectedTravelTypes'); // Debug
                print('Selected Periods: $selectedPeriods'); // Debug
                Navigator.pop(context);
                _fetchPosts(); // Refresh posts with the selected filters
              },
              child: const Text("Apply"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Header (Tabs)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Header(
          onFollowPressed: () => requireLogin(context),
          onExplorePressed: () => requireLogin(context),
          onNearbyPressed: () => requireLogin(context),
          onMenuPressed: () => requireLogin(context),
          onSearchPressed: () {
            requireLogin(context, onSuccess: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            });
          },
          onCreateUserPressed: () {
            Navigator.pushNamed(context, '/register');
          },
          onFilterPressed: (){_showMultiSectionFilterDialog();},
        ),
      ),
      //Row for Filter button
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : posts.isEmpty
                    ? const Center(child: Text("No posts available."))
                    : SmartRefresher(
                        controller: _refreshController,
                        onRefresh: _onRefresh,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: MasonryGridView.count(
                          crossAxisCount: 2,  // Number of columns
                          mainAxisSpacing: 4.0,   // Vertical space between items
                          crossAxisSpacing: 4.0,  // Horizontal space between items
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

                        ),
                      ),
          ),
        ],
      ),

      //Footer (Navigation Bar)
      bottomNavigationBar: Footer(
        onHomePressed: _loadPosts,
        onSearchPressed: () {
          navigateToSearchPage();
        },
        onPlusPressed: () {
          navigateToCreatePost();
        },
        onMessagesPressed: () {
          _loadPosts(); // TO-DO
        },
        onMePressed: () {
          navigateToProfilePage();
        },
        onMapPressed: () => requireLogin(context, onSuccess: () {
          Navigator.pushNamed(context, '/map');
        }),
      ),
    );
  }

  Future<void> _navigateToCreatePost() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreatePostPage()),
    ).then((_) => _onRefresh());
  }
}

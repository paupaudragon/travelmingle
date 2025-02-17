import 'dart:async';

import 'package:demo/main.dart';
import 'package:demo/screens/map_page.dart';
import 'package:demo/screens/message_page.dart';
import 'package:demo/screens/nearby_page.dart';
import 'package:demo/screens/post_page.dart';
import 'package:demo/screens/profile_page.dart';
import 'package:demo/screens/search_page.dart';
import 'package:demo/services/notification_service.dart';
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
  double _radius = 10.0; // this is where the range is
  Timer? _refreshTimer;
  final NotificationService _notificationService = NotificationService();

  String source = "explore";
  List<String> travelFilters = [];
  List<String> periodFilters = [];

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
    _loadPosts("explore");
    // _startPollingNotifications;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    NotificationService()
        .fetchNotifications(); // ✅ Replaces checkUnreadNotifications()
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPosts(source);
    }
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

  Future<void> _loadPosts(String source) async {
    if (!mounted) return;

    try {
      setState(() {
        isLoading = true;
      });

      this.source = source;

      // Store filters properly
      travelFilters =
          selectedTravelTypes.map((type) => type.toLowerCase()).toList();
      periodFilters = selectedPeriods
          .map((period) => period.toLowerCase().replaceAll(' ', ''))
          .toList();

      List<Post> fetchedPosts = [];

      if (source == "nearby") {
        // Get user's current location
        final position = await _apiService.getCurrentLocation();

        // Fetch nearby posts
        fetchedPosts = await _apiService.fetchPostsBySource(
          source: "nearby",
          latitude: position.latitude,
          longitude: position.longitude,
          radius: _radius,
          travelTypes: travelFilters.isNotEmpty ? travelFilters : null,
          periods: periodFilters.isNotEmpty ? periodFilters : null,
        );
      } else {
        // Fetch other types (explore, follow)
        fetchedPosts = await _apiService.fetchPostsBySource(
          source: source,
          travelTypes: travelFilters.isNotEmpty ? travelFilters : null,
          periods: periodFilters.isNotEmpty ? periodFilters : null,
        );
      }

      // Update UI once posts are fetched

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

  // Future<void> _loadNearbyPosts() async {
  //   if (!mounted) return;

  //   try {
  //     // Start loading animation
  //     setState(() => isLoading = true);

  //     // Get location asynchronously
  //     final position = await _apiService.getCurrentLocation();

  //     source = "nearby";

  //     // Begin fetching nearby posts after location retrieval
  //     final fetchedPosts = await _apiService.fetchPostsBySource(
  //       source: source,
  //       latitude: position.latitude,
  //       longitude: position.longitude,
  //       radius: _radius,
  //     );

  //     // Update UI once posts are fetched
  //     if (!mounted) return;
  //     setState(() {
  //       posts = fetchedPosts;
  //       isLoading = false;
  //     });
  //     _refreshController.refreshCompleted();
  //   } catch (e) {
  //     setState(() => isLoading = false);
  //     _refreshController.refreshFailed();
  //     print('Error loading nearby posts: $e');
  //   }
  // }

  Future<void> _filterAndFetchPost() async {
    if (!mounted) return;

    try {
      setState(() {
        isLoading = true;
      });
      // Ensure filters are properly formatted
      travelFilters =
          selectedTravelTypes.map((type) => type.toLowerCase()).toList();
      periodFilters = selectedPeriods
          .map((period) => period.toLowerCase().replaceAll(' ', ''))
          .toList();

      _loadPosts(source);

      print(
          'Fetching posts with filters - Travel Types: $travelFilters, Periods: $periodFilters'); // Debug print
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
  Future<void> navigateToFeedPage() async {
    requireLogin(context, onSuccess: () async {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FeedPage()),
      );
    });
  }

  void navigateToPostDetail(Post post) async {
    requireLogin(context, onSuccess: () async {
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
      ).then((_) => _loadPosts(source));
    });
  }

  Future<void> navigateToCreatePost() async {
    requireLogin(context, onSuccess: () async {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CreatePostPage()),
      ).then((_) => _loadPosts(source));
    });
  }

  void navigateToProfilePage() {
    requireLogin(context, onSuccess: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      ).then((_) => _loadPosts(source));
    });
  }

  void navigateToMessagePage() {
    requireLogin(context, onSuccess: () async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationsScreen(
            onHomePressed: () {
              Navigator.pop(context); // Ensure we return to FeedPage
              setState(() {
                _loadPosts(source); // Refresh FeedPage when returning
              });
            },
            onSearchPressed: navigateToSearchPage,
            onPlusPressed: navigateToCreatePost,
            onMessagesPressed: navigateToMessagePage,
            onMePressed: navigateToProfilePage,
            onMapPressed: navigateToMapPage,
          ),
        ),
      ).then((_) {
        // Ensures feed refreshes when returning
        _loadPosts(source);
      });
    });
  }

  void navigateToMapPage() {
    requireLogin(context, onSuccess: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MapTestScreen()),
      ).then((_) => _loadPosts(source));
    });
  }

  void navigateToSearchPage() {
    requireLogin(context, onSuccess: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SearchPage()),
      ).then((_) => _loadPosts(source));
    });
  }

//Create UI section
  void _showMultiSectionFilterDialog() {
    List<String> tempTravelTypes = List.from(selectedTravelTypes);
    List<String> tempPeriods = List.from(selectedPeriods);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: filterPageColor,
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
                _filterAndFetchPost(); // Refresh posts with the selected filters
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
          onFollowPressed: () => _loadPosts("follow"),
          onExplorePressed: () => _loadPosts("explore"),
          onNearbyPressed: () => _loadPosts("nearby"),
          onSearchPressed: () => navigateToSearchPage(),
          onCreateUserPressed: () {
            Navigator.pushNamed(context, '/register');
          },
          onFilterPressed: () => _showMultiSectionFilterDialog(),
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
                        onRefresh: () => _loadPosts(source),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: MasonryGridView.count(
                            crossAxisCount: 2, // Number of columns
                            mainAxisSpacing:
                                4.0, // Vertical space between items
                            crossAxisSpacing:
                                4.0, // Horizontal space between items
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
        onSearchPressed: () => navigateToSearchPage(),
        onHomePressed: () => _loadPosts("explore"),
        onPlusPressed: () {
          navigateToCreatePost();
        },
        onMessagesPressed: () {
          navigateToMessagePage();
        },
        onMePressed: () {
          navigateToProfilePage();
        },
        onMapPressed: () => requireLogin(context, onSuccess: () {
          Navigator.pushNamed(context, '/map');
        }),
        hasUnreadMessages: NotificationService().notificationState.hasUnread,
      ),
    );
  }
}

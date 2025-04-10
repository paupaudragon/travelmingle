import 'dart:async';

import 'package:demo/main.dart';
import 'package:demo/screens/S3Test.dart';
import 'package:demo/screens/main_navigation_page.dart';
import 'package:demo/screens/map_page.dart';
import 'package:demo/screens/message_page.dart';
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
import 'package:demo/widgets/footer_builder.dart';
import 'package:lottie/lottie.dart';


class FeedPage extends StatefulWidget {
  final bool showFooter;
  const FeedPage({super.key, this.showFooter = true});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final RefreshController _refreshController = RefreshController();
  List<Post> posts = [];
  bool isLoading = true;
  bool isLoggedIn = false;
  final double _radius = 50.0;
  String source = "explore";
  List<String> travelFilters = [];
  List<String> periodFilters = [];

  StreamSubscription? _notificationSubscription;

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

    _setupNotificationService();

    // _initializeNotificationServices();

    // _notificationSubscription =
    //     NotificationService().notificationUpdateStream.listen((hasUnread) {
    //   if (mounted) {
    //     setState(() {
    //       // This will trigger a rebuild when notification state changes
    //     });
    //   }
    // });
  }

  Future<void> _setupNotificationService() async {
    try {
      final userId = await _apiService.getCurrentUserId();
      if (userId != null) {
        await NotificationService().initialize(userId: userId);
        print('✅ NotificationService initialized in FeedPage');

        // ✅ Listen for real-time updates from Firebase
        NotificationService().notificationUpdateStream.listen((hasUnread) {
          if (mounted) {
            setState(() {
              print('🔔 Notification stream updated - hasUnread: $hasUnread');
              // Force rebuild to trigger footer
            });
          }
        });

        await NotificationService().fetchNotifications();
      }
    } catch (e) {
      print("❌ Error initializing notification services: $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    NotificationService().fetchNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _refreshController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPosts(source);

      NotificationService().fetchNotifications();
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
      } else if (source == "follow") {
        // ✅ Fetch followed users' posts
        fetchedPosts = await _apiService.fetchPostsBySource(
          source: "follow",
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
      // await Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) => FeedPage()),
      // );

      final navState =
          context.findAncestorStateOfType<MainNavigationPageState>();
      navState?.setState(() => navState.selectedIndex = 0); // or 1, 2, 3, 4
    });
  }

  void navigateToPostDetail(Post post) async {
    requireLogin(context, onSuccess: () async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostPage(
            postId: post.id,
            showFooter: false,
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
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(builder: (context) => const ProfilePage()),
      // ).then((_) => _loadPosts(source));
      final navState =
          context.findAncestorStateOfType<MainNavigationPageState>();
      navState?.switchTab(4); // For Profile
    });
  }

  void navigateToMessagePage() {
    requireLogin(context, onSuccess: () async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationsScreen(
            onHomePressed: () {
              Navigator.pop(context);
              setState(() {
                _loadPosts(source);
              });
            },
            onSearchPressed: navigateToSearchPage,
            onPlusPressed: navigateToCreatePost,
            onMessagesPressed: () {
              // ✅ Trigger _fetchNotifications() in message_page.dart
              print(
                  "🔄 Navigating to Messages - Ensuring notification refresh...");
              NotificationService().fetchNotifications(); // Update unread state
            },
            onMePressed: navigateToProfilePage,
            onMapPressed: navigateToMapPage,
          ),
        ),
      ).then((_) {
        // ✅ Ensures updates when returning
        print("🔄 Returning to feed page - Fetching notifications...");
        NotificationService().fetchNotifications();
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
                // ? const Center(child: CircularProgressIndicator())
                ? Center(
                    child: Lottie.asset(
                      'assets/animations/feed_loading.json',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  )
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

      bottomNavigationBar: widget.showFooter
          ? StreamBuilder<bool>(
              stream: NotificationService().notificationState.hasUnreadStream,
              initialData: NotificationService().notificationState.hasUnread,
              builder: (context, snapshot) {
                final hasUnread = snapshot.data ?? false;
                return buildFooter(context, hasUnread);
              },
            )
          : null,

      floatingActionButton: Builder(
        builder: (context) {
          // Only show in debug mode
          if (const bool.fromEnvironment('dart.vm.product') == false) {
            return FloatingActionButton(
              backgroundColor: Colors.grey[800],
              mini: true,
              child: const Icon(Icons.bug_report),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const S3TestPage()),
                );
              },
            );
          }
          return const SizedBox.shrink(); // Don't show button in release mode
        },
      ),
    );
  }
}

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:demo/main.dart';
import 'package:demo/screens/S3Test.dart';
import 'package:demo/screens/main_navigation_page.dart';
import 'package:demo/screens/map_page.dart';
import 'package:demo/screens/message_page.dart';
import 'package:demo/screens/post_page.dart';
import 'package:demo/screens/search_page.dart';
import 'package:demo/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../widgets/header.dart';
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
  bool hasError = false;
  String errorMessage = '';

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

    setState(() {
      isLoading = true;
      this.source = source;

      // Store filters properly
      travelFilters =
          selectedTravelTypes.map((type) => type.toLowerCase()).toList();
      periodFilters = selectedPeriods
          .map((period) => period.toLowerCase().replaceAll(' ', ''))
          .toList();
    });

    try {
      // Start connectivity check in parallel but don't wait for it immediately
      final connectivityFuture = Connectivity().checkConnectivity();

      // Prepare parameters for API call
      List<Post> fetchedPosts = [];
      Position? position;

      // Only get location if we need it (nearby source)
      if (source == "nearby") {
        try {
          position = await _apiService
              .getCurrentLocation(timeout: const Duration(seconds: 8))
              .timeout(const Duration(seconds: 10), onTimeout: () {
            print(
                'Location request is taking too long, using cached location if available');
            throw TimeoutException('Location timed out');
          });
        } catch (e) {
          print('Location error: $e');

          // Try to use cached location even if there's an error
          final cachedLocation = await _apiService.getCachedLocation();
          if (cachedLocation != null) {
            // Instead of creating a Position object, directly use the LatLng
            // for posts fetching
            fetchedPosts = await _apiService.fetchPostsBySource(
              source: "nearby",
              latitude: cachedLocation.latitude,
              longitude: cachedLocation.longitude,
              radius: _radius,
              travelTypes: travelFilters.isNotEmpty ? travelFilters : null,
              periods: periodFilters.isNotEmpty ? periodFilters : null,
              timeout: const Duration(seconds: 10),
            );

            // Show message to user
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Using cached location due to location service issues'),
                duration: Duration(seconds: 2),
              ),
            );

            // Skip the normal fetch logic that uses position
            if (!mounted) return;
            setState(() {
              posts = fetchedPosts;
              isLoading = false;
              hasError = false;
            });
            return; // Exit the method to avoid duplicate fetching
          }
        }
      }

      // Now check connectivity result
      final connectivityResult = await connectivityFuture;
      if (connectivityResult == ConnectivityResult.none) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          posts = [];
          hasError = true;
          errorMessage =
              'No internet connection. Please check your network settings and try again.';
        });
        return;
      }

      // Fetch posts based on source
      if (source == "nearby") {
        // If we couldn't get location, show appropriate error
        if (position == null) {
          if (!mounted) return;
          setState(() {
            isLoading = false;
            posts = [];
            hasError = true;
            errorMessage =
                'Unable to determine your location. Please check your location settings and try again.';
          });
          return;
        }

        // Fetch nearby posts with location
        fetchedPosts = await _apiService.fetchPostsBySource(
          source: "nearby",
          latitude: position.latitude,
          longitude: position.longitude,
          radius: _radius,
          travelTypes: travelFilters.isNotEmpty ? travelFilters : null,
          periods: periodFilters.isNotEmpty ? periodFilters : null,
          // Shorter timeout for nearby results
          timeout: const Duration(seconds: 10),
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
        hasError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Unable to load posts. Please try again.';
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

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.signal_wifi_off,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadPosts(source),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorLiked,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(String currentSource) {
    String message;
    IconData icon;

    switch (currentSource) {
      case "follow":
        message =
            "You don't have any posts from people you follow yet. Start following some users!";
        icon = Icons.people_outline;
        break;
      case "nearby":
        message = "No posts found in your area.";
        icon = Icons.location_off;
        break;
      default:
        message = "No posts available at the moment.";
        icon = Icons.post_add;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            if (currentSource == "follow")
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: ElevatedButton(
                  onPressed: () => navigateToSearchPage(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorLiked,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text('Find Users to Follow'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showTimeoutError(String message) {
    if (!mounted) return;

    setState(() {
      hasError = true;
      errorMessage = message;
    });

    // Also show a SnackBar for immediate feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 15),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _loadPosts(source),
        ),
      ),
    );
  }

  void _showGeneralError(String message) {
    if (!mounted) return;

    setState(() {
      hasError = true;
      errorMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 15),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () => _loadPosts(source),
        ),
      ),
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
                : hasError
                    ? _buildErrorView(errorMessage)
                    : posts.isEmpty
                        ? _buildEmptyView(source)
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

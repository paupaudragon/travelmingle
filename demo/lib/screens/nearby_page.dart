// import 'package:flutter/material.dart';
// import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
// import 'package:pull_to_refresh/pull_to_refresh.dart';
// import '../widgets/header.dart';
// import '../widgets/footer.dart';
// import '../services/api_service.dart';
// import '../models/post_model.dart';
// import '../widgets/post_card.dart';
// import 'post_page.dart';

// class NearbyPage extends StatefulWidget {
//   const NearbyPage({super.key});

//   @override
//   State<NearbyPage> createState() => _NearbyPageState();
// }

// class _NearbyPageState extends State<NearbyPage> {
//   final ApiService _apiService = ApiService();
//   final RefreshController _refreshController = RefreshController();
//   List<Post> posts = [];
//   bool isLoading = true;
//   double _radius = 10.0; // this is where the range is

//   @override
//   void initState() {
//     super.initState();
//     _loadNearbyPosts();
//   }

//   Future<void> _loadNearbyPosts() async {
//     if (!mounted) return;

//     try {
//       // Start loading animation
//       setState(() => isLoading = true);

//       // Get location asynchronously
//       final position = await _apiService.getCurrentLocation();

//       // Begin fetching nearby posts after location retrieval
//       final fetchedPosts = await _apiService.fetchNearbyPosts(
//         latitude: position.latitude,
//         longitude: position.longitude,
//         radius: _radius,
//       );

//       // Update UI once posts are fetched
//       if (!mounted) return;
//       setState(() {
//         posts = fetchedPosts;
//         isLoading = false;
//       });
//       _refreshController.refreshCompleted();
//     } catch (e) {
//       setState(() => isLoading = false);
//       _refreshController.refreshFailed();
//       print('Error loading nearby posts: $e');
//     }
//   }

//   void navigateToPostDetail(Post post) async {
//     await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => PostPage(
//           postId: post.id,
//           onPostUpdated: (updatedPost) {
//             if (!mounted) return;
//             setState(() {
//               final index = posts.indexWhere((p) => p.id == updatedPost.id);
//               if (index != -1) {
//                 posts[index] = updatedPost;
//               }
//             });
//           },
//         ),
//       ),
//     ).then((_) => _loadNearbyPosts());
//   }

//   void toggleLike(Post post) async {
//     try {
//       final result = await _apiService.updatePostLikes(post.id);
//       if (!mounted) return;
//       setState(() {
//         post.isLiked = result['is_liked'];
//         post.likesCount = result['likes_count'];
//       });
//     } catch (e) {
//       print("Error toggling like: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // Top header
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(60),
//         child: Header(
//           onFollowPressed: () => Navigator.pop(context), // Go back to feed
//           onExplorePressed: () {}, // Add explore callback if needed
//           onNearbyPressed: () {}, // No-op since this is the active page
//           onMenuPressed: () {}, // Add menu callback if needed
//           onSearchPressed: () {}, // Add search callback if needed
//           onCreateUserPressed: () {}, // Add create user callback if needed
//           onFilterPressed: () {}, // Add filter callback if needed
//         ),
//       ),

//       // Main content
//       body: Column(
//         children: [
//           Expanded(
//             child: isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : posts.isEmpty
//                     ? const Center(child: Text("No posts available nearby"))
//                     : SmartRefresher(
//                         controller: _refreshController,
//                         onRefresh: _loadNearbyPosts,
//                         child: Padding(
//                           padding: const EdgeInsets.all(4.0),
//                           child: MasonryGridView.count(
//                             crossAxisCount: 2,
//                             mainAxisSpacing: 4.0,
//                             crossAxisSpacing: 4.0,
//                             itemCount: posts.length,
//                             itemBuilder: (context, index) {
//                               final post = posts[index];
//                               return GestureDetector(
//                                 onTap: () => navigateToPostDetail(post),
//                                 child: PostCard(
//                                   post: post,
//                                   onLikePressed: () => toggleLike(post),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
//                       ),
//           ),
//         ],
//       ),

//       // Bottom navigation bar
//       bottomNavigationBar: Footer(
//         onHomePressed: () => Navigator.pop(context), // Go back to feed
//         onPlusPressed: () {}, // Add create post callback if needed
//         onMessagesPressed: () {}, // Add messages callback if needed
//         onMePressed: () {}, // Add profile callback if needed
//         onMapPressed: () {}, // Add map callback if needed
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _refreshController.dispose();
//     super.dispose();
//   }
// }

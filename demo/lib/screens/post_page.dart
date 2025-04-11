import 'dart:io';
import 'package:demo/main.dart';
import 'package:demo/screens/location_posts_page.dart';
import 'package:demo/screens/profile_page.dart';
import 'package:demo/widgets/loading_animation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class PostPage extends StatefulWidget {
  final int postId;
  final void Function(Post updatedPost)? onPostUpdated;
  final bool showFooter; // ✅ New flag

  const PostPage({
    super.key,
    required this.postId,
    this.onPostUpdated,
    this.showFooter = true,
  });

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  bool _isCommentsVisible = false;
  bool _isCommentInputVisible = false;
  final FocusNode _commentFocusNode = FocusNode();
  final TextEditingController _commentController = TextEditingController();
  late Future<Post> postFuture;
  late Future<List<Comment>> commentsFuture;
  final ApiService apiService = ApiService();
  List<Comment>? commentsCache;
  final Map<int, bool> expandedComments = {};
  int? activeReplyToCommentId;
  String? replyingToUsername;
  File? _commentImage;
  final PageController _pageController = PageController();
  int _currentDayIndex = 0;

  @override
  void initState() {
    super.initState();
    postFuture = fetchPostDetail();
    commentsFuture = fetchComments().then((comments) {
      commentsCache = comments;
      return comments;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _goToPreviousDay() {
    if (_currentDayIndex > 0) {
      setState(() {
        _currentDayIndex--;
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _goToNextDay(int totalDays) {
    if (_currentDayIndex < totalDays - 1) {
      setState(() {
        _currentDayIndex++;
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Future<void> _pickCommentImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _commentImage = File(pickedFile.path);
      });
    }
  }

  void _removeCommentImage() {
    setState(() {
      _commentImage = null;
    });
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.month}-${date.day}';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<Post> fetchPostDetail() async {
    return await apiService.fetchPostDetail(widget.postId);
  }

  Future<List<Comment>> fetchComments() async {
    return await apiService.fetchComments(widget.postId);
  }

  void togglePostLike(Post post) async {
    try {
      final response = await apiService.updatePostLikes(post.id);
      setState(() {
        post.isLiked = response['is_liked'];
        post.likesCount = response['likes_count'];
      });
      if (widget.onPostUpdated != null) {
        widget.onPostUpdated!(post); // Notify FeedPage of the updated post
      }
    } catch (e) {
      print("Error toggling post like: $e");
    }
  }

  void togglePostSave(Post post) async {
    try {
      final response = await apiService.updatePostSaves(post.id);
      print("Response from API: $response"); // Log the response for debugging
      setState(() {
        post.isSaved = response['is_saved'];
        post.savesCount = response['saves_count'];
      });
      if (widget.onPostUpdated != null) {
        widget.onPostUpdated!(post); // Notify FeedPage of the updated post
      }
    } catch (e) {
      print("Error toggling post save: $e");
    }
  }

  void toggleCommentLike(Comment comment) async {
    try {
      final response = await apiService.updateCommentLikes(comment.id);

      setState(() {
        comment.isLiked = response['is_liked'];
        comment.likesCount = response['likes_count'];
      });
    } catch (e) {
      print("Error toggling comment like: $e");
    }
  }

  void toggleExpand(int commentId) {
    setState(() {
      expandedComments[commentId] = !(expandedComments[commentId] ?? false);
    });
  }

  void activateReplyTo(int commentId, String username) {
    setState(() {
      activeReplyToCommentId = commentId;
      replyingToUsername = username;
      _isCommentInputVisible = true;
    });
    _commentFocusNode.requestFocus();
  }

  void cancelReply() {
    setState(() {
      activeReplyToCommentId = null;
      replyingToUsername = null;
      _isCommentInputVisible = false;
    });
  }

  Comment? findTopLevelComment(List<Comment> comments, int commentId) {
    for (var comment in comments) {
      if (comment.id == commentId) {
        // If the comment is a top-level comment (replyTo is null), return it
        if (comment.replyTo == null) {
          return comment;
        } else {
          // Otherwise, recursively find the top-level comment
          return findTopLevelComment(comments, comment.replyTo!);
        }
      }
      // If not found, search in its replies
      final foundInReplies = findTopLevelComment(comment.replies, commentId);
      if (foundInReplies != null) {
        return foundInReplies;
      }
    }
    return null; // Not found
  }

  void resetCommentInput() {
    setState(() {
      _commentController.clear(); // Clear the text input
      _removeCommentImage(); // Clear the selected image
      activeReplyToCommentId = null; // Clear reply-to state
      replyingToUsername = null; // Clear the replying username
    });
  }

  String formatNumber(int number) {
    if (number < 1000) {
      return number.toString();
    } else if (number < 1000000) {
      double result = number / 1000;
      return "${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)}K"; // 1.1K
    } else {
      double result = number / 1000000;
      return "${result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 1)}M"; // 1.1M
    }
  }

  Future<void> addComment(int postId) async {
    final commentContent = _commentController.text.trim();
    if (commentContent.isEmpty && _commentImage == null) return;

    // Disable the comment button to prevent multiple submissions
    // setState(() {
    //   isAddingComment = true;
    // });

    try {
      final newComment = await apiService.addComment(
        postId: postId,
        content: commentContent,
        replyTo: activeReplyToCommentId, // Pass replyTo for nested replies
        imagePath: _commentImage?.path, // Pass the selected image's path
      );

      // Reset the input fields after a successful comment
      resetCommentInput();

      // Refresh comments
      setState(() {
        commentsCache = commentsCache ?? [];
        commentsCache!.insert(0, newComment); // Add the new comment at the top
      });

      // Refresh the comments from the server in the background
      commentsFuture = fetchComments();
      commentsFuture.then((comments) {
        setState(() {
          commentsCache = comments;
        });
      });
    } catch (e) {
      print("Error adding comment: $e");
    }
  }

  Future<void> _handleFollowPress(int userId) async {
    try {
      print("Attempting to follow user: $userId"); // Debug print
      final response = await apiService.followUser(userId);
      print("Follow response: $response"); // Debug print

      setState(() {
        postFuture = postFuture.then((post) {
          post.user.isFollowing = response['is_following'];
          return post;
        });
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              response['is_following'] ? 'Following user' : 'Unfollowed user'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Follow error in handler: $e"); // Debug print
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to update follow status: $e'), // Added error message
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildPostHeader(Future<Post> postFuture) {
    return FutureBuilder<Post>(
      future: postFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Text("Post Details");
        final post = snapshot.data!;

        return FutureBuilder<Map<String, dynamic>?>(
          future: apiService.getUserInfo(),
          builder: (context, userSnapshot) {
            final isCurrentUser = userSnapshot.hasData &&
                userSnapshot.data!['id'] == post.user.id;

            return Row(
              children: [
                if (post.period != 'multipleday') ...[
                  // Make avatar and username clickable
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(
                              userId: isCurrentUser ? null : post.user.id,
                              showFooter: false,
                              isFromPage: true,
                            ),
                          ),
                        );
                      },
                      // # MARK 1
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage:
                                NetworkImage(post.user.profilePictureUrl),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.user.username,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Only show follow button for other users
                  if (!isCurrentUser && userSnapshot.hasData)
                    SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        onPressed: post.user.isFollowing
                            ? null
                            : () => _handleFollowPress(post.user.id),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: post.user.isFollowing
                              ? Colors.grey[200]
                              : primaryColor,
                          side: BorderSide(
                            color: post.user.isFollowing
                                ? Colors.grey
                                : primaryColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: Text(
                          post.user.isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                              color: post.user.isFollowing
                                  ? Colors.grey[700]
                                  : whiteColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ] else ...[
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed:
                              _currentDayIndex > 0 ? _goToPreviousDay : null,
                        ),
                        Text(
                          'Day ${_currentDayIndex + 1}/${post.childPosts!.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed:
                              _currentDayIndex < post.childPosts!.length - 1
                                  ? () => _goToNextDay(post.childPosts!.length)
                                  : null,
                        ),
                      ],
                    ),
                  ),
                ]
              ],
            );
          },
        );
      },
    );
  }

// # button bar
  Widget buildPostActions(Post post) {
    return Container(
      color: whiteColor,
      child: SafeArea(
        // not cover system gesture area
        bottom: true,
        child: Column(
          children: [
            const Divider(
              height: 1,
              thickness: 0.2,
              color: Colors.grey,
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12), // l，up，r，d
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Comment button
                  GestureDetector(
                    onTap: () => {
                      setState(() {
                        _isCommentsVisible =
                            !_isCommentsVisible; // Toggle comment section visibility
                        _isCommentInputVisible = false; // Reset input box state
                      }),
                    },
                    child: Column(children: [
                      SvgPicture.asset(
                          _isCommentsVisible
                              ? 'assets/icons/comment_filled.svg'
                              : 'assets/icons/comment.svg',
                          width: 32,
                          height: 32,
                          colorFilter:
                              ColorFilter.mode(iconColor, BlendMode.dst))
                    ]),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatNumber(commentsCache?.length ?? 0),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w400),
                  ),

                  const SizedBox(width: 10),

                  // Like button
                  GestureDetector(
                    onTap: () => togglePostLike(post),
                    child: Column(children: [
                      SvgPicture.asset(
                          post.isLiked
                              ? 'assets/icons/heart_filled.svg'
                              : 'assets/icons/heart.svg',
                          width: 32,
                          height: 32,
                          colorFilter: ColorFilter.mode(
                              post.isLiked ? colorLiked : iconColor,
                              BlendMode.srcIn))
                    ]),
                  ),
                  const SizedBox(width: 6),

                  Text(
                    formatNumber(post.likesCount),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w400),
                  ),

                  const SizedBox(width: 10),

                  // Save button
                  GestureDetector(
                    onTap: () => togglePostSave(post),
                    child: Column(children: [
                      SvgPicture.asset(
                          post.isSaved
                              ? 'assets/icons/star_filled.svg'
                              : 'assets/icons/star.svg',
                          width: 32,
                          height: 32,
                          colorFilter: ColorFilter.mode(
                              post.isSaved ? colorLiked : iconColor,
                              BlendMode.srcIn))
                    ]),
                  ),
                  const SizedBox(width: 6),

                  Text(
                    formatNumber(post.savesCount),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w400),
                  ),

                  const SizedBox(width: 6),

                  // Input box
                  if (_isCommentsVisible && !_isCommentInputVisible)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isCommentInputVisible =
                                true; // Show full input box
                          });
                        },
                        child: Container(
                          height: 34, // Custom height
                          margin: const EdgeInsets.only(
                              left: 12), // Keep distance from icon
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10), // Padding
                          decoration: BoxDecoration(
                            color: insertBoxBgColor, // Background color
                            borderRadius:
                                BorderRadius.circular(16), // Rounded corners
                            // border: Border.all(
                            //   color: Colors.black, // Border color
                            //   width: 1, // Border width
                            // ),
                          ),
                          child: Align(
                            alignment: Alignment.center,
                            child: const Text(
                              "Say something...",
                              style: TextStyle(color: insertBoxTextColor),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // # poster's profile and name
                  if (!_isCommentsVisible || _isCommentInputVisible)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfilePage(userId: post.user.id),
                            ),
                          );
                        },
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage:
                                    NetworkImage(post.user.profilePictureUrl),
                              ),
                              const SizedBox(width: 9),
                              Text(
                                post.user.username,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Size> _getImageSize(String imageUrl) async {
    final Completer<Size> completer = Completer();
    final Image image = Image.network(imageUrl);

    image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );

    return completer.future;
  }

  // Define the logic for determining the appropriate `BoxFit` for each image:
  // 1. The first image always uses `BoxFit.cover`.
  // 2. For other images:
  //    - If the image's aspect ratio is similar to the first image's aspect ratio (within a 5% margin of error),
  //      or if both the first image's aspect ratio and the current image's aspect ratio are below the minimum threshold,
  //      or if both the first image's aspect ratio and the current image's aspect ratio are above the maximum threshold,
  //      then use `BoxFit.cover`.
  //    - Otherwise:
  //      - If the current image's aspect ratio is wider than the first image's aspect ratio, use `BoxFit.fitWidth`.
  //      - If the current image's aspect ratio is taller than the first image's aspect ratio, use `BoxFit.fitHeight`.
  // # post each day
  Widget buildSingleDayContent(Post day) {
    final PageController _imageController = PageController();
    // Add a ValueNotifier to track current page
    final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (day.images.isNotEmpty)
            FutureBuilder<Size>(
              future: _getImageSize(day.images[0].imageUrl),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  double firstImageAspectRatio =
                      snapshot.data!.width / snapshot.data!.height;
                  const double minAspectRatio = 5 / 7;
                  const double maxAspectRatio = 4 / 3;
                  double clampedAspectRatio = firstImageAspectRatio.clamp(
                      minAspectRatio, maxAspectRatio);

                  return Column(
                    children: [
                      AspectRatio(
                        aspectRatio: clampedAspectRatio,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(0),
                          child: PageView.builder(
                            controller: _imageController,
                            itemCount: day.images.length,
                            onPageChanged: (index) {
                              _currentPageNotifier.value = index;
                            },
                            itemBuilder: (context, index) {
                              return FutureBuilder<Size>(
                                future:
                                    _getImageSize(day.images[index].imageUrl),
                                builder: (context, sizeSnapshot) {
                                  if (sizeSnapshot.connectionState ==
                                          ConnectionState.done &&
                                      sizeSnapshot.hasData) {
                                    double imageAspectRatio =
                                        sizeSnapshot.data!.width /
                                            sizeSnapshot.data!.height;
                                    BoxFit fit;
                                    if (index == 0) {
                                      fit = BoxFit.cover;
                                    } else {
                                      bool isAspectRatioSimilar =
                                          (imageAspectRatio -
                                                      firstImageAspectRatio)
                                                  .abs() <=
                                              firstImageAspectRatio * 0.05;
                                      bool isBothBelowMin =
                                          imageAspectRatio < minAspectRatio &&
                                              firstImageAspectRatio <
                                                  minAspectRatio;
                                      bool isBothAboveMax =
                                          imageAspectRatio > maxAspectRatio &&
                                              firstImageAspectRatio >
                                                  maxAspectRatio;
                                      if (isAspectRatioSimilar ||
                                          isBothBelowMin ||
                                          isBothAboveMax) {
                                        fit = BoxFit.cover;
                                      } else {
                                        fit = imageAspectRatio >
                                                firstImageAspectRatio
                                            ? BoxFit.fitWidth
                                            : BoxFit.fitHeight;
                                      }
                                    }
                                    return Image.network(
                                      day.images[index].imageUrl,
                                      fit: fit,
                                      width: double.infinity,
                                    );
                                  } else {
                                    return const Center(
                                        child: LoadingAnimation());
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      // Add the indicator here
                      if (day.images.length > 1) // Only show if multiple images
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: ValueListenableBuilder<int>(
                            valueListenable: _currentPageNotifier,
                            builder: (context, currentPage, child) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List<Widget>.generate(
                                  day.images.length,
                                  (index) => Container(
                                    width: 8.0,
                                    height: 8.0,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 4.0),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: currentPage == index
                                          ? primaryColor
                                          : Colors.grey.withOpacity(0.4),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  );
                } else {
                  return const LoadingAnimation();
                }
              },
            ),
          // Rest of your content...
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  day.content ?? "No content provided",
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LocationPostsPage(
                            locationName: day.location.name,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Colors.grey,
                          size: 17,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            day.location.name,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMultiDayPost(Post post) {
    if (post.childPosts == null || post.childPosts!.isEmpty) {
      return const Center(
        child: Text("No content available for this multi-day post."),
      );
    }

    return Column(
      children: [
        // The expandable PageView content
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: post.childPosts!.length,
            onPageChanged: (index) {
              setState(() {
                _currentDayIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return buildSingleDayContent(post.childPosts![index]);
            },
          ),
        ),
      ],
    );
  }

  Widget buildPostContent(Post post) {
    if (post.period == 'multipleday') {
      return SizedBox(
        height: MediaQuery.of(context).size.height,
        child: buildMultiDayPost(post),
      );
    } else {
      return buildSingleDayContent(post);
    }
  }

  Widget buildCommentsSection() {
    if (commentsCache != null && commentsCache!.isNotEmpty) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: commentsCache!.length,
        itemBuilder: (context, index) {
          return buildCommentTree(commentsCache![index]);
        },
      );
    }

    return FutureBuilder<List<Comment>>(
      future: commentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: LoadingAnimation(),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text("Error loading comments: ${snapshot.error}"),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text("No comments yet.");
        }

        final comments = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            return buildCommentTree(comments[index]);
          },
        );
      },
    );
  }

  Widget buildCommentTree(Comment comment, {int depth = 0}) {
    // Set the radius based on the depth
    double r = depth == 0 ? 18 : 14; // Main comment: r = 20, Replies: r = 15

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0), // Add space between comments
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Render the main comment
          InkWell(
            onTap: () => activateReplyTo(comment.id, comment.user.username),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Align at the top
              children: [
                // Avatar
                CircleAvatar(
                  radius: r,
                  backgroundImage: NetworkImage(comment.user.profilePictureUrl),
                ),
                const SizedBox(width: 8), // Space between avatar and content
                // Comment content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username
                      Text(
                        comment.user.username,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight:
                              FontWeight.w600, // Makes the text semi-bold
                        ),
                      ),
                      const SizedBox(
                          height: 2), // Small space between username and text
                      // Comment text
                      if (comment.content != null &&
                          comment.content!.isNotEmpty)
                        Text(
                          comment.content!,
                          style: const TextStyle(
                              fontSize: 15, color: Colors.black),
                        ),
                      if (comment.commentPictureUrl != null)
                        const SizedBox(height: 8),
                      if (comment.commentPictureUrl != null)
                        Image.network(
                          comment.commentPictureUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      const SizedBox(
                          height: 2), // Space between text and metadata
                      // Date and Reply Row
                      Row(
                        children: [
                          Text(
                            formatDate(comment.createdAt),
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          // Show "Reply" button only for depth = 0
                          if (depth == 0)
                            GestureDetector(
                              onTap: () => activateReplyTo(
                                  comment.id, comment.user.username),
                              child: const Text(
                                "Reply",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color.fromARGB(255, 120, 120, 120),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Likes and Like Button
                Column(
                  mainAxisAlignment:
                      MainAxisAlignment.start, // Align with the top
                  children: [
                    IconButton(
                      icon: Icon(
                        comment.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: comment.isLiked ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => toggleCommentLike(comment),
                    ),
                    Text(
                      "${comment.likesCount}",
                      style: const TextStyle(fontSize: 10, color: Colors.black),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // If the comment has replies, show "View # replies" button
          if (comment.replies.isNotEmpty && depth == 0)
            Padding(
              padding: const EdgeInsets.only(left: 15.0), // Indent replies
              child: TextButton(
                onPressed: () {
                  toggleExpand(comment.id);
                },
                child: Text(expandedComments[comment.id] == true
                    ? 'Hide replies'
                    : 'View ${comment.replies.length} replies'),
              ),
            ),
          // If replies are expanded, display them
          if (expandedComments[comment.id] == true)
            Padding(
              padding: EdgeInsets.only(
                left: depth == 0 ? 25.0 : 0.0, // Indent only if depth == 1
              ),
              child: Column(
                children: comment.replies
                    .map((reply) => buildCommentTree(reply,
                        depth: depth +
                            1)) // Recursively build replies with increased depth
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildCommentInput() {
    return Container(
        color: whiteColor,
        child: SafeArea(
            bottom: true,
            child: Column(
              children: [
                const Divider(
                  height: 1,
                  thickness: 0.2,
                  color: Colors.grey,
                ),
                Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back button
                        IconButton(
                          icon: const Icon(Icons.arrow_back), // Back icon
                          onPressed: () {
                            setState(() {
                              _isCommentInputVisible =
                                  false; // Return to buildPostActions
                            });
                          },
                        ),
                        // Input box
                        Expanded(
                          child: Container(
                            height:
                                45, // Set the height as per your requirement
                            child: TextField(
                              controller: _commentController,
                              focusNode: _commentFocusNode,
                              decoration: InputDecoration(
                                hintText: activeReplyToCommentId == null
                                    ? "Say something..."
                                    : "Replying...",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFE8E8E8),
                              ),
                            ),
                          ),
                        ),
                        // // Image selection button
                        // GestureDetector(
                        //   onTap: () => _pickCommentImage,
                        //   child: Column(children: [
                        //     SvgPicture.asset(
                        //       'assets/icons/gallery.svg',
                        //       width: 32,
                        //       height: 32,
                        //       colorFilter:                             ColorFilter.mode(iconColor, BlendMode.dst))
                        //   ],)
                        // ),
                        IconButton(
                          icon: const Icon(Icons.photo),
                          onPressed: _pickCommentImage,
                        ),
                        // Send button
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () => addComment(widget.postId),
                        ),
                      ],
                    ))
              ],
            )));
  }

  Widget buildCommentInput1() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          if (activeReplyToCommentId != null)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFD6D6D6),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '@$replyingToUsername',
                      style: TextStyle(color: Colors.grey[900]),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: cancelReply,
                  ),
                ],
              ),
            ),
          // Reply section
          Row(
            children: [
              // Back button
              IconButton(
                icon: const Icon(Icons.arrow_back), // Back icon
                onPressed: () {
                  setState(() {
                    _isCommentInputVisible =
                        false; // Return to buildPostActions
                  });
                },
              ),
              // Input box
              Expanded(
                child: Container(
                  height: 50, // Set the height as per your requirement
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    decoration: InputDecoration(
                      hintText: activeReplyToCommentId == null
                          ? "Say something..."
                          : "Replying...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFE8E8E8),
                    ),
                  ),
                ),
              ),
              // Image selection button
              IconButton(
                icon: const Icon(Icons.photo),
                onPressed: _pickCommentImage,
              ),
              // Send button
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => addComment(widget.postId),
              ),
            ],
          ),
          if (_commentImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Image.file(
                    _commentImage!,
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: _removeCommentImage,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: buildPostHeader(postFuture),
      ),
      body: GestureDetector(
        onTap: () {
          // When the comment section is expanded, clicking outside collapses it
          if (_isCommentsVisible) {
            setState(() {
              _isCommentsVisible = false;
              _isCommentInputVisible = false;
            });
          }
        },
        behavior: HitTestBehavior
            .opaque, // Ensure clicking on empty space triggers the event
        child: FutureBuilder<Post>(
          future: postFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: LoadingAnimation());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData) {
              return const Center(child: Text("Post not found"));
            }

            final post = snapshot.data!;

            return Column(
              children: [
                // ✅ Post Content with Dynamic Height
                Expanded(
                  flex: 1, // Post content always takes up 1 part of the space
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // ✅ Post Content without Fixed Height
                        buildPostContent(post),

                        // ✅ Divider
                        const Divider(),
                      ],
                    ),
                  ),
                ),

                // ✅ Comment Section (Scrollable)
                if (_isCommentsVisible) // Only show comment section when expanded
                  Expanded(
                    flex:
                        9, // Comment section takes up 9 parts of the space (90%)
                    child: GestureDetector(
                      onTap: () {
                        // Clicking inside the comment section does not collapse it
                        // Prevent event from bubbling up
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(
                                0), // Top rounded corners: can't make it transparent
                          ),
                          // boxShadow: [
                          //   BoxShadow(
                          //     color:
                          //         Colors.black.withOpacity(0.3), // Shadow color
                          //     blurRadius: 8, // Shadow blur radius
                          //     offset: const Offset(0, -2), // Shadow offset
                          //   ),
                          // ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 16),
                          child: buildCommentsSection(),
                        ),
                      ),
                    ),
                  ),

                // ✅ Post Actions (Like, Save) at the Bottom
                if (!_isCommentInputVisible) buildPostActions(post),

                // ✅ Comment Input Always Stays at the Bottom
                if (_isCommentInputVisible) buildCommentInput(),
              ],
            );
          },
        ),
      ),
    );
  }
}

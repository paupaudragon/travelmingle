import 'package:flutter/material.dart';
import '../widgets/header.dart'; // Import Header
import '../widgets/footer.dart'; // Import Footer
import '../services/api_service.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<Post> posts = [];
  List<Post> filteredPosts = [];
  bool isLoading = true;
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    final apiService = ApiService();
    final fetchedPosts = await apiService.fetchPosts();

    print('Fetched Posts: ${fetchedPosts.length}');
    setState(() {
      posts = fetchedPosts;
      isLoading = false;
    });
  }

  void searchPosts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredPosts = posts;
        isSearching = false;
      } else {
        isSearching = true;
        filteredPosts = posts.where((post) {
          return post.title.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60), // Header height
        child: Header(
          onFollowPressed: () {
            print("Follow button pressed");
          },
          onExplorePressed: () {
            print("Explore button pressed");
          },
          onNearbyPressed: () {
            print("Nearby button pressed");
          },
          onMenuPressed: () {
            print("Menu button pressed");
          },
          onSearchPressed: () {
              showSearch(
              context: context,
              delegate: PostSearchDelegate(posts: posts, onSearch: searchPosts),
            );
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(8.0), // Padding around the entire grid
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two columns
                // crossAxisSpacing: 2, // Reduced horizontal spacing between items
                // mainAxisSpacing: 2, // Reduced vertical spacing between items
                childAspectRatio: 0.7, // Adjusted to show two rows on screen
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];

                print('Rendering Post: ${post.title}');

                return PostCard(post: post); // Use PostCard for individual items
              },
            ),
      bottomNavigationBar: Footer(
        onHomePressed: () {
          print("Home button pressed");
        },
        onShopPressed: () {
          print("Shop button pressed");
        },
        onPlusPressed: () {
          print("+ button pressed");
        },
        onMessagesPressed: () {
          print("Messages button pressed");
        },
        onMePressed: () {
          print("Me button pressed");
        },
      ),
    );
  }
}

class PostSearchDelegate extends SearchDelegate<Post?> {
  final List<Post> posts;
  final Function(String) onSearch;

  PostSearchDelegate({required this.posts, required this.onSearch});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          onSearch('');
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
        onSearch('');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    return Container(); // Results will be shown in the main grid
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? []
        : posts.where((post) {
            return post.title.toLowerCase().contains(query.toLowerCase());
          }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final post = suggestions[index];
        return ListTile(
          title: Text(post.title),
          subtitle: Text(post.description),
          onTap: () {
            query = post.title;
            onSearch(query);
            close(context, post);
          },
        );
      },
    );
  }
}
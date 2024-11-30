import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../screens/profile_page.dart'; // Add this import

class UserListItem extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const UserListItem({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage: user.profilePictureUrl != null
            ? NetworkImage('${user.profilePictureUrl}')
            : null,
        child: user.profilePictureUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(user.username),
      subtitle: user.bio.isNotEmpty
          ? Text(
              user.bio!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
    );
  }
}

class FollowListPage extends StatefulWidget {
  final int userId;
  final int initialTabIndex;

  const FollowListPage({
    super.key,
    required this.userId,
    required this.initialTabIndex,
  });

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  List<User> following = [];
  List<User> followers = [];
  bool isLoading = true;
  String? username; // Variable to store the username

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final userInfo = await _apiService.getUserProfileById(widget.userId);
      if (userInfo == null) {
        throw Exception('User info is null');
      }
      final data = await _apiService.fetchFollowData(widget.userId);
      setState(() {
        username =
            userInfo['username'] as String?; // Safely access the username
        following = data['following'] ?? [];
        followers = data['followers'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      print('Error loading follow data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void navigateToProfile(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          username ?? 'Follows',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ), // Display username or fallback
        centerTitle: true, // Center the title
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Text(
                'Following (${following.length})',
                style: const TextStyle(color: Colors.blue), // Blue text
              ),
            ),
            Tab(
              child: Text(
                'Followers (${followers.length})',
                style: const TextStyle(color: Colors.blue), // Blue text
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Following tab
                following.isEmpty
                    ? const Center(child: Text('Not following anyone'))
                    : ListView.builder(
                        itemCount: following.length,
                        itemBuilder: (context, index) {
                          final user = following[index];
                          return UserListItem(
                            user: user,
                            onTap: () => navigateToProfile(user.id),
                          );
                        },
                      ),
                // Followers tab
                followers.isEmpty
                    ? const Center(child: Text('No followers yet'))
                    : ListView.builder(
                        itemCount: followers.length,
                        itemBuilder: (context, index) {
                          final user = followers[index];
                          return UserListItem(
                            user: user,
                            onTap: () => navigateToProfile(user.id),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}

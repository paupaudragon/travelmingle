import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';

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
      final data = await _apiService.fetchFollowData(widget.userId);
      setState(() {
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
    Navigator.pushNamed(
      context,
      '/profile',
      arguments: userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Followers & Following'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Following (${following.length})'),
            Tab(text: 'Followers (${followers.length})'),
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

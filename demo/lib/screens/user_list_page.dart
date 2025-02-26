import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'profile_page.dart';
import 'package:demo/models/user_model.dart' as app_models;

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
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  List<User> following = [];
  List<User> followers = [];
  bool isLoading = true;
  String? username;

  final RefreshController _refreshController = RefreshController();

  @override
  bool get wantKeepAlive => true;

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
    _refreshController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _loadData();
    _refreshController.refreshCompleted();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      setState(() => isLoading = true);

      final userInfo = await _apiService.getUserProfileById(widget.userId);
      if (userInfo == null) throw Exception('User info is null');

      final data = await _apiService.fetchFollowData(widget.userId);

      if (!mounted) return;

      setState(() {
        username = userInfo['username'] as String?;
        following = (data['following'] as List<dynamic>?)
                ?.map((user) =>
                    app_models.User.fromJson(user as Map<String, dynamic>))
                .toList() ??
            [];

        followers = (data['followers'] as List<dynamic>?)
                ?.map((user) =>
                    app_models.User.fromJson(user as Map<String, dynamic>))
                .toList() ??
            [];
        isLoading = false;
      });
    } catch (e) {
      print('Error loading follow data: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void navigateToProfile(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: userId),
      ),
    ).then((_) {
      // Refresh the data when returning from the profile page
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          username ?? 'Follows',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Text(
                'Following (${following.length})',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
            Tab(
              child: Text(
                'Followers (${followers.length})',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SmartRefresher(
              controller: _refreshController,
              onRefresh: _onRefresh,
              child: TabBarView(
                controller: _tabController,
                children: [
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
            ),
    );
  }
}

import 'dart:async';
import 'package:demo/enums/notification_types.dart';
import 'package:demo/models/message_category.dart';
import 'package:demo/screens/message_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:demo/services/api_service.dart';
import 'package:demo/services/notification_service.dart';
import '../widgets/footer.dart';
import 'dart:convert';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onHomePressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onPlusPressed;
  final VoidCallback? onMessagesPressed;
  final VoidCallback? onMePressed;
  final VoidCallback? onMapPressed;

  const NotificationsScreen({
    Key? key,
    this.onHomePressed,
    this.onSearchPressed,
    this.onPlusPressed,
    this.onMessagesPressed,
    this.onMePressed,
    this.onMapPressed,
  }) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isRefreshing = false;
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  Timer? _refreshTimer;
  final FocusNode _focusNode = FocusNode();

  List<NotificationCategory> _categories =
      NotificationCategory.getDefaultCategories();
  List<dynamic> _directMessages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _notificationService.notificationState.hasUnreadStream.listen((hasUnread) {
      _fetchNotifications();
      if (mounted) {
        setState(() {}); // Triggers UI update
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    NotificationService().fetchNotifications();
    ;
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _fetchNotifications();
    }
  }

  Future<void> _fetchNotifications() async {
    if (!mounted || _isRefreshing) return;

    try {
      setState(() {
        _isRefreshing = true;
        _isLoading = true; // ✅ Start loading
      });
      print('🔄 Fetching notifications...');

      final response = await _apiService.makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/notifications/',
        method: 'GET',
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        print('❌ API Error: ${response.statusCode}');
        setState(() {
          _error = 'Failed to load notifications';
          _isLoading = false;
        });
        return;
      }

      final Map<String, dynamic>? userInfo = await _apiService.getUserInfo();
      if (userInfo == null || userInfo['id'] == null) {
        print('❌ No logged-in user found.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final int currentUserId = userInfo['id'];
      final data = json.decode(response.body);

      print('📩 Notifications fetched: ${data['notifications'].length}');

      final unreadNotifications = (data['notifications'] as List)
          .where((n) =>
              n['is_read'] == false && n['recipient']['id'] == currentUserId)
          .toList();

      setState(() {
        _categories = NotificationCategory.updateWithNotifications(
            NotificationCategory.getDefaultCategories(), unreadNotifications);
        _isLoading = false; // ✅ Ensure UI updates
      });

      final unreadCount = unreadNotifications.length;
      _notificationService.notificationState.setUnreadStatus(unreadCount > 0);
      print('✅ Notifications updated, unread count: $unreadCount');
    } catch (e, stackTrace) {
      print('❌ Error in _fetchNotifications: $e');
      print(stackTrace);
      setState(() {
        _error = 'Error loading notifications';
        _isLoading = false; // ✅ Prevent infinite loading
      });
    } finally {
      setState(() {
        _isRefreshing = false;
        _isLoading = false; // ✅ Ensure loading is disabled
      });
      print('✅ Fetch completed, _isLoading = $_isLoading');
    }
  }

  Future<void> _handleNotificationRead(NotificationType type, String id) async {
    try {
      await _notificationService.markNotificationAsRead(int.parse(id));
      await _fetchNotifications();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  void _onCategoryTap(NotificationCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryDetailScreen(
          category: category,
          onMessageRead: _handleNotificationRead,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 Building Message Page - isLoading: $_isLoading, error: $_error');
    return Focus(
      focusNode: _focusNode,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Messages'),
              TextButton(
                onPressed: () {},
                child: const Text('More Groups'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                ),
              ),
            ],
          ),
          automaticallyImplyLeading: false,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator()) // ✅ Stuck here?
            : _error != null
                ? _buildErrorView()
                : _buildNotificationsView(),
        bottomNavigationBar: Footer(
          onHomePressed: widget.onHomePressed ?? () => Navigator.pop(context),
          onSearchPressed: widget.onSearchPressed ?? () {},
          onPlusPressed: widget.onPlusPressed ?? () {},
          onMessagesPressed: _fetchNotifications,
          onMePressed: widget.onMePressed ?? () {},
          onMapPressed: widget.onMapPressed ?? () {},
          hasUnreadMessages: NotificationService().notificationState.hasUnread,
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchNotifications,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsView() {
    return Column(
      children: [
        _buildCategoryGrid(),
        const Divider(height: 1),
        Expanded(
          child: _buildDirectMessagesList(),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _categories
            .map((category) => _buildCategoryButton(category))
            .toList(),
      ),
    );
  }

  Widget _buildCategoryButton(NotificationCategory category) {
    return InkWell(
      onTap: () => _onCategoryTap(category),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: category.hasUnread ? Colors.red : Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: Icon(
              category.icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectMessagesList() {
    if (_directMessages.isEmpty) {
      return Center(
        child: Text(
          'No messages yet',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _directMessages.length,
      itemBuilder: (context, index) {
        final message = _directMessages[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(message['sender']?['avatar'] ?? ''),
          ),
          title: Text(message['sender']?['username'] ?? 'Unknown'),
          subtitle: Text(message['message'] ?? ''),
          trailing: Text(message['created_at'] ?? ''),
          onTap: () {
            // Handle direct message tap
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}

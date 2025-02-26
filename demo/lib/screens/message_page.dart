import 'dart:async';
import 'dart:convert';
import 'package:demo/screens/direct_messages_list.dart';
import 'package:demo/screens/message_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:demo/enums/notification_types.dart';
import 'package:demo/models/message_category.dart';
import 'package:demo/screens/notification_detail_page.dart';
import 'package:demo/services/api_service.dart';
import 'package:demo/services/notification_service.dart';
import 'package:demo/widgets/footer.dart';

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
  bool _isInitialized = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _notificationService.notificationState.hasUnreadStream.listen((hasUnread) {
      if (mounted && !_isRefreshing) {
        _fetchNotifications();
      }
    });
    _fetchCurrentUserId(); // ✅ Load user ID
    _fetchDirectMessages();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _fetchNotifications();

      _fetchCurrentUserId(); // ✅ Load user ID
      _fetchDirectMessages;
    }
  }

  // @override
  // void dispose() {
  //   _refreshTimer?.cancel();
  //   _scrollController.dispose();
  //   _messageController.dispose();
  //   super.dispose();
  // }

  /// **Fetch current user's ID**
  Future<void> _fetchCurrentUserId() async {
    int? userId = await _apiService.getCurrentUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && !_isRefreshing) {
      _fetchNotifications();

      _fetchCurrentUserId(); // ✅ Load user ID
      _fetchDirectMessages;
    }
  }

  Future<void> _fetchNotifications() async {
    if (!mounted || _isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔄 Fetching notifications...');

      final response = await _apiService.makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/notifications/',
        method: 'GET',
      );

      if (!mounted) return;

      if (response.statusCode != 200) {
        print('❌ API Error: ${response.statusCode}');
        throw Exception('Failed to load notifications');
      }

      final Map<String, dynamic>? userInfo = await _apiService.getUserInfo();
      if (userInfo == null || userInfo['id'] == null) {
        print('❌ No logged-in user found.');
        throw Exception('No logged-in user found');
      }

      final int currentUserId = userInfo['id'];

      final data = json.decode(response.body);
      final notifications = data['notifications'] as List;

      print('📩 Notifications fetched: ${notifications.length}');

      // Update categories with all notifications
      final updatedCategories = NotificationCategory.updateWithNotifications(
        NotificationCategory.getDefaultCategories(),
        notifications,
      );

      // Count unread notifications
      final unreadNotifications = notifications
          .where((n) =>
              n['is_read'] == false &&
              n['recipient']
                  is Map<String, dynamic> && // Ensure recipient is a Map
              n['recipient']['id'] == currentUserId)
          .toList();

      if (mounted) {
        setState(() {
          _categories = updatedCategories;
          _isLoading = false;
          _isRefreshing = false;
          _error = null;
        });
      }

      final unreadCount = unreadNotifications.length;
      _notificationService.notificationState.setUnreadStatus(unreadCount > 0);
      print('✅ Notifications updated, unread count: $unreadCount');
    } catch (e, stackTrace) {
      print('❌ Error in _fetchNotifications: $e');
      print(stackTrace);

      if (mounted) {
        setState(() {
          _error = e.toString();
          _categories = NotificationCategory.getDefaultCategories();
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _fetchDirectMessages() async {
    if (!mounted || _isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _isLoading = true;
      _error = null;
    });

    try {
      print('📩 Fetching direct messages...');

      final messages =
          await _apiService.fetchConversations(); // ✅ Calls the API

      if (messages.isNotEmpty) {
        messages.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      }

      // ✅ Debugging - Print messages before processing
      print("Fetched direct messages: ${json.encode(messages)}");

      if (mounted) {
        setState(() {
          _directMessages = messages
              .where((message) => message is Map<String, dynamic>)
              .map((message) {
            return {
              'id': message['id'],
              'sender': message['sender'] is Map<String, dynamic>
                  ? message['sender']
                  : {'id': message['sender']}, // Convert to a map
              'receiver': message['receiver'] is Map<String, dynamic>
                  ? message['receiver']
                  : {'id': message['receiver']}, // Convert to a map
              'message_content':
                  message['content'] ?? "No content", // Ensure not null
              'timestamp': message['timestamp'] ?? "", // Ensure not null
              'is_read': message['is_read'] ?? false,
            };
          }).toList();

          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error in _fetchDirectMessages: $e');
      print(stackTrace);

      if (mounted) {
        setState(() {
          _error = e.toString();
          _directMessages = [];
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
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

    // ✅ Ensure currentUserId is initialized before rendering messages
    if (_currentUserId == null) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _directMessages.length, // ✅ Show all direct messages
      itemBuilder: (context, index) {
        final message = _directMessages[index];

        // ✅ Ensure message content is shown correctly
        final messageContent =
            message['message_content'] ?? "No message content";
        final sender = message['sender'];
        final receiver = message['receiver'];

        // ✅ Determine the chat partner
        final chatPartnerId =
            sender['id'] == _currentUserId ? receiver['id'] : sender['id'];
        final chatPartnerUsername = sender['id'] == _currentUserId
            ? receiver['username']
            : sender['username'];

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(receiver['profile_picture_url']),
            radius: 24,
          ),
          title: Text(
            chatPartnerUsername,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            messageContent,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: message['is_read'] ? Colors.grey : Colors.white),
          ),
          trailing: message['is_read']
              ? Icon(Icons.done_all, color: Colors.green)
              : Icon(Icons.markunread,
                  color: Colors.red), // ✅ Indicate unread messages
          onTap: () async {
            print("📨 Opening conversation with $chatPartnerUsername");

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MessageDetailPage(userId: chatPartnerId),
              ),
            );

            // ✅ Refresh messages after returning from chat
            _fetchDirectMessages();
          },
        );
      },
    );
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

  Future<void> _handleNotificationRead(NotificationType type, String id) async {
    try {
      await _notificationService.markNotificationAsRead(int.parse(id));
      await _fetchNotifications();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
        body: RefreshIndicator(
          onRefresh: _fetchNotifications,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorView()
                  : _buildNotificationsView(),
        ),
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

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}

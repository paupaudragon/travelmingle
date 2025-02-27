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
import 'package:intl/intl.dart';

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

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
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
    // _notificationService.notificationState.hasUnreadStream.listen((hasUnread) {
    //   if (mounted && !_isRefreshing) {
    //     _fetchNotifications();
    //   }
    // });
    _fetchNotifications();
    _fetchCurrentUserId(); // ✅ Load user ID
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      _fetchNotifications();
      _fetchCurrentUserId(); // ✅ Load user ID
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("🔄 App resumed - Refreshing notifications...");
      _fetchNotifications();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // ✅ Remove observer
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

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
    if (_focusNode.hasFocus || !_isRefreshing) {
      _fetchNotifications();

      _fetchCurrentUserId(); // ✅ Load user ID
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

      _currentUserId = userInfo['id'];

      final data = json.decode(response.body);
      final notifications = data['notifications'] as List;

      print('📩 Notifications fetched: ${notifications.length}');

      // ✅ Fetch the latest messages from conversations
      final conversationsResponse = await _apiService.makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/messages/conversations/',
        method: 'GET',
      );

      if (conversationsResponse.statusCode != 200) {
        print('❌ Error fetching conversations.');
        throw Exception('Failed to load conversations');
      }

      final List<dynamic> conversations =
          json.decode(conversationsResponse.body);

      // ✅ Keep only the latest message per conversation
      Map<int, dynamic> latestMessages = {};
      for (var message in conversations) {
        int senderId = message['sender'];
        int receiverId = message['receiver'];

        int chatPartnerId = senderId == _currentUserId ? receiverId : senderId;

        if (!latestMessages.containsKey(chatPartnerId) ||
            DateTime.parse(message['timestamp']).isAfter(
                DateTime.parse(latestMessages[chatPartnerId]['timestamp']))) {
          latestMessages[chatPartnerId] = message;
        }
      }

      final filteredMessageNotifications = latestMessages.values.toList();

      // ✅ Sort messages by newest
      filteredMessageNotifications.sort((a, b) => DateTime.parse(b['timestamp'])
          .compareTo(DateTime.parse(a['timestamp'])));

      // ✅ Add prefix if the current user sent the latest message
      for (var msg in filteredMessageNotifications) {
        int senderId = msg['sender'];

        if (senderId == _currentUserId) {
          msg['content'] = "You: ${msg['content']}";
        }
      }

      // ✅ Update state with filtered messages
      if (mounted) {
        setState(() {
          _directMessages = filteredMessageNotifications;
          _isLoading = false;
          _isRefreshing = false;
          _error = null;
        });
      }

      final unreadCount =
          notifications.where((n) => n['is_read'] == false).length;
      _notificationService.notificationState.setUnreadStatus(unreadCount > 0);
      print('✅ Notifications updated, unread count: $unreadCount');
    } catch (e, stackTrace) {
      print('❌ Error in _fetchNotifications: $e');
      print(stackTrace);

      if (mounted) {
        setState(() {
          _error = e.toString();
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
              color: Colors.black,
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
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _directMessages.length,
      itemBuilder: (context, index) {
        final message = _directMessages[index];
        final int senderId = message['sender'];
        final int receiverId = message['receiver'];
        final bool isSentByCurrentUser = senderId == _currentUserId;
        final int chatPartnerId = isSentByCurrentUser ? receiverId : senderId;

        return FutureBuilder<Map<String, dynamic>>(
          future: _apiService.fetchUserProfile(chatPartnerId),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListTile(
                title: Text("Loading..."),
                subtitle: Text("Fetching chat details..."),
                leading: CircleAvatar(backgroundColor: Colors.grey[300]),
              );
            }

            final userProfile = snapshot.data!;
            final chatPartnerUsername = userProfile['username'] ?? "Unknown";
            final chatPartnerProfilePic = userProfile['profile_picture_url'] ?? "";

            final String content = message['content'] ?? 'No content';
            final timestamp = message['timestamp'] ?? "";
            final bool isRead = message['is_read'] ?? false;

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: chatPartnerProfilePic.isNotEmpty
                    ? NetworkImage(chatPartnerProfilePic)
                    : AssetImage('assets/images/default_avatar.png')
                        as ImageProvider,
              ),
              title: Text(chatPartnerUsername),
              subtitle:
                  Text(content, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat.jm().format(DateTime.parse(timestamp)),
                    style: TextStyle(color: Colors.grey),
                  ),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              onTap: () async {
                print("✅ Opening chat with $chatPartnerUsername");
                await _notificationService
                    .markNotificationAsRead(message['id']);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MessageDetailPage(userId: chatPartnerId),
                  ),
                );
              },
            );
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
}

import 'package:demo/enums/notification_types.dart';
import 'package:demo/models/message_category.dart';
import 'package:demo/screens/user_list_page.dart';
import 'package:flutter/material.dart';
import 'package:demo/services/notification_service.dart';
import 'package:demo/screens/post_page.dart'; // Add this import

class CategoryDetailScreen extends StatefulWidget {
  final NotificationCategory category;
  final Function(NotificationType, String) onMessageRead;

  const CategoryDetailScreen({
    Key? key,
    required this.category,
    required this.onMessageRead,
  }) : super(key: key);

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isMarking = false;
  List<dynamic> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllNotifications();
  }

  Future<void> _loadAllNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _notificationService.fetchNotifications();
      setState(() {
        _items = List.from(widget.category.items);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading notifications: $e');
      setState(() {
        _isLoading = false;
        _items = [];
      });
    }
  }

  Future<void> _handleItemTap(dynamic item) async {
    // Debug print to see the full notification item
    print('Tapped notification item: $item');

    // Mark as read if unread
    if (item['is_read'] == false) {
      await _markItemAsRead(item);
    }

    if (!mounted) return;

    // Check notification type
    final notificationType = item['notification_type'];

    if (notificationType == 'follow') {
      // For follow notifications, navigate to the current user's follower list
      if (item['recipient'] != null && item['recipient']['id'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FollowListPage(
              userId: item['recipient']['id'],
              initialTabIndex: 1, // 1 is for followers tab
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Cannot navigate to followers list - User info not found'),
            ),
          );
        }
      }
    } else {
      // Handle post-related notifications (likes, comments, etc.)
      final postData = item['post'];
      if (postData != null) {
        final postId = postData['id'];
        print('Extracted post_id: $postId');

        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostPage(
                postId: postId,
                onPostUpdated: (updatedPost) {
                  print('Post updated: ${updatedPost.id}');
                  _loadAllNotifications();
                },
              ),
            ),
          );
        } catch (e) {
          print('Error navigating to post: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error navigating to post: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        print('No post data found in notification item');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Cannot navigate to this notification content - No post data found'),
            ),
          );
        }
      }
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarking) return;

    setState(() {
      _isMarking = true;
    });

    try {
      final unreadItems =
          _items.where((item) => item['is_read'] == false).toList();

      if (unreadItems.isEmpty) {
        setState(() {
          _isMarking = false;
        });
        return;
      }

      setState(() {
        for (final item in unreadItems) {
          final index = _items.indexWhere((i) => i['id'] == item['id']);
          if (index != -1) {
            _items[index] = Map.from(_items[index])..['is_read'] = true;
          }
        }
      });

      NotificationService notificationService = NotificationService();
      notificationService.notificationState.setUnreadStatus(false);
      await notificationService.markAllAsRead();
      await notificationService.fetchNotifications();
    } catch (e) {
      print('❌ Error marking all as read: $e');
    } finally {
      setState(() {
        _isMarking = false;
      });
    }
  }

  Future<void> _markItemAsRead(dynamic item) async {
    final type = NotificationCategory.typeFromString(item['notification_type']);
    if (type != null) {
      await widget.onMessageRead(type, item['id'].toString());
      await NotificationService().fetchNotifications();

      final index = _items.indexWhere((i) => i['id'] == item['id']);
      if (index != -1) {
        setState(() {
          _items[index] = Map.from(_items[index])..['is_read'] = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.category.name),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final hasUnread = _items.any((item) => item['is_read'] == false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _isMarking ? null : _markAllAsRead,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: _isMarking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Mark All Read'),
            ),
        ],
      ),
      body: _items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.category.icon,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${widget.category.name} yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final isUnread = item['is_read'] == false;

                return ListTile(
                  onTap: () => _handleItemTap(item),
                  title: Text(item['message'] ?? 'No message'),
                  subtitle: Text(item['created_at'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

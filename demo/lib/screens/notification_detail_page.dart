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
  bool _isNavigating = false;

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
        _items = widget.category.items.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          return <String, dynamic>{};
        }).toList();
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

  Future<void> _handleItemTap(dynamic rawItem) async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      // Helper function to recursively convert maps
      Map<String, dynamic> convertMap(Map map) {
        return map.map((key, value) {
          if (value is Map) {
            return MapEntry(key.toString(), convertMap(value));
          } else if (value is List) {
            return MapEntry(
                key.toString(),
                value.map((item) {
                  if (item is Map) {
                    return convertMap(item);
                  }
                  return item;
                }).toList());
          }
          return MapEntry(key.toString(), value);
        });
      }

      // Convert the raw item
      final Map<String, dynamic> item = convertMap(rawItem as Map);

      // Mark notification as read if it's unread
      if (item['is_read'] == false) {
        final notificationId = item['id'];
        print('📱 Marking notification $notificationId as read');

        try {
          // Call the notification service to mark as read
          await NotificationService().markNotificationAsRead(notificationId);

          // Update local state after successful API call
          final index = _items.indexWhere((i) => i['id'] == notificationId);
          if (index != -1) {
            setState(() {
              _items[index] = Map<String, dynamic>.from(_items[index])
                ..['is_read'] = true;
            });
          }
        } catch (e) {
          print('❌ Error marking notification as read: $e');
        }
      }

      final notificationType = item['notification_type'];
      print('📱 Processing notification type: $notificationType');

      if (notificationType == 'follow') {
        final recipientData = item['recipient'] as Map<String, dynamic>;
        final recipientId = recipientData['id'];

        print('📱 Navigating to follower list for user ID: $recipientId');

        if (recipientId != null) {
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FollowListPage(
                userId: recipientId,
                initialTabIndex: 1,
              ),
            ),
          );
          // Reload notifications after returning
          await _loadAllNotifications();
        }
      } else if (item['post'] != null) {
        final postData = item['post'] as Map<String, dynamic>;
        final postId = postData['id'];

        if (postId != null) {
          print('📱 Navigating to post: $postId');
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostPage(
                postId: postId,
                onPostUpdated: (updatedPost) {
                  print('📱 Post updated: ${updatedPost.id}');
                  _loadAllNotifications();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error in _handleItemTap: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isNavigating = false;
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

      // Update local state immediately for better UX
      setState(() {
        // Create new list items with updated read status
        _items = _items.map((item) {
          // Create a new map to avoid modifying the original
          final newItem = Map<String, dynamic>.from(item);
          newItem['is_read'] = true;
          return newItem;
        }).toList();
      });

      // Create a properly typed NotificationService instance
      NotificationService notificationService = NotificationService();

      // Call the API to mark all as read
      await notificationService.markAllAsRead();

      // Update the UI state
      notificationService.notificationState.setUnreadStatus(false);

      // Refresh the notifications list completely from the server
      await notificationService.fetchNotifications();

      // Force refresh the local list to match server state
      await _loadAllNotifications();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error marking all as read: $e');

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking all as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Reload to ensure UI consistency
      await _loadAllNotifications();
    } finally {
      if (mounted) {
        setState(() {
          _isMarking = false;
        });
      }
    }
  }

  Future<void> _markItemAsRead(dynamic item) async {
    try {
      final type =
          NotificationCategory.typeFromString(item['notification_type']);
      if (type != null) {
        final notificationId = item['id'];
        print('📱 Marking notification $notificationId as read'); // Debug print

        // Update local state first for immediate UI feedback
        final index = _items.indexWhere((i) => i['id'] == notificationId);
        if (index != -1) {
          setState(() {
            _items[index] = Map.from(_items[index])..['is_read'] = true;
          });
        }

        // Call the notification service
        await NotificationService().markNotificationAsRead(notificationId);

        // Update the UI callback
        await widget.onMessageRead(type, notificationId.toString());

        // Refresh notifications
        await _loadAllNotifications();
      }
    } catch (e) {
      print('❌ Error marking item as read: $e');
      // Refresh notifications on error to ensure consistent state
      await _loadAllNotifications();
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
                  title: Text(_getNotificationMessage(item)),
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

  String _getNotificationMessage(Map<String, dynamic> item) {
    final notificationType = item['notification_type'];

    if (notificationType == 'follow') {
      final senderUsername = item['sender']?['username'] ?? 'Someone';
      return '$senderUsername started following you';
    }

    return item['message'] ?? 'New notification';
  }
}

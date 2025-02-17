import 'package:demo/enums/notification_types.dart';
import 'package:demo/models/message_category.dart';
import 'package:flutter/material.dart';
import 'package:demo/services/notification_service.dart';

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

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.category.items);
  }

  @override
  void dispose() {
    // Trigger refresh of main screen when returning
    if (Navigator.canPop(context)) {
      final route = ModalRoute.of(context);
      if (route?.isCurrent ?? false) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            NotificationService().fetchNotifications();
          }
        });
      }
    }
    super.dispose();
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
          _isMarking = false; // ✅ Ensure we reset UI state
        });
        return;
      }

      // ✅ Update local UI instantly before hitting backend
      setState(() {
        for (final item in unreadItems) {
          final index = _items.indexWhere((i) => i['id'] == item['id']);
          if (index != -1) {
            _items[index] = Map.from(_items[index])..['is_read'] = true;
          }
        }
      });

      NotificationService notificationService = NotificationService();

      // ✅ Immediately update the unread status globally
      notificationService.notificationState.setUnreadStatus(false);

      // ✅ Make the API call to mark all notifications as read
      await notificationService.markAllAsRead();

      // ✅ Refresh UI after backend confirms update
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

      // ✅ Notify FCM & backend
      await NotificationService().fetchNotifications();

      // ✅ Update UI instantly
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
    final hasUnread = _items.any((item) => item['is_read'] == false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        actions: [
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

                return InkWell(
                  onTap: isUnread ? () => _markItemAsRead(item) : null,
                  child: ListTile(
                    title: Text(item['message'] ?? 'No message'),
                    subtitle: Text(item['created_at'] ?? ''),
                    trailing: isUnread
                        ? Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}

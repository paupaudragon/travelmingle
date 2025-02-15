import 'dart:async';

import 'package:flutter/material.dart';
import 'package:demo/services/api_service.dart';
import 'package:demo/services/notification_service.dart';
import '../widgets/footer.dart';
import 'dart:convert';

class NotificationsScreen extends StatefulWidget {
  final Function? onHomePressed;
  final Function? onSearchPressed;
  final Function? onPlusPressed;
  final Function? onMessagesPressed;
  final Function? onMePressed;
  final Function? onMapPressed;

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
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _fetchNotifications();
      }
    });
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _apiService.makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/notifications/',
        method: 'GET',
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        final rawNotifications = decodedData['notifications'] as List;
        final serverUnreadCount = decodedData['unread_count'] as int;

        print('📱 Server unread count: $serverUnreadCount');
        print('📱 Total notifications: ${rawNotifications.length}');

        // Group notifications by semantic action
        final Map<String, dynamic> uniqueNotifications = {};

        for (var notification in rawNotifications) {
          final timestamp = notification['created_at']?.toString() ?? '';
          final sender =
              notification['sender']?['username']?.toString() ?? 'unknown';
          final type = notification['notification_type']?.toString() ?? '';
          final postId = notification['post']?['id']?.toString() ?? '';
          final isRead = notification['is_read'] ?? false;

          if (timestamp.isNotEmpty) {
            try {
              final DateTime parsedTime = DateTime.parse(timestamp);
              String actionKey =
                  '$sender:$type:$postId:${parsedTime.millisecondsSinceEpoch ~/ 1000}';

              // Keep the unread version if it exists
              if (!uniqueNotifications.containsKey(actionKey) ||
                  (uniqueNotifications[actionKey]['is_read'] == true &&
                      !isRead)) {
                uniqueNotifications[actionKey] = notification;
              }
            } catch (e) {
              print('Error parsing timestamp: $e');
              continue;
            }
          }
        }

        final notificationsList = uniqueNotifications.values.toList()
          ..sort((a, b) => DateTime.parse(b['created_at'].toString())
              .compareTo(DateTime.parse(a['created_at'].toString())));

        // Count unread after deduplication
        final actualUnreadCount =
            notificationsList.where((n) => n['is_read'] == false).length;
        print('📱 Actual unread count after deduplication: $actualUnreadCount');

        // Update notification state based on actual unread count
        _notificationService.notificationState
            .setUnreadStatus(actualUnreadCount > 0);

        if (!mounted) return;
        setState(() {
          _notifications = notificationsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error in _fetchNotifications: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markNotificationAsRead(int notificationId) async {
    try {
      final response = await _apiService.makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/notifications/mark-read/',
        method: 'POST',
        body: {
          'notification_ids': [notificationId],
        },
      );

      if (response.statusCode == 200) {
        // Update the local state of the notification
        setState(() {
          final index =
              _notifications.indexWhere((n) => n['id'] == notificationId);
          if (index != -1) {
            _notifications[index]['is_read'] = true;
          }
        });
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      await _fetchNotifications(); // Refresh the list
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  void _handleNotificationTap(dynamic notification) async {
    if (notification['is_read'] == false) {
      try {
        print('🔔 Tapping notification: ${notification['id']}');

        // Update local state immediately
        setState(() {
          final index =
              _notifications.indexWhere((n) => n['id'] == notification['id']);
          if (index != -1) {
            _notifications[index]['is_read'] = true;
          }
        });

        // Mark as read in backend
        await _markNotificationAsRead(notification['id']);

        // Short delay to allow server processing
        await Future.delayed(const Duration(milliseconds: 300));

        // Count remaining unread
        final remainingUnread =
            _notifications.where((n) => n['is_read'] == false).length;
        print('📱 Remaining unread after tap: $remainingUnread');

        // Update icon state
        _notificationService.notificationState
            .setUnreadStatus(remainingUnread > 0);

        // If this was the last unread, do a final refresh
        if (remainingUnread == 0) {
          await Future.delayed(const Duration(milliseconds: 500));
          await _fetchNotifications();
        }
      } catch (e) {
        print('❌ Error handling notification tap: $e');
        // Refresh to ensure consistent state
        await _fetchNotifications();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('Mark All Read'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
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
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return InkWell(
                      onTap: () => _handleNotificationTap(notification),
                      child: ListTile(
                        title: Text(notification['message'] ?? 'No message'),
                        subtitle: Text(notification['created_at'] ?? ''),
                        trailing: notification['is_read'] == false
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
      bottomNavigationBar: Footer(
        onHomePressed: () =>
            widget.onHomePressed?.call() ?? Navigator.pop(context),
        onSearchPressed: () => widget.onSearchPressed?.call(),
        onPlusPressed: () => widget.onPlusPressed?.call(),
        onMessagesPressed: _fetchNotifications,
        onMePressed: () => widget.onMePressed?.call(),
        onMapPressed: () => widget.onMapPressed?.call(),
      ),
    );
  }

  @override
  void dispose() {
    // Cancel timer if it exists
    _refreshTimer?.cancel();
    super.dispose();
  }
}

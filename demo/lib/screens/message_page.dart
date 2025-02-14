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

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _apiService.makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/notifications/',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        setState(() {
          _notifications = decodedData['notifications'];
          _isLoading = false;
        });
      } else {
        throw Exception(
            'Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
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
        await _fetchNotifications(); // Refresh the list
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
      await _markNotificationAsRead(notification['id']);
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
}

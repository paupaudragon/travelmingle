// lib/services/notification_state.dart
import 'dart:async';

class NotificationState {
  static final NotificationState _instance = NotificationState._internal();
  factory NotificationState() => _instance;
  NotificationState._internal();

  final _hasUnreadController = StreamController<bool>.broadcast();
  Stream<bool> get hasUnreadStream => _hasUnreadController.stream;

  bool _hasUnread = false;
  bool get hasUnread => _hasUnread;

  void setUnreadStatus(bool hasUnread) {
    print('Setting unread status: $hasUnread'); // Debug log
    _hasUnread = hasUnread;
    _hasUnreadController.add(hasUnread);
  }

  void dispose() {
    _hasUnreadController.close();
  }
}

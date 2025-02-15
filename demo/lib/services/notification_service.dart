import 'dart:async';
import 'package:demo/services/api_service.dart';
import 'package:demo/services/notification_state.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();
  final NotificationState _notificationState = NotificationState();
  Timer? _periodicTimer;

  NotificationState get notificationState => _notificationState;

  @pragma('vm:entry-point')
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print("📱 Background message received:");
    print("Title: ${message.notification?.title}");
    print("Body: ${message.notification?.body}");
    print("Data: ${message.data}");
  }

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // Initialize local notifications
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        print('Notification tapped: ${details.payload}');
      },
    );

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
      await registerDeviceToken(token);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Initial check for unread notifications
    await checkUnreadNotifications();

    // Start periodic check (every 30 seconds)
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      checkUnreadNotifications();
    });
  }

  Future<void> registerDeviceToken(String token) async {
    try {
      final response = await _apiService.makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/register-device/',
        method: 'POST',
        body: {"token": token},
      );

      if (response.statusCode == 200) {
        print('✅ Device registered successfully');
      } else {
        print('❌ Failed to register device. Status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('❌ Error registering device: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.notification?.title}');
    await _showLocalNotification(message);
    await checkUnreadNotifications();
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannel.id,
          androidChannel.name,
          channelDescription: androidChannel.description,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await _apiService.makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/notifications/mark-read/',
        method: 'POST',
        body: {'mark_all': true},
      );

      if (response.statusCode == 200) {
        // Update state immediately
        _notificationState.setUnreadStatus(false);

        // Double check server state after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        await checkUnreadNotifications();
      }
    } catch (e) {
      print('❌ Error marking all as read: $e');
      // Recheck state on error
      await checkUnreadNotifications();
    }
  }

  Future checkUnreadNotifications() async {
    try {
      print('📱 Checking notifications...');
      final response = await _apiService.makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/notifications/',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final unreadCount = data['unread_count'] ?? 0;
        print('📱 Unread count from API: $unreadCount');

        // Update notification state
        _notificationState.setUnreadStatus(unreadCount > 0);

        print('📱 Updated notification state - hasUnread: ${unreadCount > 0}');
        return unreadCount;
      }
    } catch (e) {
      print('❌ Error checking notifications: $e');
      return 0;
    }
  }

  Future<void> refreshNotificationState() async {
    print('📱 Manually refreshing notification state...');
    await checkUnreadNotifications();
  }

  void dispose() {
    _periodicTimer?.cancel();
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      print('📱 Marking notification $notificationId as read...');
      final response = await _apiService.makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/notifications/mark-read/',
        method: 'POST',
        body: {
          'notification_ids': [notificationId],
        },
      );

      if (response.statusCode == 200) {
        print('📱 Successfully marked notification as read');
        // Get the updated unread count from the response
        final data = json.decode(response.body);
        final unreadCount = data['unread_count'] ?? 0;

        // Update state immediately
        _notificationState.setUnreadStatus(unreadCount > 0);
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      // On error, refresh the notification state
      await checkUnreadNotifications();
    }
  }
}

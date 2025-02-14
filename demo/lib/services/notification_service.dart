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

  Future<void> checkUnreadNotifications() async {
    try {
      print('📱 Checking notifications...');
      // Get and print headers for debugging
      final headers = await _apiService.getHeaders();
      print('📱 Request headers: $headers');

      final response = await _apiService.makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/notifications/',
        method: 'GET',
      );

      print('📱 Response status: ${response.statusCode}');
      print('📱 Response headers: ${response.headers}');
      print('📱 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final unreadCount = data['unread_count'] ?? 0;
        print('📱 Unread count from API: $unreadCount');

        // Print notifications details
        if (data['notifications'] != null) {
          final notifications = data['notifications'] as List;
          print('📱 Total notifications: ${notifications.length}');
          print(
              '📱 Unread notifications: ${notifications.where((n) => n['is_read'] == false).length}');

          // Print the first 3 notifications for debugging
          final numberOfNotificationsToPrint =
              notifications.length < 3 ? notifications.length : 3;
          for (var i = 0; i < numberOfNotificationsToPrint; i++) {
            print('📱 Notification ${i + 1}:');
            print('   - Message: ${notifications[i]['message']}');
            print('   - Is Read: ${notifications[i]['is_read']}');
            print('   - Created At: ${notifications[i]['created_at']}');
          }
        }

        _notificationState.setUnreadStatus(unreadCount > 0);
        print('📱 Set unread status to: ${unreadCount > 0}');
      }
    } catch (e, stackTrace) {
      print('❌ Error checking notifications:');
      print(e);
      print('Stack trace:');
      print(stackTrace);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      print('📱 Marking all notifications as read...');
      final response = await _apiService.makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/notifications/mark-read/',
        method: 'POST',
        body: {'mark_all': true},
      );

      if (response.statusCode == 200) {
        _notificationState.setUnreadStatus(false);
        print('📱 Successfully marked all as read');
        await checkUnreadNotifications(); // Refresh notification state
      }
    } catch (e) {
      print('❌ Error marking notifications as read: $e');
      rethrow;
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
        await checkUnreadNotifications(); // Update unread status
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      rethrow;
    }
  }
}

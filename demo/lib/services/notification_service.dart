import 'dart:async';
import 'package:demo/services/api_service.dart';
import 'package:demo/services/notification_state.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

class NotificationService {
  List<Map<String, dynamic>> _cachedNotifications = [];
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

  void _setupTokenListeners() async {
    // Get initial token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('🔥 Initial FCM Token: $token');
      await registerDeviceToken(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((String newToken) async {
      print('🔄 FCM Token refreshed: $newToken');
      await registerDeviceToken(newToken);
    });
  }

  void reset() {
    _notificationState.setUnreadStatus(false);
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  @pragma('vm:entry-point')
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print("📱 Background message received:");
    print("Title: ${message.notification?.title}");
    print("Body: ${message.notification?.body}");
    print("Data: ${message.data}");
  }

  Future<void> initialize() async {
    print('🔄 Initializing NotificationService...');
    reset(); // ✅ Clear old notifications on start

    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    _setupTokenListeners();

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

    // Ensure we get the correct FCM token for this user
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('🔥 FCM Token: $token');
      await registerDeviceToken(token);
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    // ✅ Ensure correct user data before fetching notifications
    await Future.delayed(const Duration(seconds: 2));
    await NotificationService().fetchNotifications();

    // Start periodic check (every 30 seconds)
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      NotificationService().fetchNotifications();
    });
  }

  Future<void> registerDeviceToken(String token) async {
    try {
      print('🔄 Registering FCM token with backend...');

      // Ensure user is authenticated before proceeding
      final authToken = await _apiService.getAccessToken();
      if (authToken == null) {
        print('❌ Skipping FCM token registration: User not authenticated.');
        return; // Stop execution if no auth token is available
      }

      final response = await _apiService.makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/register-device/',
        method: 'POST',
        body: {"token": token},
      );

      if (response.statusCode == 200) {
        print(
            '✅ Device registered successfully with token: ${token.substring(0, 20)}...');
      } else {
        print('❌ Failed to register device. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error registering device token: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📩 New message received: ${message.notification?.title}');

    // Extract message details from payload
    final messageData = message.data;

    // Update unread message count
    _notificationState.setUnreadStatus(true);

    // Trigger local notification (optional)
    await _showLocalNotification(message);
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
        await Future.delayed(const Duration(milliseconds: 1000));
        // await checkUnreadNotifications();
        await NotificationService().fetchNotifications();
      }
    } catch (e) {
      print('❌ Error marking all as read: $e');
      // Recheck state on error
      await NotificationService().fetchNotifications();
    }
  }

  void dispose() {
    _periodicTimer?.cancel();
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      print('📱 Service - Marking notification $notificationId as read');

      // Update local cache first
      for (var notification in _cachedNotifications) {
        if (notification['id'] == notificationId) {
          notification['is_read'] = true;
        }
      }

      // Make API request
      final response = await _apiService.makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/notifications/mark-read/',
        method: 'POST',
        body: {
          'notification_ids': [notificationId], // Keep as integer
        },
      );

      print('📱 Mark read response status: ${response.statusCode}');
      print('📱 Mark read response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final unreadCount = data['unread_count'] ?? 0;
        _notificationState.setUnreadStatus(unreadCount > 0);

        // Refresh notifications to ensure consistency
        await fetchNotifications();
      } else {
        throw Exception(
            'Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in markNotificationAsRead: $e');
      await fetchNotifications(); // Refresh on error
      throw e; // Rethrow to handle in UI
    }
  }

  Future<void> fetchNotifications() async {
    try {
      _notificationState.setUnreadStatus(false);

      final response = await _apiService.makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/notifications/',
        method: 'GET',
      );

      final Map<String, dynamic>? userInfo = await _apiService.getUserInfo();
      if (userInfo == null || userInfo['id'] == null) {
        print('❌ No logged-in user found.');
        return;
      }
      final int currentUserId = userInfo['id'];

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cachedNotifications =
            List<Map<String, dynamic>>.from(data['notifications']);
        final unreadNotifications = (data['notifications'] as List)
            .where((n) =>
                n['is_read'] == false && n['recipient']['id'] == currentUserId)
            .toList();

        _cachedNotifications =
            List<Map<String, dynamic>>.from(data['notifications']);

        final unreadCount = unreadNotifications.length;
        print('📱 Updated unread count: $unreadCount');

        // ✅ Update notification state so the message icon updates
        notificationState.setUnreadStatus(unreadCount > 0);
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
    }
  }
}

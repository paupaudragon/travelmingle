import 'dart:async';
import 'package:demo/services/api_service.dart';
import 'package:demo/services/notification_state.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

class NotificationService {
  static bool _isInitialized = false;
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

  Future<void> reset() async {
    print("🧹 Resetting NotificationService...");

    // Clear notification state
    _notificationState.setUnreadStatus(false);

    // Clear cached notifications
    _cachedNotifications = [];

    // Cancel any ongoing timers
    _periodicTimer?.cancel();
    _periodicTimer = null;

    // Reset initialization flag
    _isInitialized = false;

    print("✅ NotificationService reset completed");
  }

  @pragma('vm:entry-point')
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print("📱 Background message received:");
    print("Title: ${message.notification?.title}");
    print("Body: ${message.notification?.body}");
    print("Data: ${message.data}");
  }

  Future<void> initialize({required int userId}) async {
    // If already initialized for this user, do nothing
    if (_isInitialized) return;

    print('🔄 Initializing NotificationService for user ID: $userId...');

    // Clear previous state
    await reset();

    try {
      // Request permission for push notifications
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');

      // Get and register token only after we know which user is active
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('🔥 FCM Token for user $userId: ${token.substring(0, 10)}...');
        await registerDeviceToken(token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((String newToken) async {
        print('🔄 FCM Token refreshed: ${newToken.substring(0, 10)}...');
        await registerDeviceToken(newToken);
      });

      // Set up message handling
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      _isInitialized = true;
      print('✅ NotificationService initialized for user ID: $userId');
    } catch (e) {
      print('❌ Error initializing NotificationService: $e');
    }
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
        body: <String, dynamic>{'mark_all': "true"},
      );

      if (response.statusCode == 200) {
        // Update state immediately
        _notificationState.setUnreadStatus(false);

        // Double check server state after a short delay
        await Future.delayed(const Duration(milliseconds: 1000));
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

      // Format the request properly
      final requestBody = {
        'notification_ids': [notificationId],
      };
      print('📱 Request body: ${json.encode(requestBody)}');

      // Make API request
      final response = await _apiService.makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/notifications/mark-read/',
        method: 'POST',
        body: requestBody,
      );

      print('📱 Mark read response status: ${response.statusCode}');
      print('📱 Mark read response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📱 Parsed response data: $data');

        final unreadCount = data['unread_count'] ?? 0;
        _notificationState.setUnreadStatus(unreadCount > 0);

        // Refresh notifications to ensure consistency
        await fetchNotifications();
      } else {
        throw Exception(
            'Failed to mark notification as read: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error in markNotificationAsRead: $e');
      await fetchNotifications(); // Refresh on error
      throw e; // Rethrow to handle in UI
    }
  }

  Future<void> fetchNotifications() async {
    try {
      // Get the current user ID first
      final int? userId = await _apiService.getCurrentUserId();
      if (userId == null) {
        print("⚠️ Cannot fetch notifications: No logged-in user");
        return;
      }

      print('🔄 Fetching notifications for user $userId...');

      // Get user info to verify the right user
      final Map<String, dynamic>? userInfo = await _apiService.getUserInfo();
      if (userInfo == null ||
          userInfo['id'] == null ||
          userInfo['id'] != userId) {
        print('❌ User mismatch or no user info found. Aborting fetch.');
        return;
      }

      final response = await _apiService.makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/notifications/',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Only process data for the current user
        final int currentUserId = userInfo['id'];
        final notifications = (data['notifications'] as List)
            .where((n) => n['recipient']['id'] == currentUserId)
            .toList();

        // Cache only the current user's notifications
        _cachedNotifications = List<Map<String, dynamic>>.from(notifications);

        // Count only the current user's unread notifications
        final unreadNotifications =
            notifications.where((n) => n['is_read'] == false).toList();

        final unreadCount = unreadNotifications.length;
        print('📱 Updated unread count for user $currentUserId: $unreadCount');

        _notificationState.setUnreadStatus(unreadCount > 0);
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
    }
  }
}

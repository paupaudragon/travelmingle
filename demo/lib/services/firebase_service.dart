import 'dart:async';
import 'package:demo/services/api_service.dart';
import 'package:demo/services/notification_state.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseMessagingService {
  // Singleton pattern
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final NotificationState _notificationState = NotificationState();
  bool _isInitialized = false;

  // Stream for message events
  final _messageStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream =>
      _messageStreamController.stream;

  // Local notifications plugin for displaying notifications when app is in foreground
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize Firebase Messaging service
  Future<void> initialize() async {
    if (_isInitialized) return;

    print('🔥 Initializing Firebase Messaging Service...');

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permission
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('🔔 User granted permission: ${settings.authorizationStatus}');

      // Set up foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Set up message opened handler
      FirebaseMessaging.onMessageOpenedApp.listen(_handleAppOpenedFromMessage);

      // Get token and register with backend
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print('📱 FCM Token: ${token.substring(0, 10)}...');
        await ApiService().registerDeviceToken(token);
      }

      // Set up token refresh listener
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        print('🔄 FCM Token refreshed: ${newToken.substring(0, 10)}...');
        await ApiService().registerDeviceToken(newToken);
      });

      _isInitialized = true;
      print('✅ Firebase Messaging Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing Firebase Messaging: $e');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(initSettings);

    // Define notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Handler for foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📩 Foreground message received: ${message.data}');

    // Show a local notification
    await _showLocalNotification(message);

    // Check if this is a chat message
    if (message.data['type'] == 'message') {
      // Update notification state
      _notificationState.setUnreadStatus(true);

      // Extract message data
      final messageData = {
        'sender_id': message.data['sender_id'],
        'message_id': message.data['message_id'],
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Broadcast to all listeners
      _messageStreamController.add(messageData);
    }
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      message.hashCode,
      notification.title ?? 'New Message',
      notification.body ?? '',
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          priority: Priority.high,
          importance: Importance.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  // Handler for when app is opened from a notification
  void _handleAppOpenedFromMessage(RemoteMessage message) {
    print('🔔 App opened from notification: ${message.data}');
    // Navigation would be handled here based on notification data
  }

  // Clean up resources
  void dispose() {
    _messageStreamController.close();
  }
}

// This needs to be defined at the top level
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Background message received: ${message.data}');
  // You could store the message for later processing when the app is opened
}

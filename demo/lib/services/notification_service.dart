import 'dart:async';
import 'dart:convert';
import 'package:demo/services/api_service.dart';
import 'package:demo/services/firebase_service.dart';
import 'package:demo/services/notification_state.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // State
  final NotificationState notificationState = NotificationState();
  bool _isInitialized = false;
  List<Map<String, dynamic>> _cachedNotifications = [];

  // Throttle variables to prevent excessive API calls
  DateTime _lastFetchTime = DateTime.now().subtract(const Duration(minutes: 5));
  static const Duration _minimumFetchInterval = Duration(seconds: 30);

  // Stream controller for notification updates
  final _notificationUpdateController = StreamController<bool>.broadcast();
  Stream<bool> get notificationUpdateStream =>
      _notificationUpdateController.stream;

  /// Initialize the notification service for a specific user
  Future<void> initialize({required int userId}) async {
    if (_isInitialized) return;

    print('🔔 Initializing NotificationService for user ID: $userId');

    try {
      // Initialize Firebase through the FirebaseMessagingService
      await FirebaseMessagingService().initialize();

      // Listen for message events from Firebase
      FirebaseMessagingService().messageStream.listen(_handleNewMessage);

      // Do an initial fetch to update notification state
      await fetchNotifications();

      _isInitialized = true;
      print('✅ NotificationService initialized for user ID: $userId');
    } catch (e) {
      print('❌ Error initializing NotificationService: $e');
    }
  }

  /// Register a device token with the backend
  /// This method is added for backward compatibility
  Future<void> registerDeviceToken(String token) async {
    return await ApiService().registerDeviceToken(token);
  }

  /// Handle new messages from Firebase
  void _handleNewMessage(Map<String, dynamic> messageData) {
    print('📨 New message event received in NotificationService: $messageData');

    // Set unread status to trigger UI updates
    notificationState.setUnreadStatus(true);

    // Notify listeners about the update
    _notificationUpdateController.add(true);

    // Fetch latest notifications to update state, but only if it's been a while
    _throttledFetchNotifications();
  }

  /// Throttled fetch to prevent excessive API calls
  Future<void> _throttledFetchNotifications() async {
    final now = DateTime.now();
    if (now.difference(_lastFetchTime) < _minimumFetchInterval) {
      print('🔄 Skipping fetch - too soon since last fetch');
      return;
    }

    await fetchNotifications();
  }

  /// Fetch notifications from the API
  Future<void> fetchNotifications() async {
    try {
      final int? userId = await ApiService().getCurrentUserId();
      if (userId == null) {
        print("⚠️ Cannot fetch notifications: No logged-in user");
        return;
      }

      print('🔄 Fetching notifications for user $userId...');
      _lastFetchTime = DateTime.now();

      final response = await ApiService().makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/notifications/',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final notifications = data['notifications'] as List;

        // Cache notifications
        _cachedNotifications = List<Map<String, dynamic>>.from(notifications);

        // Count unread notifications
        final unreadNotifications = notifications
            .where(
                (n) => n['is_read'] == false && n['recipient']['id'] == userId)
            .toList();

        final unreadCount = unreadNotifications.length;
        print('📱 Updated unread count: $unreadCount');

        // Update notification state
        notificationState.setUnreadStatus(unreadCount > 0);

        // Notify listeners
        _notificationUpdateController.add(unreadCount > 0);
      } else {
        print('❌ Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching notifications: $e');
    }
  }

  /// Mark a specific notification as read
  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      print('📱 Marking notification $notificationId as read');

      final requestBody = {
        'notification_ids': [notificationId],
      };

      final response = await ApiService().makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/notifications/mark-read/',
        method: 'POST',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final unreadCount = data['unread_count'] ?? 0;

        // Update notification state
        notificationState.setUnreadStatus(unreadCount > 0);

        // Notify listeners
        _notificationUpdateController.add(unreadCount > 0);

        // Update cached notifications
        await fetchNotifications();
      } else {
        throw Exception(
            'Failed to mark notification as read: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error in markNotificationAsRead: $e');
      throw e;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      print('📱 Marking all notifications as read');

      final requestBody = {
        'mark_all': "true",
      };

      final response = await ApiService().makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/notifications/mark-read/',
        method: 'POST',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        // Update notification state
        notificationState.setUnreadStatus(false);

        // Notify listeners
        _notificationUpdateController.add(false);

        // Update cached notifications
        await fetchNotifications();
      } else {
        throw Exception(
            'Failed to mark all notifications as read: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error marking all as read: $e');
      throw e;
    }
  }

  /// Reset notification service (usually called on logout)
  void reset() {
    print("🧹 Resetting NotificationService...");

    // Clear notification state
    notificationState.setUnreadStatus(false);

    // Clear cached notifications
    _cachedNotifications = [];

    // Reset initialization flag
    _isInitialized = false;

    // Notify listeners
    _notificationUpdateController.add(false);

    print("✅ NotificationService reset completed");
  }

  /// Clean up resources
  void dispose() {
    _notificationUpdateController.close();
  }

  /// Static method for backward compatibility with main.dart
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print('📱 Static background message handler called');
    await firebaseMessagingBackgroundHandler(message);
  }

  Future<void> markConversationAsRead(int userId) async {
    try {
      final response = await ApiService().makeAuthenticatedRequest(
        url: '${ApiService.baseApiUrl}/messages/mark-read/$userId/',
        method: 'POST',
      );

      if (response.statusCode == 200) {
        print("✅ Conversation with $userId marked as read");
        await fetchNotifications(); // Refresh red dot
      } else {
        print("❌ Failed to mark conversation as read: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error in markConversationAsRead: $e");
    }
  }
}

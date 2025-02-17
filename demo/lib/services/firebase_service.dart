import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseMessagingService {
  final Function(String) registerDeviceToken;

  FirebaseMessagingService({required this.registerDeviceToken});

  Future<void> initialize() async {
    try {
      // Request permission
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('🔔 User granted permission: ${settings.authorizationStatus}');

      // Get the token
      String? token = await FirebaseMessaging.instance.getToken();
      print('🔥 FCM Token: $token');

      if (token != null) {
        // Register the token with your backend
        await registerDeviceToken(token);

        // Listen for token refresh
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          print('🔄 FCM Token refreshed: $newToken');
          registerDeviceToken(newToken);
        });
      } else {
        print('❌ Failed to get FCM token');
      }
    } catch (e) {
      print('❌ Error initializing Firebase Messaging: $e');
    }
  }
}

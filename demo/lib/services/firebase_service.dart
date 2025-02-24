import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseMessagingService {
  final Function(String) registerDeviceToken;
  final Function(String senderId, String messageId) onNewMessageReceived;

  FirebaseMessagingService({
    required this.registerDeviceToken,
    required this.onNewMessageReceived,
  });

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

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("📩 Incoming Firebase notification: ${message.data}");

        if (message.data['type'] == 'message') {
          String senderId = message.data['sender_id'];
          String messageId = message.data['message_id'];

          print(
              "📨 New message from sender: $senderId (Message ID: $messageId)");

          // Call the callback to update UI
          onNewMessageReceived(senderId, messageId);
        } else {
          print("ℹ️ Received non-message notification: ${message.data}");
        }
      });
    } catch (e) {
      print('❌ Error initializing Firebase Messaging: $e');
    }
  }
}

import 'package:demo/screens/message_page.dart';
import 'package:demo/screens/map_page.dart';
import 'package:demo/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/feed_page.dart';
import 'screens/register_page.dart';
import 'screens/login_page.dart';
import 'package:firebase_core/firebase_core.dart';

// Color constants
const Color headerColor = Color(0xFFfafafa);
const Color footerColor = Color(0xFFf2f2f2);
const Color whiteColor = Color(0xFFfafafa);
const Color filterPageColor = Color(0xFFfafafa);
const Color gridBackgroundColor = Color(0xFFeeeeee);
const Color greyColor = Color(0xFF486966);
const Color colorLike = Color(0xFF747f7f);
const Color colorLiked = Color(0xFFffad08);
const Color primaryColor = Color(0xFFffad08);
const Color iconColor = Color(0xff1d1d1d);
const Color insertBoxBgColor = Color(0xFFe0e0e0);
const Color insertBoxTextColor = Color(0xFF1d1d1d);

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.handleBackgroundMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // final notificationService = NotificationService();
  // await notificationService.initialize();

  await clearCachedAuth();
  runApp(MyApp());
}

Future<void> clearCachedAuth() async {
  print("🧹 Clearing cached auth data...");
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // Clears stored login tokens
  print("✅ Cached auth data cleared.");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [RouteObserver<PageRoute>()],
      navigatorKey: navigatorKey,
      title: 'My App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xfffadd00)),
        primaryColor: primaryColor,
        scaffoldBackgroundColor: headerColor,
        iconTheme: const IconThemeData(color: iconColor),
      ),
      initialRoute: '/login',
      routes: {
        '/feed': (context) => const FeedPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/map': (context) => const MapTestScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}

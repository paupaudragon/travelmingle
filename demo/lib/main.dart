import 'package:demo/services/api_service.dart';
import 'package:demo/screens/map_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'screens/feed_page.dart';
import 'screens/register_page.dart';
import 'screens/login_page.dart';
import 'package:firebase_core/firebase_core.dart';

const Color headerColor = Color(0xFFfafafa);
const Color footerColor = Color(0xFFfafafa);
const Color filterPageColor = Color(0xFFfafafa);
const Color gridBackgroundColor = Color(0xFFeeeeee);
const Color colorLike = Color(0xFF747f7f);
const Color colorLiked = Color(0xFFffad08);
const Color primaryColor = Color(0xFFffad08);
const Color iconColor = Color(0xff1d1d1d);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  await apiService.initializeCurrentUser();
  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyDSg6nklqNqmsvrBbN6s9kwbLcPmmlanic",
        appId: "1:788833039521:android:1c383bf2dc497e3f222ce0",
        messagingSenderId: "788833039521",
        projectId: "travelmingle-fd7bf",
      ),
    );
    print("✅ Firebase initialized successfully!");
  } catch (e) {
    print("❌ Firebase initialization failed: $e");
  }
  // Get FCM Token
  String? token = await FirebaseMessaging.instance.getToken();
  print("🔥 FCM Token: $token");
  await apiService.registerDeviceToken();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xfffadd00), // Change highlight color globally
        ),
        primaryColor: Color(0xFFffad08),
        scaffoldBackgroundColor: Color(0xFFfafafa), // default background color

        iconTheme: IconThemeData(
          color: Color(0xff1d1d1d), // icon color
        ),
      ),
      initialRoute: '/login', // Set your initial route
      routes: {
        '/auth-check': (context) => const AuthCheck(),
        '/feed': (context) => Builder(
              builder: (context) => Theme(
                data: Theme.of(context).copyWith(
                  scaffoldBackgroundColor: gridBackgroundColor,
                ),
                child: const FeedPage(),
              ),
            ),
        '/login': (context) => const LoginPage(), // Login route
        '/register': (context) => const RegisterPage(), // Register route
        '/map': (context) => MapTestScreen(),
      },
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkAuthStatus();
    ApiService().registerDeviceToken();
  }

  Future<void> checkAuthStatus() async {
    final apiService = ApiService();
    final token = await apiService.getAccessToken();

    setState(() {
      isLoggedIn = token != null;
      isLoading = false;
    });

    // Navigate to the appropriate route
    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/feed');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Display a loading indicator while checking authentication status
    return Scaffold(
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : const Text('Redirecting...'),
      ),
    );
  }
}

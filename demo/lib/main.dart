import 'package:demo/services/api_service.dart';
import 'package:demo/screens/map_page.dart';
import 'package:flutter/material.dart';
import 'screens/feed_page.dart';
import 'screens/register_page.dart';
import 'screens/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  await apiService.initializeCurrentUser();
  runApp(MyApp());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        hintColor: Colors.grey,
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(
            color: Colors.black, // Label text color
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
                color: Colors.blue), // Blue underline when not focused
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
                color: Colors.blue, width: 2), // Blue underline when focused
          ),
          hintStyle: const TextStyle(
            color: Colors.grey, // Hint text color
          ),
        ),
        tabBarTheme: TabBarTheme(
          labelColor: Colors.black, // Selected tab text color
          unselectedLabelColor: Colors.grey, // Unselected tab text color
          indicator: UnderlineTabIndicator(
            borderSide:
                BorderSide(color: Colors.blue, width: 3), // Tab underline
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue, // Elevated button background
            foregroundColor: Colors.black, // Elevated button text color
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.black, // Text button color
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.black, // Floating action button color
        ),
      ),
      initialRoute: '/login', // Set your initial route
      routes: {
        '/auth-check': (context) => const AuthCheck(),
        '/feed': (context) => const FeedPage(), // Home route
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

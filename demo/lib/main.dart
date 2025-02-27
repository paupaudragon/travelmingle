import 'package:demo/services/api_service.dart';
import 'package:demo/screens/map_page.dart';
import 'package:flutter/material.dart';
import 'screens/feed_page.dart';
import 'screens/register_page.dart';
import 'screens/login_page.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  await apiService.initializeCurrentUser();
  runApp(MyApp());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // @override
  // Widget build(BuildContext context) {
  //   return MaterialApp(
  //     title: 'My App',
  //     theme: ThemeData(
  //       primarySwatch: Colors.blue,
  //       scaffoldBackgroundColor: Color(0xFFfafafa),
  //       hintColor: Colors.grey,
  //       inputDecorationTheme: InputDecorationTheme(
  //         labelStyle: const TextStyle(
  //           color: Colors.black, // Label text color
  //         ),
  //         enabledBorder: const UnderlineInputBorder(
  //           borderSide: BorderSide(
  //               color: Colors.blue), // Blue underline when not focused
  //         ),
  //         focusedBorder: const UnderlineInputBorder(
  //           borderSide: BorderSide(
  //               color: Colors.blue, width: 2), // Blue underline when focused
  //         ),
  //         hintStyle: const TextStyle(
  //           color: Colors.grey, // Hint text color
  //         ),
  //       ),
  //       tabBarTheme: TabBarTheme(
  //         labelColor: Colors.black, // Selected tab text color
  //         unselectedLabelColor: Colors.grey, // Unselected tab text color
  //         indicator: UnderlineTabIndicator(
  //           borderSide:
  //               BorderSide(color: Colors.blue, width: 3), // Tab underline
  //         ),
  //       ),
  //       elevatedButtonTheme: ElevatedButtonThemeData(
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: Colors.blue, // Elevated button background
  //           foregroundColor: Colors.black, // Elevated button text color
  //         ),
  //       ),
  //       textButtonTheme: TextButtonThemeData(
  //         style: TextButton.styleFrom(
  //           foregroundColor: Colors.black, // Text button color
  //         ),
  //       ),
  //       floatingActionButtonTheme: FloatingActionButtonThemeData(
  //         backgroundColor: Colors.black, // Floating action button color
  //       ),
  //     ),
  //     initialRoute: '/login', // Set your initial route
  //     routes: {
  //       '/auth-check': (context) => const AuthCheck(),
  //       '/feed': (context) => const FeedPage(), // Home route
  //       '/login': (context) => const LoginPage(), // Login route
  //       '/register': (context) => const RegisterPage(), // Register route
  //       '/map': (context) => MapTestScreen(),
  //     },
  //   );
  // }

  

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

import 'package:flutter/material.dart';
import 'screens/feed_page.dart';
import 'screens/register_page.dart';
import 'screens/login_page.dart';

void main() {
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
      ),
      initialRoute: '/feed', // Set your initial route
      routes: {
        '/feed': (context) => const FeedPage(), // Home route
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(), // Register route
      },
    );
  }
}

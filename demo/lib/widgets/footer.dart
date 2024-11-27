import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  final Function onHomePressed;
  final Function onLogoutPressed;
  final Function onPlusPressed;
  final Function onMessagesPressed;
  final Function onMePressed;

  const Footer({
    Key? key,
    required this.onHomePressed,
    required this.onLogoutPressed,
    required this.onPlusPressed,
    required this.onMessagesPressed,
    required this.onMePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5), // Off-white background color
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Home Button
          IconButton(
            icon: const Icon(Icons.home, size: 28, color: Colors.black),
            onPressed: () => onHomePressed(),
          ),
          // Shop Button
          IconButton(
            icon: const Icon(Icons.logout, size: 28, color: Colors.black),
            onPressed: () => onLogoutPressed(),
          ),

          // "+" Button (Square Design)
          GestureDetector(
            onTap: () => onPlusPressed(),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.orange, // Background color of the "+" button
                borderRadius: BorderRadius.circular(
                    8), // Rounded corners for square button
              ),
              child: const Icon(Icons.add, size: 28, color: Colors.white),
            ),
          ),
          // Messages Button
          IconButton(
            icon: const Icon(Icons.message, size: 28, color: Colors.black),
            onPressed: () => onMessagesPressed(),
          ),
          // Me Button
          IconButton(
            icon: const Icon(Icons.person, size: 28, color: Colors.black),
            onPressed: () => onMePressed(),
          ),
        ],
      ),
    );
  }
}

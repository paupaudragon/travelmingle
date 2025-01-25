import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  final Function onHomePressed;
  final Function onSearchPressed;
  final Function onPlusPressed;
  final Function onMessagesPressed;
  final Function onMePressed;
  final Function onMapPressed;

  const Footer({
    Key? key,
    required this.onHomePressed,
    required this.onSearchPressed,
    required this.onPlusPressed,
    required this.onMessagesPressed,
    required this.onMePressed,
    required this.onMapPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: const Color(0xFFF5F5F5), // Off-white background color
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Home Button
          IconButton(
            icon: const Icon(Icons.home_rounded, size: 28, color: Colors.black),
            onPressed: () => onHomePressed(),
          ),

          IconButton(
            icon:
                const Icon(Icons.search_rounded, size: 28, color: Colors.black),
            onPressed: () => onSearchPressed(),
          ),

          // "+" Button (Square Design)
          GestureDetector(
            onTap: () => onPlusPressed(),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.blue, // Background color of the "+" button
                borderRadius: BorderRadius.circular(
                    8), // Rounded corners for square button
              ),
              child:
                  const Icon(Icons.add_rounded, size: 28, color: Colors.white),
            ),
          ),

          //Messages Button
          IconButton(
            icon: const Icon(Icons.message_rounded,
                size: 28, color: Colors.black),
            onPressed: () => onMessagesPressed(),
          ),

          // Me Button
          IconButton(
            icon:
                const Icon(Icons.person_rounded, size: 28, color: Colors.black),
            onPressed: () => onMePressed(),
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => onMapPressed(),
          ),
        ],
      ),
    );
  }
}

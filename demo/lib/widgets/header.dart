import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final Function onFollowPressed;
  final Function onExplorePressed;
  final Function onNearbyPressed;
  final Function onMenuPressed;
  final Function onSearchPressed;
  final Function onCreateUserPressed; // Add callback for "Create User"

  const Header({
    Key? key,
    required this.onFollowPressed,
    required this.onExplorePressed,
    required this.onNearbyPressed,
    required this.onMenuPressed,
    required this.onSearchPressed,
    required this.onCreateUserPressed, // Add parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 244, 240, 240), // Off-white background color
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Center(
        child: TextButton(
          onPressed: () => onExplorePressed(),
          child: const Text(
            "Explore",
            style: TextStyle(
              color: Colors.orange,
              fontSize: 20, // Highlighted as active
            ),
          ),
        ),
      ),
    );
  }
}

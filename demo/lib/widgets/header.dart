import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final Function onFollowPressed;
  final Function onExplorePressed;
  final Function onNearbyPressed;
  final Function onMenuPressed;
  final Function onSearchPressed;

  const Header({
    Key? key,
    required this.onFollowPressed,
    required this.onExplorePressed,
    required this.onNearbyPressed,
    required this.onMenuPressed,
    required this.onSearchPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5), // Off-white background color
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Menu Icon
          IconButton(
            icon: const Icon(Icons.menu, size: 28, color: Colors.black),
            onPressed: () => onMenuPressed(),
          ),
          // Follow, Explore, Nearby Buttons
          Row(
            children: [
              TextButton(
                onPressed: () => onFollowPressed(),
                child: const Text(
                  "Follow",
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () => onExplorePressed(),
                child: const Text(
                  "Explore",
                  style: TextStyle(color: Colors.orange, fontSize: 16), // Highlighted as active
                ),
              ),
              TextButton(
                onPressed: () => onNearbyPressed(),
                child: const Text(
                  "Nearby",
                  style: TextStyle(color: Colors.black, fontSize: 16), 
                ),
              ),
            ],
          ),
          // Search Icon
          IconButton(
            icon: const Icon(Icons.search, size: 28, color: Colors.black),
            onPressed: () => onSearchPressed(),
          ),
        ],
      ),
    );
  }
}

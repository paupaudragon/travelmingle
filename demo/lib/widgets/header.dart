import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final Function onFollowPressed;
  final Function onExplorePressed;
  final Function onNearbyPressed;
  final Function onMenuPressed;
  final Function onSearchPressed;
  final Function onCreateUserPressed; // Add callback

  const Header({
    Key? key,
    required this.onFollowPressed,
    required this.onExplorePressed,
    required this.onNearbyPressed,
    required this.onMenuPressed,
    required this.onSearchPressed,
    required this.onCreateUserPressed, 
  }) : super(key: key);

  // TODO: move filter button

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFfafafa),
      height: 60,

      // color: const Color.fromARGB(255, 244, 240, 240), // Off-white background color
      child: Center(
        child: TextButton(
          onPressed: () => onExplorePressed(),
          child: const Text(
            "Explore",
            style: TextStyle(
              color: Color(0xffEBC122),
              fontSize: 20, // Highlighted as active
            ),
          ),
        ),
      ),
    );
  }
}

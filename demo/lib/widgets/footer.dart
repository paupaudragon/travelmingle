import 'package:demo/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      color: footerColor, // Off-white background color
      padding: const EdgeInsets.symmetric(vertical: 8),
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Home Button
          Column(
            mainAxisSize: MainAxisSize.min, // Ensure compact layout
            children: [
              SvgPicture.asset(
                'assets/icons/home.svg',
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                    Colors.black, BlendMode.srcIn), // Change color dynamically
              ),
              const SizedBox(height: 2), // Reduce gap between icon and text
              const Text(
                "Home",
                style: TextStyle(
                  fontSize: 10, // Make text smaller
                  fontWeight: FontWeight.w400, // Lighter font weight
                  color: Colors.black, // Text color
                ),
              ),
            ],
          ),

          // map Button
          Column(
            mainAxisSize: MainAxisSize.min, // Ensure compact layout
            children: [
              SvgPicture.asset(
                'assets/icons/map.svg',
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                    Colors.black, BlendMode.srcIn), // Change color dynamically
              ),
              const SizedBox(height: 2), // Reduce gap between icon and text
              const Text(
                "Map",
                style: TextStyle(
                  fontSize: 10, // Make text smaller
                  fontWeight: FontWeight.w400, // Use a lighter font weight
                  color: Colors.black, // Text color
                ),
              ),
            ],
          ),

          // // "+" Button (Square Design)
          // IconButton(
          //   onPressed: () => onPlusPressed(),
          //   padding: EdgeInsets.zero, // Remove default padding
          //   constraints: BoxConstraints(), // Remove default size constraints
          //   icon: SizedBox(
          //     width: 50, // Ensure correct size
          //     height: 50,
          //     child: SvgPicture.asset(
          //       'assets/icons/create.svg',
          //       fit: BoxFit.contain, // Ensure proper scaling
          //       colorFilter: ColorFilter.mode(
          //           primaryColor, BlendMode.srcIn), // Change color dynamically
          //     ),
          //   ),
          // ),

          IconButton(
            onPressed: () => onPlusPressed(),
            padding: EdgeInsets.zero, // Remove default padding
            constraints: BoxConstraints(), // Remove default size constraints
            icon: SizedBox(
              width: 55, // Ensure correct size
              height: 47,
              child: Image.asset(
                'assets/icons/create.png',
                fit: BoxFit
                    .contain, // Ensure proper scaling Change color dynamically
              ),
            ),
          ),

          // Messages Button
          Column(
            mainAxisSize: MainAxisSize.min, // Ensure compact layout
            children: [
              SvgPicture.asset(
                'assets/icons/message.svg',
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                    Colors.black, BlendMode.srcIn), // Change color dynamically
              ),
              const SizedBox(height: 2), // Reduce gap between icon and text
              const Text(
                "Messages",
                style: TextStyle(
                  fontSize: 10, // Make text smaller
                  fontWeight: FontWeight.w400, // Lighter font weight
                  color: Colors.black, // Text color
                ),
              ),
            ],
          ),

          // Me Button
          Column(
            mainAxisSize: MainAxisSize.min, // Ensure compact layout
            children: [
              SvgPicture.asset(
                'assets/icons/me.svg',
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                    Colors.black, BlendMode.srcIn), // Change color dynamically
              ),
              const SizedBox(height: 2), // Reduce gap between icon and text
              const Text(
                "Me",
                style: TextStyle(
                  fontSize: 10, // Make text smaller
                  fontWeight: FontWeight.w400, // Lighter font weight
                  color: Colors.black, // Text color
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

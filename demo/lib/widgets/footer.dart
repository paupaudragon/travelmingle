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
          /// **Home Button**
          GestureDetector(
            onTap: () => onHomePressed(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/home.svg',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
                const SizedBox(height: 1),
                const Text(
                  "Home",
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.black),
                ),
              ],
            ),
          ),

          /// **Map Button**
          GestureDetector(
            onTap: () => onMapPressed(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/map.svg',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
                const SizedBox(height: 1),
                const Text(
                  "Map",
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.black),
                ),
              ],
            ),
          ),

          /// **"+" Button (Create)**
          IconButton(
            onPressed: () => onPlusPressed(),
            padding: EdgeInsets.zero, // Remove default padding
            constraints: BoxConstraints(), // Remove default constraints
            icon: SizedBox(
              width: 55,
              height: 47,
              child: Image.asset(
                'assets/icons/create.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          /// **Messages Button**
          GestureDetector(
            onTap: () => onMessagesPressed(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/message.svg',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
                const SizedBox(height: 1),
                const Text(
                  "Messages",
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.black),
                ),
              ],
            ),
          ),

          /// **Me Button**
          GestureDetector(
            onTap: () => onMePressed(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/me.svg',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
                const SizedBox(height: 1),
                const Text(
                  "Me",
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

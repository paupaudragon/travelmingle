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
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/home.svg',
              width: 22,
              height: 22,
            ),
            onPressed: () => onHomePressed(),
          ),

          // map Button
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/map.svg',
              width: 22,
              height: 22,
            ),
            onPressed: () => onMapPressed(),
          ),

          // "+" Button (Square Design)
          GestureDetector(
            onTap: () => onPlusPressed(),
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .primaryColor, // Background color of the "+" button
                borderRadius: BorderRadius.circular(
                    8), // Rounded corners for square button
              ),
              child:
                  const Icon(Icons.add_rounded, size: 28, color: Colors.white),
            ),
          ),

          //Messages Button
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/message.svg',
              width: 22,
              height: 22,
            ),
            onPressed: () => onMessagesPressed(),
          ),

          // Me Button
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/me.svg',
              width: 22,
              height: 22,
            ),
            onPressed: () => onMePressed(),
          ),
        ],
      ),
    );
  }
}

import 'package:demo/main.dart';
import 'package:demo/services/notification_service.dart';
import 'package:demo/widgets/message_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Footer extends StatelessWidget {
  final Function onHomePressed;
  final Function onPlusPressed;
  final Function onMessagesPressed;
  final Function onMePressed;
  // final Function onMapPressed;
  final Function onSearchPressed;
  final bool hasUnreadMessages;

  const Footer({
    Key? key,
    required this.onHomePressed,
    required this.onPlusPressed,
    required this.onMessagesPressed,
    required this.onMePressed,
    // required this.onMapPressed,
    required this.onSearchPressed,
    required this.hasUnreadMessages, // Fix: add this. to assign to the property
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
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
                const SizedBox(height: 1),
                const Text(
                  "Home",
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: iconColor),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onSearchPressed(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/search.svg',
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
                const SizedBox(height: 1),
                const Text(
                  "Search",
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: iconColor),
                ),
              ],
            ),
          ),

          /// **"+" Button (Create)**
          Transform.translate(
            offset: Offset(0, -1),
            child: IconButton(
              onPressed: () => onPlusPressed(),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
              icon: SizedBox(
                width: 55,
                height: 47,
                child: Image.asset(
                  'assets/icons/create.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // Pass hasUnreadMessages to MessageIconWithStatus
          MessageIconWithStatus(
            onTap: () {
              print("📩 Message icon clicked - Fetching notifications...");
              NotificationService()
                  .fetchNotifications(); // ✅ Updates unread count
              onMessagesPressed(); // ✅ Navigates to the messages page
            },
            iconColor: iconColor,
            hasUnread: hasUnreadMessages, // Pass the property here
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
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
                const SizedBox(height: 1),
                const Text(
                  "Me",
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: iconColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

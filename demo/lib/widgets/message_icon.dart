import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MessageIconWithStatus extends StatelessWidget {
  final VoidCallback onTap;
  final Color iconColor;
  final bool hasUnread;

  // We no longer need to instantiate the NotificationState here
  // since we're now using the passed value directly

  const MessageIconWithStatus({
    Key? key,
    required this.onTap,
    required this.iconColor,
    required this.hasUnread,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the passed hasUnread prop directly
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SvgPicture.asset(
                'assets/icons/message.svg',
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
              // Show red dot for unread messages
              if (hasUnread) // Use the prop here
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            "Messages",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}

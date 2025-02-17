import 'package:demo/services/notification_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MessageIconWithStatus extends StatelessWidget {
  final VoidCallback onTap;
  final Color iconColor;
  final NotificationState _notificationState =
      NotificationState(); // ✅ Use Singleton

  MessageIconWithStatus({
    Key? key,
    required this.onTap,
    required this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream:
          _notificationState.hasUnreadStream, // ✅ Use the singleton instance
      initialData: _notificationState.hasUnread, // ✅ Use the singleton instance
      builder: (context, snapshot) {
        final hasUnread = snapshot.data ?? false;

        return GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/message.svg',
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                    hasUnread ? Colors.red : iconColor, BlendMode.srcIn),
              ),
              const SizedBox(height: 1),
              Text(
                "Messages",
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: iconColor),
              ),
            ],
          ),
        );
      },
    );
  }
}

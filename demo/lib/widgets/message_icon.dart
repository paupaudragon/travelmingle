import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/notification_state.dart';

class MessageIconWithStatus extends StatelessWidget {
  final VoidCallback onTap;
  final Color iconColor;

  const MessageIconWithStatus({
    Key? key,
    required this.onTap,
    required this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: NotificationState().hasUnreadStream,
      initialData: NotificationState().hasUnread,
      builder: (context, snapshot) {
        final hasUnread = snapshot.data ?? false;
        print('Message icon state - hasUnread: $hasUnread'); // Debug log

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

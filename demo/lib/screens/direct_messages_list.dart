import 'package:demo/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:demo/screens/message_detail_page.dart';
import 'package:demo/services/api_service.dart';
import 'package:intl/intl.dart';

class DirectMessagesList extends StatelessWidget {
  final List<dynamic> messages;
  final Function(dynamic) onMessageTap;
  final int currentUserId;
  final VoidCallback? onRefreshRequested;

  const DirectMessagesList({
    Key? key,
    required this.messages,
    required this.onMessageTap,
    required this.currentUserId,
    this.onRefreshRequested,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final int senderId = message['sender'];
        final int receiverId = message['receiver'];
        final String content = message['content'] ?? '';
        final String timestamp = message['timestamp'] ?? '';
        final bool isRead = message['is_read'] == true;
        final chatPartnerId = currentUserId == senderId ? receiverId : senderId;

        // Only show unread indicator if:
        // 1. The message is not read AND
        // 2. The current user is the RECEIVER (not the sender)
        // This ensures we only show red dots for messages sent TO the current user
        final bool shouldShowUnreadIndicator =
            !isRead && senderId != currentUserId;

        // Debug unread status
        print(
            'Message ${message['id']} isRead: $isRead, senderId: $senderId, currentUserId: $currentUserId, shouldShowUnread: $shouldShowUnreadIndicator');

        return FutureBuilder<Map<String, dynamic>>(
          future: ApiService().fetchUserProfile(chatPartnerId),
          builder: (context, snapshot) {
            final username = snapshot.data?['username'] ?? "User";
            final avatar = snapshot.data?['profile_picture_url'] ?? "";

            return Dismissible(
              key: Key('${message['id']}_$index'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                color: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.mark_email_read, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                // Show confirmation dialog
                final confirmed = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Mark Conversation as Read'),
                    content:
                        const Text('Mark all messages from this user as read?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      ElevatedButton(
                        child: const Text('Mark as Read'),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  // Use the updated markConversationAsRead method which returns a bool
                  final success = await NotificationService()
                      .markConversationAsRead(chatPartnerId);

                  if (success) {
                    // If successful, fetch notifications and refresh UI
                    await NotificationService().fetchNotifications();

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Conversation with $username marked as read'),
                        duration: Duration(seconds: 2),
                      ),
                    );

                    // Call refresh callback
                    if (onRefreshRequested != null) {
                      onRefreshRequested!();
                    }
                  } else {
                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to mark conversation as read'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }

                // Always return false to prevent dismissal
                return false;
              },
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: avatar.isNotEmpty
                      ? NetworkImage(avatar)
                      : AssetImage('assets/images/default_avatar.png')
                          as ImageProvider,
                ),
                title: Text(username),
                subtitle:
                    Text(content, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(timestamp),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 6),
                    // Show red dot only if message is not read AND sent TO the current user
                    if (shouldShowUnreadIndicator)
                      const CircleAvatar(
                        radius: 4,
                        backgroundColor: Colors.red,
                      ),
                  ],
                ),
                onTap: () => onMessageTap(message),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat.jm().format(date);
    } catch (e) {
      return "";
    }
  }
}

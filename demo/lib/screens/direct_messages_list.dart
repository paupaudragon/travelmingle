import 'package:flutter/material.dart';
import 'package:demo/screens/message_detail_page.dart';

class DirectMessagesList extends StatelessWidget {
  final List<dynamic> messages;
  final Function(dynamic) onMessageTap;
  final int currentUserId; // ✅ Pass current user ID

  const DirectMessagesList({
    Key? key,
    required this.messages,
    required this.onMessageTap,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final int senderId =
            message['sender']; // ✅ FIX: Ensure sender ID is correct
        final int receiverId =
            message['receiver']; // ✅ FIX: Ensure receiver ID is correct
        final String content = message['content'] ?? '';
        final String timestamp = message['timestamp'] ?? '';

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(message['sender_avatar'] ?? ''),
          ),
          title: Text("User $senderId"),
          subtitle: Text(content),
          trailing: Text(timestamp),
          onTap: () {
            // ✅ Ensure correct chat navigation (chat partner should NOT be the current user)
            final chatPartnerId =
                currentUserId == senderId ? receiverId : senderId;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MessageDetailPage(userId: chatPartnerId),
              ),
            );
          },
        );
      },
    );
  }
}

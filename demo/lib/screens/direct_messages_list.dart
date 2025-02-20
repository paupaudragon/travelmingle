import 'package:flutter/material.dart';
import 'package:demo/screens/message_detail_page.dart';

class DirectMessagesList extends StatelessWidget {
  final List<dynamic> messages;
  final Function(dynamic) onMessageTap;

  const DirectMessagesList({
    Key? key,
    required this.messages,
    required this.onMessageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final sender = message['sender'];
        final receiver = message['receiver'];
        final content = message['content'] ?? '';
        final timestamp = message['timestamp'] ?? message['created_at'] ?? '';

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(sender?['avatar'] ?? ''),
          ),
          title: Text(sender?['username'] ?? 'Unknown'),
          subtitle: Text(content),
          trailing: Text(timestamp),
          onTap: () {
            final chatPartnerId = sender['id'];  // Navigate to chat with sender

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

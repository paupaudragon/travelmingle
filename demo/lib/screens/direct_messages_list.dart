import 'package:flutter/material.dart';

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
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(message['sender']?['avatar'] ?? ''),
          ),
          title: Text(message['sender']?['username'] ?? 'Unknown'),
          subtitle: Text(message['message'] ?? ''),
          trailing: Text(message['created_at'] ?? ''),
          onTap: () => onMessageTap(message),
        );
      },
    );
  }
}

class Message {
  final int id;
  final int sender;  // ✅ FIXED: Use integer, not a map
  final int receiver;
  final String content;
  final String timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.content,
    required this.timestamp,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      sender: json['sender'],  // ✅ FIXED: Integer value
      receiver: json['receiver'],  // ✅ FIXED: Integer value
      content: json['content'],
      timestamp: json['timestamp'],
      isRead: json['is_read'],  // ✅ FIXED: Boolean value
    );
  }
}

import 'dart:async';
import 'package:demo/models/message_model.dart';
import 'package:demo/services/firebase_service.dart';
import 'package:demo/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:demo/services/api_service.dart';

class MessageDetailPage extends StatefulWidget {
  final int userId; // The user you are chatting with

  const MessageDetailPage({Key? key, required this.userId}) : super(key: key);

  @override
  _MessageDetailPageState createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> messages = [];
  bool _isLoading = true;
  bool _sendingMessage = false;

  // Stream subscriptions
  StreamSubscription? _firebaseMessageSubscription;

  @override
  void initState() {
    super.initState();

    // Initial fetch of messages
    _fetchMessages();

    // Listen for new messages from Firebase
    _firebaseMessageSubscription =
        FirebaseMessagingService().messageStream.listen(_handleFirebaseMessage);
  }

  @override
  void dispose() {
    // Clean up subscriptions
    _firebaseMessageSubscription?.cancel();

    // Clean up controllers
    _scrollController.dispose();
    _messageController.dispose();

    super.dispose();
  }

  // Handle new messages from Firebase
  void _handleFirebaseMessage(Map<String, dynamic> messageData) {
    final senderId = messageData['sender_id'];
    final messageId = messageData['message_id'];

    print("🔔 Message event in chat: sender $senderId, message ID: $messageId");

    // Only refresh if this message is from the user we're chatting with
    if (senderId == widget.userId.toString()) {
      if (mounted) {
        print("🔄 Refreshing messages for this chat");
        _fetchMessages();
      }
    }
  }

  Future<void> _fetchMessages() async {
    try {
      // Ensure current user ID is available
      if (_apiService.currentUserId == null) {
        await _apiService.getCurrentUserId();
      }

      List<Message> fetchedMessages =
          await _apiService.fetchMessages(widget.userId);

      if (mounted) {
        setState(() {
          messages = fetchedMessages
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _isLoading = false;
        });
      }

      // Scroll to bottom after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

      // We no longer automatically mark messages as read when viewing the conversation
      // This fixes the issue where the red dot disappears without the backend being updated
    } catch (e) {
      print("Error fetching messages: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // This method is now only called when explicitly requested by the user
  Future<void> _markMessagesAsRead() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('Marking conversation as read...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );

      // Call the API to mark the conversation as read
      final success =
          await NotificationService().markConversationAsRead(widget.userId);

      if (success) {
        // Update global notification status
        await NotificationService().fetchNotifications();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conversation marked as read'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
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
    } catch (e) {
      print("Error marking messages as read: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() => _sendingMessage = true);

    try {
      await _apiService.sendMessage(
          widget.userId, _messageController.text.trim());

      _messageController.clear();
      await _fetchMessages(); // Refresh message list after sending
    } catch (e) {
      print("Error sending message: $e");
    }

    setState(() => _sendingMessage = false);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isSender = message.sender == _apiService.currentUserId;

        return Align(
          alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: BoxDecoration(
              color: isSender ? Colors.grey : Colors.blueAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style:
                      TextStyle(color: isSender ? Colors.white : Colors.black),
                ),
                Text(
                  _formatTimestamp(message.timestamp),
                  style: TextStyle(
                    color: isSender ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        actions: [
          // Add explicit button to mark conversation as read
          IconButton(
            icon: Icon(Icons.mark_email_read),
            onPressed: _markMessagesAsRead,
            tooltip: 'Mark conversation as read',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: _sendingMessage
                ? const CircularProgressIndicator()
                : const Icon(Icons.send, color: Colors.blue),
            onPressed: _sendingMessage ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}

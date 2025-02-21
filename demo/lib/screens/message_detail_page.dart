import 'dart:async';
import 'dart:convert';
import 'package:demo/models/message_model.dart';
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
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _fetchMessages(); // ✅ Fetch messages every 5 seconds
    });
  }

  Future<void> _fetchMessages() async {
    try {
      List<Message> fetchedMessages =
          await _apiService.fetchMessages(widget.userId);

      if (mounted) {
        setState(() {
          messages = fetchedMessages;
          _isLoading = false; // ✅ Update loading state
        });
      }

      // Scroll to bottom after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

      _markMessagesAsRead(); // Automatically mark as read after fetching
    } catch (e) {
      print("Error fetching messages: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markMessagesAsRead() async {
    try {
      for (var message in messages) {
        if (!message.isRead == false) {
          // ❌ Incorrect: message['is_read']
          await _apiService.markMessageAsRead(message.id);
        }
      }
    } catch (e) {
      print("Error marking messages as read: $e");
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

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isSender = message.sender ==
            _apiService.currentUserId; // ✅ FIXED: Compare integers directly

        return Align(
          alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            decoration: BoxDecoration(
              color: isSender ? Colors.grey[300] : Colors.blueAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content, // ✅ FIXED: Directly access 'content'
                  style:
                      TextStyle(color: isSender ? Colors.white : Colors.black),
                ),
                // Text(
                //   message.timestamp, // ✅ FIXED: Corrected timestamp access
                //   style: TextStyle(
                //     color: isSender ? Colors.white70 : Colors.black54,
                //     fontSize: 10,
                //   ),
                // ),
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
      appBar: AppBar(title: const Text("Chat")),
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

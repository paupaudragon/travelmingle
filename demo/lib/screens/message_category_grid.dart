import 'package:demo/models/message_category.dart';
import 'package:flutter/material.dart';

class MessageCategoryGrid extends StatelessWidget {
  final List<NotificationCategory> categories;
  final Function(NotificationCategory) onCategorySelected;

  const MessageCategoryGrid({
    Key? key,
    required this.categories,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: categories
            .map((category) => _buildCategoryButton(context, category))
            .toList(),
      ),
    );
  }

  Widget _buildCategoryButton(
      BuildContext context, NotificationCategory category) {
    return InkWell(
      onTap: () => onCategorySelected(category),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: category.hasUnread ? Colors.red : Colors.grey[800],
              shape: BoxShape.circle,
            ),
            child: Icon(
              category.icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

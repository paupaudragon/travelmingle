// message_category.dart
import 'package:demo/enums/notification_types.dart';
import 'package:flutter/material.dart';

enum UICategoryType { likesAndCollects, follows, comments }

class NotificationCategory {
  final String name;
  final IconData icon;
  final UICategoryType uiType;
  final List<NotificationType> includedTypes;
  final bool hasUnread;
  final List<dynamic> items;

  const NotificationCategory({
    required this.name,
    required this.icon,
    required this.uiType,
    required this.includedTypes,
    this.hasUnread = false,
    this.items = const [],
  });

  static List<NotificationCategory> getDefaultCategories() {
    return [
      const NotificationCategory(
        name: 'Likes & Collects',
        icon: Icons.favorite,
        uiType: UICategoryType.likesAndCollects,
        includedTypes: [
          NotificationType.likePost,
          NotificationType.likeComment,
          NotificationType.collect
        ],
      ),
      const NotificationCategory(
        name: 'New Followers',
        icon: Icons.person,
        uiType: UICategoryType.follows,
        includedTypes: [NotificationType.follow],
      ),
      const NotificationCategory(
        name: 'Comments & @',
        icon: Icons.chat_bubble,
        uiType: UICategoryType.comments,
        includedTypes: [
          NotificationType.comment,
          NotificationType.reply,
          NotificationType.mention
        ],
      ),
    ];
  }

  NotificationCategory copyWith({
    String? name,
    IconData? icon,
    UICategoryType? uiType,
    List<NotificationType>? includedTypes,
    bool? hasUnread,
    List<dynamic>? items,
  }) {
    return NotificationCategory(
      name: name ?? this.name,
      icon: icon ?? this.icon,
      uiType: uiType ?? this.uiType,
      includedTypes: includedTypes ?? this.includedTypes,
      hasUnread: hasUnread ?? this.hasUnread,
      items: items ?? this.items,
    );
  }

  static NotificationType? typeFromString(String? notificationType) {
    switch (notificationType) {
      case 'like_post':
        return NotificationType.likePost;
      case 'like_comment':
        return NotificationType.likeComment;
      case 'comment':
        return NotificationType.comment;
      case 'reply':
        return NotificationType.reply;
      case 'mention':
        return NotificationType.mention;
      case 'collect':
        return NotificationType.collect;
      case 'follow':
        return NotificationType.follow;
      default:
        print('📱 Unhandled notification type: $notificationType');
        return null;
    }
  }

  // Method to update categories with notifications
  static List<NotificationCategory> updateWithNotifications(
    List<NotificationCategory> categories,
    List<dynamic> notifications,
  ) {
    // Create a map for categorizing notifications
    Map<UICategoryType, List<dynamic>> groupedNotifications = {};

    // Initialize empty lists for each category
    for (var category in categories) {
      groupedNotifications[category.uiType] = [];
    }

    // Print all notification types for debugging
    notifications.forEach((notification) {
      // print(
      //     '📱 Processing notification type: ${notification['notification_type']}');
    });

    // Group notifications by UI category
    for (var notification in notifications) {
      final type = typeFromString(notification['notification_type']);
      if (type != null) {
        // Find which category this type belongs to
        final category = categories.firstWhere(
          (cat) => cat.includedTypes.contains(type),
          orElse: () => categories.first,
        );

        // print(
        //     '📱 Adding ${notification['notification_type']} to ${category.name}');
        groupedNotifications[category.uiType]!.add(notification);
      }
    }

    // Update each category with its notifications
    return categories.map((category) {
      final categoryNotifications = groupedNotifications[category.uiType] ?? [];

      // Sort by timestamp
      categoryNotifications.sort((a, b) {
        final aTime = DateTime.parse(a['created_at']);
        final bTime = DateTime.parse(b['created_at']);
        return bTime.compareTo(aTime);
      });

      print(
          '📱 ${category.name} has ${categoryNotifications.length} notifications');

      return category.copyWith(
        items: categoryNotifications,
        hasUnread:
            categoryNotifications.any((item) => item['is_read'] == false),
      );
    }).toList();
  }
}

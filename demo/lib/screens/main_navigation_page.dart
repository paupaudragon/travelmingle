import 'package:demo/widgets/footer.dart';
import 'package:flutter/material.dart';
import 'package:demo/screens/feed_page.dart';
import 'package:demo/screens/profile_page.dart';
import 'package:demo/screens/message_page.dart';
import 'package:demo/screens/search_page.dart';
import 'package:demo/screens/create_post.dart';
import 'package:demo/services/notification_service.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({Key? key}) : super(key: key);

  @override
  State<MainNavigationPage> createState() => MainNavigationPageState();
}

class MainNavigationPageState extends State<MainNavigationPage> {
  int selectedIndex = 0;
  bool hasUnread = false;

  final List<Widget> _pages = const [
    FeedPage(showFooter: false),
    SearchPage(showFooter: false),
    CreatePostPage(showFooter: false),
    NotificationsScreen(showFooter: false),
    ProfilePage(showFooter: false),
  ];

  @override
  void initState() {
    super.initState();
    _listenToNotificationUpdates();
  }

  void _listenToNotificationUpdates() {
    NotificationService().notificationUpdateStream.listen((unread) {
      if (mounted) {
        setState(() {
          hasUnread = unread;
        });
      }
    });
  }

  void switchTab(int index) {
    if (selectedIndex == index) return;
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[selectedIndex],
      bottomNavigationBar: Footer(
        onHomePressed: () => switchTab(0),
        onSearchPressed: () => switchTab(1),
        onPlusPressed: () => switchTab(2),
        onMessagesPressed: () => switchTab(3),
        onMePressed: () => switchTab(4),
        hasUnreadMessages: hasUnread,
      ),
    );
  }
}

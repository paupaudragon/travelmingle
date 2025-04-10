import 'dart:async';

import 'package:demo/main.dart';
import 'package:demo/screens/S3Test.dart';
import 'package:demo/screens/create_post.dart';
import 'package:demo/screens/main_navigation_page.dart';
import 'package:demo/screens/map_page.dart';
import 'package:demo/screens/message_page.dart';
import 'package:demo/screens/post_page.dart';
import 'package:demo/screens/profile_page.dart';
import 'package:demo/screens/search_page.dart';
import 'package:demo/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../services/api_service.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

Widget buildFooter(BuildContext context, bool hasUnread) {
  return Footer(
    onHomePressed: () {
      Navigator.popUntil(context, (route) => route.isFirst);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context
            .findAncestorStateOfType<MainNavigationPageState>()
            ?.switchTab(0);
      });
    },
    onSearchPressed: () {
      Navigator.popUntil(context, (route) => route.isFirst);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context
            .findAncestorStateOfType<MainNavigationPageState>()
            ?.switchTab(1);
      });
    },
    onPlusPressed: () {
      Navigator.popUntil(context, (route) => route.isFirst);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context
            .findAncestorStateOfType<MainNavigationPageState>()
            ?.switchTab(2);
      });
    },

    onMessagesPressed: () {
      Navigator.popUntil(context, (route) => route.isFirst);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context
            .findAncestorStateOfType<MainNavigationPageState>()
            ?.switchTab(3);
      });
    },
    onMePressed: () {
      Navigator.popUntil(context, (route) => route.isFirst);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context
            .findAncestorStateOfType<MainNavigationPageState>()
            ?.switchTab(4);
      });
    },
    hasUnreadMessages: hasUnread,
  );
}

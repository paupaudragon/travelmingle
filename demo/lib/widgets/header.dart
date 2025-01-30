import 'package:demo/main.dart';
import 'package:demo/screens/feed_page.dart';
import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final Function onFollowPressed;
  final Function onExplorePressed;
  final Function onNearbyPressed;
  final Function onMenuPressed;
  final Function onSearchPressed;
  final Function onCreateUserPressed; // Add callback
  final Function onFilterPressed; // Add callback

  const Header({
    Key? key,
    required this.onFollowPressed,
    required this.onExplorePressed,
    required this.onNearbyPressed,
    required this.onMenuPressed,
    required this.onSearchPressed,
    required this.onCreateUserPressed,
    required this.onFilterPressed, // Add callback
  }) : super(key: key);

  // TODO: move filter button

  @override
 Widget build(BuildContext context) {
  return Container(
    height: 60,
    padding: EdgeInsets.only(top: 10), // inside top margin
    decoration: BoxDecoration(
      color: headerColor,
      border: Border(
        bottom: BorderSide(
          color: const Color.fromARGB(141, 158, 158, 158),
          width: 1,
        ),
      ),
    ),
    child: Stack(
      children: [
        Center(
          child: TextButton(
            onPressed: () => onExplorePressed(),
            child: Text(
              "Explore",
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          ),
        ),

        // search icon
        Positioned(
          right: 10,
          top: 3,
          child: IconButton(
            icon: const Icon(Icons.search_rounded, size: 28),
            onPressed: () => onSearchPressed(),
          ),
        ),

        // filter icon
        Positioned(
          left: 10,
          top: 3,
          child: IconButton(
                icon: const Icon(Icons.filter_list, size: 24),
                onPressed: (){},
                tooltip: 'Filter by Categories',
              ),
        ),
      ],
    ),
  );
}
}

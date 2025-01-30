import 'package:demo/main.dart';
import 'package:demo/screens/feed_page.dart';
import 'package:flutter/material.dart';
import 'circle_tab_indicator.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Header extends StatelessWidget {
  final Function onFollowPressed;
  final Function onExplorePressed;
  final Function onNearbyPressed;
  final Function onMenuPressed;
  final Function onSearchPressed;
  final Function onCreateUserPressed; // Callback for creating a user
  final Function onFilterPressed; // Callback for filter action

  const Header({
    Key? key,
    required this.onFollowPressed,
    required this.onExplorePressed,
    required this.onNearbyPressed,
    required this.onMenuPressed,
    required this.onSearchPressed,
    required this.onCreateUserPressed,
    required this.onFilterPressed, // Callback for filter action
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      padding: EdgeInsets.only(top: 10), // Inside top margin
      decoration: BoxDecoration(
        color: headerColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Filter icon
          Positioned(
            left: 10,
            top: 4,
            child: IconButton(
              icon: SvgPicture.asset(
              'assets/icons/filter.svg',
              width: 22,
              height: 22,
            ),
              onPressed: () => onFilterPressed(),
              tooltip: 'Filter by Categories',
            ),
          ),

          SizedBox(
            width: 220, // Set width
            height: 35,
            child: DefaultTabController(
              length: 3,
              initialIndex: 1,
              child: TabBar(
                labelColor: Colors.black, // Color of selected tab
                unselectedLabelColor: Colors.grey, // Color of unselected tab
                dividerColor: Colors.transparent, // Hide divider line
                indicator: CircleTabIndicator(
                    color: colorLiked, radius: 3), // Custom dot indicator
                labelPadding:
                    EdgeInsets.symmetric(horizontal: 3.0), // Reduce tab spacing
                labelStyle: TextStyle(
                  fontSize: 14, // Adjust font size
                  fontWeight: FontWeight.w500, // Make text thinner
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w400, // Keep unselected text thin as well
                ),
                tabs: const [
                  Tab(text: "Follow"),
                  Tab(text: "Explore"),
                  Tab(text: "Nearby"),
                ],
              ),
            ),
          ),

          // Search icon
          Positioned(
            right: 10,
            top: 3,
            child: IconButton(
              icon: SvgPicture.asset(
              'assets/icons/search.svg',
              width: 22,
              height: 22,
            ),
              onPressed: () => onSearchPressed(),
            ),
          ),
        ],
      ),
    );
  }
}

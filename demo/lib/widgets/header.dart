import 'package:demo/main.dart';
import 'package:flutter/material.dart';
import 'circle_tab_indicator.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Header extends StatelessWidget {
  final Function onFollowPressed;
  final Function onExplorePressed;
  final Function onNearbyPressed;
  final Function onSearchPressed;
  final Function onCreateUserPressed; // Callback for creating a user
  final Function onFilterPressed; // Callback for filter action
  final bool isLoading;
  final String currentSource;

  const Header({
    Key? key,
    required this.onFollowPressed,
    required this.onExplorePressed,
    required this.onNearbyPressed,
    required this.onSearchPressed,
    required this.onCreateUserPressed,
    required this.onFilterPressed, // Callback for filter action
    this.isLoading = false,
    this.currentSource = "explore",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int initialIndex;
    switch (currentSource) {
      case "follow":
        initialIndex = 0;
        break;
      case "nearby":
        initialIndex = 2;
        break;
      default:
        initialIndex = 1; // explore
    }
    return Container(
      height: 65,
      padding: EdgeInsets.only(top: 10), // Inside top margin
      decoration: BoxDecoration(
        color: headerColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 50), // Small spacing between filter and tabs
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
                onTap: (index) {
                  switch (index) {
                    case 0:
                      onFollowPressed();
                      break;
                    case 1:
                      onExplorePressed();
                      break;
                    case 2:
                      onNearbyPressed();
                      break;
                  }
                },
              ),
            ),
          ),

          // Filter icon
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/filter.svg',
              width: 22,
              height: 22,
            ),
            onPressed: () => onFilterPressed(),
            tooltip: 'Filter by Categories',
          ),
        ],
      ),
    );
  }
}

import 'package:demo/models/post_model.dart';
import 'package:flutter/material.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final List<Post> childPosts;
  final int currentDayIndex;
  final Function(int) onDaySelected;

  ProgressIndicatorWidget(
      {required this.childPosts, required this.currentDayIndex, required this.onDaySelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: currentDayIndex > 0
              ? () => onDaySelected(currentDayIndex - 1)
              : null,
        ),
        Row(
          children: List.generate(childPosts.length, (index) {
            return GestureDetector(
              onTap: () => onDaySelected(index),
              child: CircleAvatar(
                radius: 10,
                backgroundColor:
                    index == currentDayIndex ? Colors.blue : Colors.grey[300],
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        index == currentDayIndex ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }),
        ),
        IconButton(
          icon: Icon(Icons.arrow_forward),
          onPressed: currentDayIndex < childPosts.length - 1
              ? () => onDaySelected(currentDayIndex + 1)
              : null,
        ),
      ],
    );
  }
}

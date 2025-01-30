import 'package:flutter/material.dart';

class CircleTabIndicator extends Decoration {
  final Color color; // Color of the dot
  final double radius; // Radius of the dot

  const CircleTabIndicator({required this.color, required this.radius});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CirclePainter(color: color, radius: radius);
  }
}

class _CirclePainter extends BoxPainter {
  final Color color;
  final double radius;

  _CirclePainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Paint paint = Paint()
      ..color = color
      ..isAntiAlias = true;

    // Calculate the position of the dot
    final Offset circleOffset = Offset(
      offset.dx + configuration.size!.width / 2, // Horizontally centered
      configuration.size!.height - radius, // Vertically at the bottom
    );

    // Draw the dot
    canvas.drawCircle(circleOffset, radius, paint);
  }
}
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingAnimation extends StatelessWidget {
  final double size;

  const LoadingAnimation({Key? key, this.size = 200}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/animations/loading.json',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

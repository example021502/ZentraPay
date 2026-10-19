import 'package:flutter/material.dart';

class BouncingLogo extends StatefulWidget {
  const BouncingLogo({super.key});

  @override
  State<BouncingLogo> createState() => _BouncingLogoState();
}

class _BouncingLogoState extends State<BouncingLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _translateAnimation;

  // Maximum height the container moves up (in pixels)
  final double _translateHeight = 50.0;

  @override
  void initState() {
    super.initState();

    // Set up the animation controller to play once and stop
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Smooth upward trajectory that decelerates as it reaches the top
    _translateAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    // Start the animation to move upward and stop at the final position
    _controller.forward();
  }

  @override
  void dispose() {
    // Always dispose controllers to avoid memory leaks
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Value ranges from 0.0 (start) to 1.0 (final top resting position)
          final double value = _translateAnimation.value;
          final double currentTranslateY = -value * _translateHeight;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Translates upward and remains fixed at currentTranslateY
              Transform.translate(
                offset: Offset(0, currentTranslateY),
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 70,
                    maxHeight: 70,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    "images/logo.jpg",
                    alignment: Alignment.center,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

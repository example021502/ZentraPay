import 'package:flutter/material.dart';

class BouncingLogo extends StatefulWidget {
  const BouncingLogo({super.key});

  @override
  State createState() => _BouncingLogoState();
}

class _BouncingLogoState extends State with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation _bounceAnimation;

  // Maximum height the container bounces up (in pixels)
  final double _bounceHeight = 100.0;

  @override
  void initState() {
    super.initState();

    // Set up the animation controller for continuous looping
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Bounce trajectory using easeOut to rise smoothly and bounceOut to fall
    _bounceAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
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
          // Value ranges from 0.0 (ground) to 1.0 (peak apex)
          final double value = _bounceAnimation.value;
          final double currentTranslateY = -value * _bounceHeight;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Bouncing Container / Image / Icon
              Transform.translate(
                offset: Offset(0, currentTranslateY),
                child: Container(
                  constraints: BoxConstraints(maxWidth: 100, maxHeight: 100),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(200),
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
              // GAP BETWEEN THE SHADOW AND THE LOGO
              const SizedBox(height: 5),

              // 2. Dynamic Floor Shadow (Scales down and fades as object rises)
              Opacity(
                opacity: (1.0 - value * 0.7).clamp(0.2, 1.0),
                child: Transform.scale(
                  scaleX: (1.0 - value * 0.5).clamp(0.4, 1.0),
                  child: Container(
                    width: 70,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(200),
                    ),
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

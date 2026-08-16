import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

import 'app_theme.dart';

/// The layered, "peeking" hero card used at the top of the Home section
/// (see `home_header.dart`): two gradient layers peek out behind a rounded
/// main card. Wrapping any screen's top/hero card in this gives it the same
/// visual identity as the Home balance card, while the caller keeps its own
/// content (title row, balances, actions, ...) inside [child].
class ZentraHeroCard extends StatelessWidget {
  final Widget child;

  const ZentraHeroCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bottom-most peeking layer
          Positioned(
            top: -12,
            left: 16,
            right: 16,
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.main.withAlpha(100),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withAlpha(150),
                    width: 3,
                  ),
                ),
              ),
            ),
          ),
          // Middle peeking layer
          Positioned(
            top: -6,
            left: 8,
            right: 8,
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.main.withAlpha(180),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withAlpha(220),
                    width: 3.5,
                  ),
                ),
              ),
            ),
          ),
          // Main foreground card
          Container(
            decoration: AppTheme.coloredCardDecoration(
              AppColors.main,
            ).copyWith(gradient: AppTheme.primaryGradient),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 15.0,
                horizontal: 20,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

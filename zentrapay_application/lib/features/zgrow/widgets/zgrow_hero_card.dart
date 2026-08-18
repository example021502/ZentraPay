import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/main.dart';

/// Pink hero card: headline, total savings (real, listens to
/// SavingsRepository), and the "Save Now" entry into MilestonesScreen.
class ZGrowHeroCard extends StatelessWidget {
  const ZGrowHeroCard({super.key});

  final savings = 0.00;

  @override
  Widget build(BuildContext context) {
    // Wrap the card container in a Stack to allow absolute positioning of elements on top
    return Stack(
      children: [
        // Main container holding the card contents and gradient decoration
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Build Your Future, One Tap at a Time",
                style: AppTheme.headlineMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
              AppTheme.divider(context, AppTheme.primaryWhite),
              Text(
                "Your Overall Savings",
                style: AppTheme.labelSmall.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "GHS $savings",
                    style: AppTheme.headlineLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  Icon(
                    Icons.visibility_off,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
            ],
          ),
        ),
        // Positioned trending icon stacked at the bottom right corner with light white color
        Positioned(
          bottom: 0,
          right: MediaQuery.of(context).size.width * 0.5,
          left: MediaQuery.of(context).size.width * 0.5,
          child: Icon(
            Icons.trending_up,
            size: 56, // Large decorative size
            color: AppColors.primary.withAlpha(
              60,
            ), // Light white color with transparency
          ),
        ),
      ],
    );
  }
}

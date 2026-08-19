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
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Build Your Future, One Tap at a Time",
            style: AppTheme.headlineLarge.copyWith(color: AppColors.primary),
          ),
          AppTheme.divider(context, AppTheme.primaryWhite),
          Text(
            "Your Overall Savings",
            style: AppTheme.bodyMedium.copyWith(color: AppColors.primary),
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
              Icon(Icons.visibility_off, size: 22, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
        ],
      ),
    );
  }
}

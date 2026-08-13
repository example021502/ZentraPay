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
    return Container(
      decoration: AppTheme.coloredCardDecoration(
        AppColors.secondary,
      ).copyWith(gradient: AppTheme.secondaryGradient),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Build Your Future, One Tap at a Time",
                      style: AppTheme.headlineMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Icon(
                        Icons.trending_up_outlined,
                        size: 40,
                        color: AppColors.primary.withAlpha(80),
                      ),
                    ),
                  ),
                ],
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
                Icon(Icons.visibility_off, size: 22, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(200),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 5.0, 15.0, 5.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Icon(
                          Icons.arrow_downward,
                          size: 22,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      "Save Now",
                      style: AppTheme.labelSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

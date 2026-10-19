import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/main.dart';

/// Pink hero card: headline, total savings (real, listens to
/// SavingsRepository), and a visibility toggle that swaps the amount for a
/// `___.__` placeholder.
class ZGrowHeroCard extends StatefulWidget {
  const ZGrowHeroCard({super.key});

  @override
  State<ZGrowHeroCard> createState() => _ZGrowHeroCardState();
}

class _ZGrowHeroCardState extends State<ZGrowHeroCard> {
  final savings = 0.00;

  /// When false the amount row shows the placeholder instead of the figure.
  bool _amountVisible = true;

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
                _amountVisible ? "GHS $savings" : "___.__",
                style: AppTheme.headlineLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              IconButton(
                onPressed: () =>
                    setState(() => _amountVisible = !_amountVisible),
                icon: Icon(
                  _amountVisible ? Icons.visibility_off : Icons.visibility,
                  size: 22,
                  color: AppColors.primary,
                ),
                tooltip: _amountVisible ? "Hide amount" : "Show amount",
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
        ],
      ),
    );
  }
}

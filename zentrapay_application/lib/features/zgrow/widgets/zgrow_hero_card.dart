import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/main.dart';

/// The savings summary that sits inside ZGrow's [SectionHeader]: the total
/// saved so far, with a visibility toggle that swaps the amount for a `___.__`
/// placeholder. Laid out like the ZRemit rate card (title row, divider, rows)
/// so both sections open the same way.
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Overall Savings",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.headlineSmall.copyWith(color: AppColors.primary),
        ),
        AppTheme.divider(context, AppColors.primary),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _amountVisible ? "GHS $savings" : "___.__",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.headlineLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _amountVisible = !_amountVisible),
              icon: Icon(
                _amountVisible ? Icons.visibility_off : Icons.visibility,
                size: 22,
                color: AppTheme.primaryWhite,
              ),
              tooltip: _amountVisible ? "Hide amount" : "Show amount",
            ),
          ],
        ),
        Text(
          "Build your future, one tap at a time.",
          style: AppTheme.bodySmall.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}

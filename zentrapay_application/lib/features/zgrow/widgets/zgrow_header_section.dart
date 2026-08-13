import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/zgrow/widgets/growth_chart_card.dart';
import 'package:zentrapay_application/features/zgrow/widgets/savings_total.dart';
import 'package:zentrapay_application/features/zgrow/widgets/zgrow_hero_card.dart';

/// Top of the ZGrow tab: the pink hero card + the growth chart card.
class ZGrowHeaderSection extends StatelessWidget {
  const ZGrowHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ZGrowHeroCard(),
        const SizedBox(height: 25),
        Container(
          decoration: AppTheme.cardDecoration,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 25.0, horizontal: 20),
            child: GrowthChartCard(totalSavings: SavingsTotal.amount),
          ),
        ),
      ],
    );
  }
}

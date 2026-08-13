import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/main.dart';

class GrowthChartLegend extends StatelessWidget {
  const GrowthChartLegend({super.key, required this.sampleData});

  final bool sampleData;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dot(AppTheme.zgrowColor, "Net Savings"),
            const SizedBox(width: 14),
            _dot(AppTheme.secondaryNavy, "Income"),
            const SizedBox(width: 14),
            _dot(AppTheme.warningOrange, "Spend"),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          sampleData
              ? "Sample data — add a savings account to see your own trend."
              : "Sample trend — anchored to your current totals until a full history is available.",
          style: const TextStyle(color: Colors.grey, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _dot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textBlack, fontSize: 11),
        ),
      ],
    );
  }
}

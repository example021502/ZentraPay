import 'package:flutter/material.dart';
import 'package:zentrapay_application/features/zgrow/widgets/chart_period.dart';
import 'package:zentrapay_application/main.dart';

class GrowthChartHeader extends StatelessWidget {
  const GrowthChartHeader({
    super.key,
    required this.period,
    required this.onChanged,
  });

  final ChartPeriod period;
  final ValueChanged<ChartPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Growth Trend",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        DropdownButton<ChartPeriod>(
          value: period,
          underline: const SizedBox.shrink(),
          isDense: true,
          style: const TextStyle(
            color: AppColors.textBlack,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          items: ChartPeriod.values
              .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
              .toList(),
          onChanged: (p) {
            if (p != null) onChanged(p);
          },
        ),
      ],
    );
  }
}

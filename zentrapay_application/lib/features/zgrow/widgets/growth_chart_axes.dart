import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/features/zgrow/widgets/growth_chart_data.dart';
import 'package:zentrapay_application/main.dart';

/// Bottom (period labels) + left (compact money) axis titles for the
/// growth chart — split out of GrowthLineChart to keep files small.
FlTitlesData growthChartTitlesData(List<String> labels) {
  return FlTitlesData(
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 22,
        // Explicit interval: 1 — the fix for overlapping/repeated labels.
        // Without it fl_chart can pick a fractional interval and call this
        // back at in-between x-values.
        interval: 1,
        getTitlesWidget: (value, meta) {
          final i = value.toInt();
          if (i < 0 || i >= labels.length || i != value) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              labels[i],
              style: const TextStyle(color: AppColors.textBlack, fontSize: 9),
            ),
          );
        },
      ),
    ),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 36,
        getTitlesWidget: (value, meta) => Text(
          GrowthChartData.compactMoney(value),
          style: const TextStyle(color: AppColors.textBlack, fontSize: 9),
        ),
      ),
    ),
  );
}

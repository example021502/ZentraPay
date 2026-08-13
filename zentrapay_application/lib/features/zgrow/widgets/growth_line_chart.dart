import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/zgrow/widgets/chart_period.dart';
import 'package:zentrapay_application/features/zgrow/widgets/growth_chart_axes.dart';
import 'package:zentrapay_application/features/zgrow/widgets/growth_chart_data.dart';

/// The bare fl_chart LineChart for the 3 money series — split out of
/// GrowthChartCard purely to keep each file under the ~100-line budget.
class GrowthLineChart extends StatelessWidget {
  const GrowthLineChart({
    super.key,
    required this.netSavings,
    required this.income,
    required this.spend,
    required this.period,
  });

  final double netSavings;
  final double income;
  final double spend;
  final ChartPeriod period;

  @override
  Widget build(BuildContext context) {
    final labels = GrowthChartData.xLabels(period);
    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.withAlpha(50), strokeWidth: 0.8),
          ),
          lineTouchData: const LineTouchData(enabled: false),
          titlesData: growthChartTitlesData(labels),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            _line(
              GrowthChartData.series(netSavings, 0.4, period),
              AppTheme.zgrowColor,
            ),
            _line(
              GrowthChartData.series(income, 1.7, period),
              AppTheme.secondaryNavy,
            ),
            _line(
              GrowthChartData.series(spend, 3.1, period),
              AppTheme.warningOrange,
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) => LineChartBarData(
    spots: spots,
    isCurved: true,
    color: color,
    barWidth: 2,
    dotData: const FlDotData(show: false),
  );
}

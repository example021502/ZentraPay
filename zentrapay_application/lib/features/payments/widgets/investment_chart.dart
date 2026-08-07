import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/models/zinvest.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

/// Renders the real historical series from [LiquidityTrendRepository] as a
/// simple fl_chart line chart. Replaces the old static "show_chart" icon
/// placeholder that used to sit here unused.
class InvestmentChart extends StatelessWidget {
  final List<LiquidityTrendPoint> points;
  final Color color;

  const InvestmentChart({
    super.key,
    required this.points,
    this.color = AppTheme.zinvestColor,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Center(
        child: Text(
          "No trend data yet.",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].totalValue.toAmount()),
    ];

    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY).abs() * 0.15 + 1;

    return LineChart(
      LineChartData(
        minY: minY - padding,
        maxY: maxY + padding,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final index = spot.x.toInt();
              final point = points[index.clamp(0, points.length - 1)];
              return LineTooltipItem(
                formatMoney(point.totalValue),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: color.withAlpha(30)),
          ),
        ],
      ),
    );
  }
}

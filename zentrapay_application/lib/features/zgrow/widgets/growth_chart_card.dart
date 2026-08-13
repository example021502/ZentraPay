import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/repositories/zbanking_repository.dart';
import 'package:zentrapay_application/features/zgrow/widgets/chart_period.dart';
import 'package:zentrapay_application/features/zgrow/widgets/growth_chart_data.dart';
import 'package:zentrapay_application/features/zgrow/widgets/growth_chart_header.dart';
import 'package:zentrapay_application/features/zgrow/widgets/growth_chart_legend.dart';
import 'package:zentrapay_application/features/zgrow/widgets/growth_line_chart.dart';

/// The "Growth Trend" card: period dropdown + 3-line chart + legend. Owns
/// the selected [ChartPeriod] itself so switching it never has to bubble
/// state changes up through the parent screen.
class GrowthChartCard extends StatefulWidget {
  const GrowthChartCard({super.key, required this.totalSavings});

  /// Real total from SavingsRepository — computed by the caller since it
  /// already listens to that repository for the header's balance display.
  final double Function() totalSavings;

  @override
  State<GrowthChartCard> createState() => _GrowthChartCardState();
}

class _GrowthChartCardState extends State<GrowthChartCard> {
  ChartPeriod _period = ChartPeriod.monthly;

  @override
  Widget build(BuildContext context) {
    final insights = BankingInsightsRepository.instance.data;
    var netSavings = widget.totalSavings();
    var income = insights?.monthlyIncome.toAmount() ?? 0;
    var spend = insights?.monthlySpend.toAmount() ?? 0;

    final sampleData = GrowthChartData.allZero(netSavings, income, spend);
    if (sampleData) {
      netSavings = GrowthChartData.dummyNetSavings;
      income = GrowthChartData.dummyIncome;
      spend = GrowthChartData.dummySpend;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GrowthChartHeader(
          period: _period,
          onChanged: (p) => setState(() => _period = p),
        ),
        const SizedBox(height: 16),
        GrowthLineChart(
          netSavings: netSavings,
          income: income,
          spend: spend,
          period: _period,
        ),
        const SizedBox(height: 12),
        GrowthChartLegend(sampleData: sampleData),
      ],
    );
  }
}

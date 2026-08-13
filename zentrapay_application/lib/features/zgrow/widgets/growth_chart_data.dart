import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:zentrapay_application/features/zgrow/widgets/chart_period.dart';

/// Pure data-generation for the growth chart — no widgets, so it's trivial
/// to unit test and to swap for a real backend-driven history later (see
/// the comment on [series]).
class GrowthChartData {
  const GrowthChartData._();

  // Fallback anchors shown when the account genuinely has no real data yet
  // (new user, empty wallet) — otherwise all three lines would be flat at
  // zero, which isn't useful for previewing the chart. Swapped out the
  // instant any real balance/insights value is non-zero.
  static const double dummyNetSavings = 2450;
  static const double dummyIncome = 3200;
  static const double dummySpend = 1800;

  static bool allZero(double netSavings, double income, double spend) =>
      netSavings == 0 && income == 0 && spend == 0;

  // Three money-denominated lines: Net Savings, Income, Spend — the only
  // real money metrics currently exposed to the client. The backend only
  // hands back *current* snapshot totals, not a historical series, so each
  // line is a deterministic synthesized trend anchored to that one real
  // number at the most recent (rightmost) point. Swap this for a real
  // backend-driven history once that endpoint exists; nothing else (the
  // dropdown, labels, legend) needs to change.
  static double _trendValue(double target, int index, int count, double seed) {
    if (count <= 1 || index == count - 1) return target;
    final progress = index / (count - 1);
    final wave = sin(seed + index * 0.9) * 0.08;
    final growth = 0.5 + 0.45 * progress;
    return target * (growth + wave).clamp(0.05, 1.5);
  }

  static List<FlSpot> series(double target, double seed, ChartPeriod period) {
    final count = period.pointCount;
    return List.generate(
      count,
      (i) => FlSpot(i.toDouble(), _trendValue(target, i, count, seed)),
    );
  }

  // Sunday-first weekday order (Sun, Mon, Tue, Wed, Thu, Fri, Sat) for the
  // last 7 calendar days ending today.
  static List<String> _dailyLabels() {
    const weekday = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return weekday[d.weekday % 7]; // DateTime.weekday: Mon=1..Sun=7
    });
  }

  static List<String> _weeklyLabels() =>
      List.generate(6, (i) => i == 5 ? "Now" : "W${i + 1}");

  static List<String> _monthlyLabels() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    return List.generate(6, (i) {
      final idx = (now.month - 1 - (5 - i)) % 12;
      return months[idx < 0 ? idx + 12 : idx];
    });
  }

  static List<String> xLabels(ChartPeriod period) => switch (period) {
    ChartPeriod.daily => _dailyLabels(),
    ChartPeriod.weekly => _weeklyLabels(),
    ChartPeriod.monthly => _monthlyLabels(),
  };

  static String compactMoney(double value) {
    if (value.abs() >= 1000) return "${(value / 1000).toStringAsFixed(1)}k";
    return value.toStringAsFixed(0);
  }
}

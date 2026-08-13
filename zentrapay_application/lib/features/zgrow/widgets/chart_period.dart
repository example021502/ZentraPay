/// Granularity for the growth chart's X-axis — controls both the point
/// count/labels and how far back each synthesized trend point reaches.
enum ChartPeriod { daily, weekly, monthly }

extension ChartPeriodLabel on ChartPeriod {
  String get label => switch (this) {
    ChartPeriod.daily => "Daily",
    ChartPeriod.weekly => "Weekly",
    ChartPeriod.monthly => "Monthly",
  };

  int get pointCount => switch (this) {
    ChartPeriod.daily => 7,
    ChartPeriod.weekly => 6,
    ChartPeriod.monthly => 6,
  };
}

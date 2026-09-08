import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/placeholder_screen.dart';
import 'package:zentrapay_application/features/payments/milestones_screen.dart';
import 'package:zentrapay_application/features/zgrow/widgets/financial_tool_tile.dart';

/// Budget Planner / Saving Goal / Debt Tracker list. Saving Goal opens the
/// real MilestonesScreen; the other two don't have dedicated pages yet, so
/// they open a labeled PlaceholderScreen instead of a silent no-op.
class FinancialToolsSection extends StatelessWidget {
  const FinancialToolsSection({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FinancialToolTile(
          icon: Icons.list_alt,
          title: "Budget Planner",
          description:
              "Take control of your money. Set monthly spending limits, track expenses automatically, and hit your financial goals faster.",
          onTap: () =>
              _open(context, const PlaceholderScreen(title: "Budget Planner")),
        ),
        const SizedBox(height: 8),
        FinancialToolTile(
          icon: Icons.access_time,
          title: "Saving Goal",
          description:
              "Save with purpose. Whether it's a vacation, emergency fund, or new car, track your progress and reach your financial goals faster",
          onTap: () => _open(context, const MilestonesScreen()),
        ),
        const SizedBox(height: 8),
        FinancialToolTile(
          icon: Icons.balance,
          title: "Debt Tracker",
          description:
              "Turn overwhelming debts into manageable steps. Map out snowball or avalanche payoff plans and celebrate every cleared balance.",
          onTap: () =>
              _open(context, const PlaceholderScreen(title: "Debt Tracker")),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

class FinancialTools extends StatelessWidget {
  const FinancialTools({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Financial Tools", style: AppStyles.header),
        const SizedBox(height: 10),
        _item(Icons.library_books_outlined, "Budget Planner"),
        _item(Icons.timer_outlined, "Saving Goal"),
        _item(Icons.credit_score_outlined, "Debt Tracker"),
      ],
    );
  }

  Widget _item(IconData icon, String label) => InkWell(
    onTap: () {
      ZentraNotifier.success("Financial Tool", "Not yet implemented!");
    },
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, color: AppTheme.primaryPink, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 20),
    ),
  );
}

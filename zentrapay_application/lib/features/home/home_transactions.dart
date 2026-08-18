import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';

class HomeTransactions extends StatelessWidget {
  const HomeTransactions({super.key, required this.history});

  // Stores the list of recent transactions passed from the parent widget
  final List<Map<String, dynamic>> history;

  @override
  Widget build(BuildContext context) {
    // Only exists once there's real transaction history to show.
    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Recent Activities", style: AppTheme.headlineSmall),
            TextButton(
              onPressed: () {
                //   TODO: TO BE IMPLEMENTED LATER
                showComingSoon(context, "See All History");
              },

              child: Text(
                "See All",
                style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryPink),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        // The ListView needs a bounded max-height so it doesn't get an
        // unlimited vertical extent when placed inside the scrolling parent
        // (without it, Flutter throws "Vertical viewport was given unbounded
        // height"). It stays internally scrollable within that height.
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: history.length > 5 ? 5 : history.length,
            itemBuilder: (BuildContext context, int i) {
              final item = history[i];
              final title = item["title"] ?? "Transaction";
              final time = item["time"] ?? "Today";
              final amount = item["amount"] ?? "GHS 0.00";
              final icon = item["icon"] ?? Icons.receipt_long;
              final type = item["type"] ?? "payment";
              return TransactionListItem(
                icon: icon,
                title: title,
                subtitle: time,
                amount: amount,
                onTap: () => _showTransactionDetails(
                    context, title, time, amount, type),
              );
            },
          ),
        ),
      ],
    );
  }

  // Displays a bottom sheet modal showing breakdown metrics for a selected transaction
  void _showTransactionDetails(
    BuildContext context,
    String title,
    String time,
    String amount,
    String type,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.gray300,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(title, style: AppTheme.headlineMedium),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              time,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            AmountText(amount: amount, fontSize: 32),
            const SizedBox(height: AppTheme.spacingLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem("Type", type),
                _buildDetailItem("Status", "Completed"),
                _buildDetailItem("Reference", "TXN123456"),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to structure label-value metrics inside the transaction detail sheet
  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(value, style: AppTheme.titleLarge),
      ],
    );
  }
}

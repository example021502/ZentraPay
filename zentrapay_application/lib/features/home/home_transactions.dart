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

    // Clip the history list to a maximum of the first 5 transactions
    final List<Map<String, dynamic>> clippedHistory = history.length > 5
        ? history.take(5).toList()
        : history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTheme.spacingXl),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Recent Activities", style: AppTheme.bodyMedium),
            TextButton(
              onPressed: () {
                // TODO: TO BE IMPLEMENTED LATER
                showComingSoon(context, "See All History");
              },
              child: Text(
                "See All",
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryPink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Column(
          children: clippedHistory.map((item) {
            final title = item["title"] ?? "Transaction";
            final timeRaw = item["time"]?.toString() ?? '';
            final dateTime = DateTime.tryParse(timeRaw) ?? DateTime.now();
            String dateOnly =
                "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
            String timeOnly =
                "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
            final date = "$dateOnly • $timeOnly";
            final amount = item["amount"] ?? "Unknown";
            final icon = item["icon"] ?? Icons.receipt_long;
            final type = item["type"] ?? "payment";

            return TransactionListItem(
              icon: icon,
              title: title,
              subtitle: date,
              amount: amount,
              onTap: () =>
                  _showTransactionDetails(context, title, date, amount, type),
            );
          }).toList(),
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
            Text(
              title,
              style: AppTheme.headlineMedium,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              time,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AmountText(amount: amount, fontSize: 32, maxLines: 1),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Row(
              children: [
                Expanded(child: _buildDetailItem("Type", type)),
                Expanded(child: _buildDetailItem("Status", "Completed")),
                Expanded(child: _buildDetailItem("Reference", "TXN123456")),
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
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          value,
          style: AppTheme.titleLarge,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

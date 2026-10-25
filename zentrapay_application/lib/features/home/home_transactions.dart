import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/Common/format_date_time_string.dart';
import 'package:zentrapay_application/features/home/HomePayments/send_again_flow.dart';

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
        Text("Latest Activities", style: AppTheme.bodyMedium),
        const SizedBox(height: AppTheme.spacingMd),
        Column(
          children: clippedHistory.map((item) {
            final title = item["title"] ?? "Transaction";
            // `time` is the raw backend timestamp string — always format it
            // before display rather than relying on the caller to have done so.
            final date = formatDateTimeString(item['time']?.toString());

            // final dateTime =
            //     DateTime.tryParse(item["time"]?.toString() ?? '') ??
            //     DateTime.now();
            // String dateOnly =
            //     "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
            // String timeOnly =
            //     "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
            // final String date = "$dateOnly • $timeOnly";
            final amount = item["amount"] ?? "Unknown";
            final icon = item["icon"] ?? Icons.receipt_long;

            return TransactionListItem(
              icon: icon,
              title: title,
              subtitle: date,
              amount: amount,
              onTap: () => _showTransactionDetails(context, item),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Displays a bottom sheet modal showing breakdown metrics for a selected
  // transaction. Carries the full [AppTransaction] (embedded by the caller)
  // so outgoing payments can offer a "Send Again" shortcut straight into
  // the shared pay flow.
  void _showTransactionDetails(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    // Captured before the sheet opens: the sheet's own context is disposed
    // on pop, but this page context stays valid for the send-again flow.
    final BuildContext pageContext = context;
    final String title = (item["title"] ?? "Transaction").toString();
    final String time = formatDateTimeString(item['time']?.toString());
    final String amount = (item["amount"] ?? "Unknown").toString();
    final String type = (item["type"] ?? "payment").toString();
    final Object? stored = item['transaction'];
    final AppTransaction? transaction = stored is AppTransaction
        ? stored
        : null;
    // Only outgoing rows record a real counterparty — an incoming payment
    // stores the user themself as receiver, so "Send Again" would prefill a
    // transfer to your own account (see canSendAgain).
    final bool showSendAgain = transaction != null && canSendAgain(transaction);
    // Prefer the real ledger values; keep the legacy placeholders only for
    // maps built without the full transaction record.
    final String status = transaction != null && transaction.status.isNotEmpty
        ? transaction.status
        : "Completed";
    final String reference =
        transaction != null && transaction.txnRef.isNotEmpty
        ? transaction.txnRef
        : "TXN123456";

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) => Container(
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
                Expanded(child: _buildDetailItem("Status", status)),
                Expanded(child: _buildDetailItem("Reference", reference)),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),
            if (showSendAgain) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Close the details sheet first so the loading overlay
                    // and the amount screen own the stage from here on.
                    Navigator.pop(sheetContext);
                    await sendAgainFromTransaction(
                      context: pageContext,
                      transaction: transaction,
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text("Send Again"),
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(sheetContext),
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

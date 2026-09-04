import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';

enum TransactionResultStatus { success, error }

/// One labeled row in a [showTransactionResultOverlay] detail card (e.g.
/// "Recipient" / "Jane Doe").
class TransactionResultDetail {
  final String label;
  final String value;

  const TransactionResultDetail(this.label, this.value);
}

/// The app's standard post-transaction outcome overlay — same bottom-sheet
/// shape as [showAppOverlaySheet] (History, Notifications, Settings), used
/// in place of a toast/[ZentraNotifier] call for money-movement results.
///
/// A transaction's outcome (money moved, or didn't) deserves an explicit
/// acknowledgement rather than something that can auto-dismiss unnoticed
/// while the app is mid-navigation — see makePayment.dart / SendingForm.dart
/// for the call sites this replaced `ZentraNotifier.success/error` at.
Future<void> showTransactionResultOverlay({
  required BuildContext context,
  required TransactionResultStatus status,
  required String title,
  required String message,
  List<TransactionResultDetail> details = const [],
  String buttonLabel = 'Done',
}) {
  final isSuccess = status == TransactionResultStatus.success;
  final accentColor = isSuccess ? AppTheme.successGreen : AppTheme.errorRed;

  return showAppOverlaySheet<void>(
    context: context,
    minHeightFraction: 0.42,
    maxHeightFraction: 0.80,
    builder: (sheetContext) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: accentColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: accentColor,
                size: 48,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              title,
              style: AppTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              message,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
              textAlign: TextAlign.center,
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingLg),
              AppCard(
                child: Column(
                  children: [
                    for (int i = 0; i < details.length; i++) ...[
                      _DetailRow(detail: details[i]),
                      if (i != details.length - 1)
                        const Divider(
                          height: AppTheme.spacingLg,
                          color: AppTheme.dividerColor,
                        ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spacingXl),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: buttonLabel,
                onPressed: () => Navigator.of(sheetContext).pop(),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
          ],
        ),
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  final TransactionResultDetail detail;

  const _DetailRow({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          detail.label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Flexible(
          child: Text(
            detail.value,
            style: AppTheme.labelLarge,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

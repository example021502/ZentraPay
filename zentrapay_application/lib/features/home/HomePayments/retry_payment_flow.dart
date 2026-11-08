import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/core/utils/Common/app_confirm_sheet.dart';
import 'package:zentrapay_application/core/utils/Common/transaction_result_overlay.dart';
import 'package:zentrapay_application/core/utils/loading_overlay.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/features/payments/repository/cache_payments_data.dart';

/// A failed payment the user sent can be tried again from its details sheet.
/// Wallet-to-wallet payments are replayed; for a bank / mobile-money payout the backend explains that a
/// new transfer is needed (the full account number is never stored).
bool canRetry(AppTransaction transaction) {
  final status = transaction.status.trim().toUpperCase();
  final type = transaction.transactionType.trim().toUpperCase();
  return transaction.isDebit &&
      (status == 'FAILED' || status == 'EXPIRED') &&
      (type == 'P2P_TRANSFER' || type == 'CASH_OUT_BANK' || type == 'CASH_OUT_MOMO');
}

bool _retryInFlight = false;

/// Retry a failed payment:
///
/// 1. The backend checks that the sender AND the receiver are still valid. If either is not, the payment
///    stays failed (with that reason) and the user is told why - no PIN is asked.
/// 2. Otherwise the PIN is asked, the backend checks again and makes the payment.
Future<void> retryFailedTransaction({
  required BuildContext context,
  required AppTransaction transaction,
}) async {
  if (_retryInFlight) return;
  _retryInFlight = true;
  try {
    final RetryCheck check;
    try {
      check = await LoadingOverlay.run(
        () => PaymentsService.checkRetry(transaction.transactionId),
        message: 'Checking the payment…',
      );
    } catch (e) {
      if (!context.mounted) return;
      await showTransactionResultOverlay(
        context: context,
        status: TransactionResultStatus.error,
        title: "Couldn't check the payment",
        message: _messageOf(e, "We couldn't check this payment right now. Please try again."),
      );
      return;
    }
    if (!context.mounted) return;

    if (!check.retryable) {
      // The reason may now be saved on the payment: show the history with it
      TransactionsRepository.instance.ensureLoaded(forceRefresh: true).catchError((_) {});
      await showTransactionResultOverlay(
        context: context,
        status: TransactionResultStatus.error,
        title: 'This payment cannot be retried',
        message: check.message,
      );
      return;
    }

    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AppConfirmPinSheet(
        name: check.receiverName.isEmpty ? transaction.receiverName : check.receiverName,
        currencyCode: check.currencyCode,
        amount: check.amount,
      ),
    );
    if (pin == null || pin.isEmpty || !context.mounted) return;

    try {
      final result = await LoadingOverlay.run(
        () => PaymentsService.retry(transaction.transactionId, pin),
        message: 'Sending your money…',
      );
      WalletsRepository.instance.refresh().catchError((_) => null);
      TransactionsRepository.instance.syncLatest();
      if (!context.mounted) return;
      final pending = result.isOpenStatus;
      final failed = result.isFailedStatus;
      await showTransactionResultOverlay(
        context: context,
        status: failed ? TransactionResultStatus.error : TransactionResultStatus.success,
        title: failed
            ? 'Retry failed'
            : pending
            ? 'Payment on its way'
            : 'Payment sent',
        message: failed
            ? (result.failureReason.isNotEmpty ? result.failureReason : 'The payment could not be completed.')
            : '${check.currencyCode} ${check.amount} sent to ${check.receiverName}.',
      );
    } catch (e) {
      WalletsRepository.instance.refresh().catchError((_) => null);
      TransactionsRepository.instance.syncLatest();
      if (!context.mounted) return;
      await showTransactionResultOverlay(
        context: context,
        status: TransactionResultStatus.error,
        title: 'Retry failed',
        message: _messageOf(e, 'Something went wrong. No money was deducted from your account.'),
      );
    }
  } finally {
    _retryInFlight = false;
  }
}

String _messageOf(Object e, String fallback) {
  if (e is DioException && e.response?.data is Map) {
    final message = (e.response!.data as Map)['message'];
    if (message is String && message.isNotEmpty) return message;
  }
  return fallback;
}

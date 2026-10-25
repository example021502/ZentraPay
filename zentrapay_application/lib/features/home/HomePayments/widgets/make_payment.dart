import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../features/payments/repository/cache_payments_data.dart';
import '../../../../core/utils/Common/app_confirm_sheet.dart';
import '../../../../core/utils/Common/enter_amount.dart';
import '../../../../core/utils/Common/generate_transaction_id.dart';
import '../../../../core/utils/Common/transaction_result_overlay.dart';
import '../../../../core/models/transaction.dart';
import '../../../../core/utils/loading_overlay.dart';
import '../../../../features/zgrow/emergency/emergency_vault.dart';

class PaymentController {
  bool _payInFlight = false;

  bool get payInFlight => _payInFlight;

  /// Universal payload builder for all payment types.
  /// Mirrors the backend's `InitializePaymentRequestDTO` exactly:
  /// `{pin, TXN_Ref, transfer{amount,currencyCode,purpose},
  /// appUser|bank|recipient{…}, channelType}`.
  Map<String, dynamic> _buildPayload({
    required String pin,
    required String txnRef,
    required String channelType,
    required String label,
    required Map<String, dynamic> transfer,
    required Map<String, dynamic> recipient,
  }) {
    return {
      "pin": pin,
      "TXN_Ref": txnRef,
      "transfer": transfer,
      label: recipient,
      "channelType": channelType,
    };
  }

  /// Single generic payment executor handling the entire UI & API workflow
  Future<void> processPayment({
    required BuildContext context,
    required String
    recipientNameForUI, // Used for dialogs (e.g., User Name, Bank Name)
    required String channelType,
    required Map<String, dynamic> recipientMap,
    required void Function(bool) onStateChanged,
    String purpose = "",
    String? preferredCurrencyCode,
  }) async {
    if (_payInFlight) return;

    // 1. Show Amount Entry Dialog
    final amountResult = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnterAmount(
        recipient: recipientNameForUI,
        preferredCurrency: preferredCurrencyCode,
      ),
    );
    if (amountResult == null || !context.mounted) return;

    // The transfer currency is only known once the user has entered an amount
    // (it comes from the sender's own fiat accounts). The backend's
    // PaymentDestinationDTO requires currencyCode (@NotBlank, validated via
    // @Valid cascade) and compares it against the transfer currency, and its
    // countryCode check treats a blank recipient country as domestic — so
    // stamp both in here instead of requiring every call site to know them.

    // 2. Show PIN Confirmation Sheet
    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) => AppConfirmPinSheet(
        name: recipientNameForUI,
        currencyCode: amountResult['currencyCode'],
        amount: amountResult['amount'],
      ),
    );
    if (pin == null || pin.isEmpty || !context.mounted) return;

    final txnRef = generateTxnRef();
    final amount = double.tryParse(amountResult['amount'].toString()) ?? 0;
    final currencyCode = amountResult['currencyCode'].toString();
    // `TransferDetails.purpose` is declared @NotBlank on the backend — always
    // send a non-empty description so validation can never reject the payment.
    final effectivePurpose = purpose.trim().isEmpty
        ? "Wallet transfer"
        : purpose.trim();
    final Map<String, dynamic> amountDetails = {
      "amount": amount,
      "currencyCode": currencyCode,
      "purpose": effectivePurpose,
    };
    // 3. Build the universal payload
    final payload = _buildPayload(
      pin: pin,
      txnRef: txnRef,
      transfer: amountDetails,
      recipient: recipientMap,
      label: channelType == "INTERNAL"
          ? "appUser"
          : channelType == "BANK"
          ? "bank"
          : channelType == "MOMO"
          ? "mobileMoney"
          : "recipient",
      channelType: channelType,
    );

    _payInFlight = true;
    onStateChanged(_payInFlight);

    // 4. Dispatch API Request & Handle Feedback — the global overlay blocks
    // the rest of the screen for the duration so the request can't be fired
    // twice and the user can't wander off into another action mid-payment.
    try {
      final transaction = await LoadingOverlay.run(
        () => PaymentsService.payment(payload: payload),
        message: "Processing payment…",
      );
      debugPrint("============= THE TRANSACTION RESULT:: $transaction");
      if (!context.mounted) return;
      // payment() hands back {'data': AppTransaction, 'message': String}; a
      // response that carried no transaction data is a failure, not a success.
      final AppTransaction? data = transaction['data'] as AppTransaction?;
      if (data == null) {
        await showTransactionResultOverlay(
          context: context,
          status: TransactionResultStatus.error,
          title: "Payment Failed",
          message: (transaction['message'] ?? "Payment failed").toString(),
        );
        return;
      }
      // Human-readable ledger status for the detail card — empty backend
      // statuses fall back to the overlay's own outcome so the row never
      // renders blank/undefined.
      final String statusLabel = data.status.trim().isEmpty
          ? (data.isFailedStatus ? "FAILED" : "SUCCESS")
          : data.status;
      // Every detail row falls back to the values the flow already knows
      // locally (amount entry, generated reference, chosen channel), so the
      // card is complete even when the backend response omits a field.
      final String amountLabel = data.absoluteAmount.trim().isNotEmpty
          ? data.absoluteAmount
          : "$currencyCode $amount";
      final String referenceLabel = data.txnRef.trim().isNotEmpty
          ? data.txnRef
          : txnRef;
      final String typeLabel = data.transactionType.trim().isNotEmpty
          ? data.transactionType
          : channelType;
      // The ledger can settle the HTTP call successfully but still report a
      // terminal status on the row (FAILED/EXPIRED) — honor it instead of
      // blindly showing the success state.
      if (data.isFailedStatus) {
        await showTransactionResultOverlay(
          context: context,
          status: TransactionResultStatus.error,
          title: "Payment Failed",
          message: (transaction['message'] ?? "Payment failed").toString(),
          details: [
            TransactionResultDetail("Recipient", recipientNameForUI),
            TransactionResultDetail("Amount", amountLabel),
            TransactionResultDetail("Status", statusLabel),
            TransactionResultDetail("Reference", referenceLabel),
          ],
        );
        return;
      }
      // Emergency Vault round-up (a no-op unless the vault is switched on and
      // the amount has a part-50 remainder).
      int savedMinor = 0;
      try {
        savedMinor = await EmergencyVault.instance.recordRoundUp(
          amount: amount,
          currency: currencyCode,
          reference: referenceLabel,
        );
      } catch (e) {
        debugPrint("Emergency vault round-up failed: $e");
      }
      if (!context.mounted) return;
      await showTransactionResultOverlay(
        context: context,
        status: TransactionResultStatus.success,
        title: (transaction['message'] ?? "Payment Successful").toString(),
        // amountLabel drops the debit sign so the sentence reads
        // "GHS 100.00 sent to Ama" rather than "-GHS 100.00 sent to Ama".
        message: "$amountLabel sent to $recipientNameForUI.",
        details: [
          TransactionResultDetail("Recipient", recipientNameForUI),
          TransactionResultDetail("Amount", amountLabel),
          TransactionResultDetail("Status", statusLabel),
          TransactionResultDetail("Type", typeLabel),
          TransactionResultDetail("Reference", referenceLabel),
          if (savedMinor > 0)
            TransactionResultDetail(
              "Saved to Emergency Vault",
              EmergencyVault.formatMinor(savedMinor, currency: currencyCode),
            ),
        ],
      );
    } catch (e) {
      if (!context.mounted) return;
      await showTransactionResultOverlay(
        context: context,
        status: TransactionResultStatus.error,
        title: "Payment Failed",
        message: _extractErrorMessage(e),
      );
    } finally {
      _payInFlight = false;
      onStateChanged(_payInFlight);
    }
  }

  String _extractErrorMessage(Object e) {
    if (e is DioException && e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data['message'] is String && (data['message'] as String).isNotEmpty) {
        return data['message'];
      }
    }
    return "Something went wrong! Please try again. Don't worry. no money was deducted from your account.";
  }
}

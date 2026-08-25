import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/repositories/payments_service.dart';
import '../../../../core/utils/Common/AppConfirmSheet.dart';
import '../../../../core/utils/Common/EnterAmount.dart';
import '../../../../core/utils/Common/GenerateTransactionId.dart';
import '../../../../core/utils/Notifier.dart';

class PaymentController {
  bool _payInFlight = false;

  bool get payInFlight => _payInFlight;

  /// Universal payload builder for all payment types
  Map<String, dynamic> _buildPayload({
    required String pin,
    required String txnRef,
    required double amount,
    required String currencyCode,
    required Map<String, dynamic> recipient,
    required Map<String, dynamic> destination,
    String purpose = "",
  }) {
    return {
      "pin": pin,
      "recipient": recipient,
      "destination": destination,
      "transfer": {
        "referenceId": txnRef,
        "amount": amount,
        "currencyCode": currencyCode,
        "currencyType": "fiat",
        "purpose": purpose,
      },
    };
  }

  /// Single generic payment executor handling the entire UI & API workflow
  Future<void> processPayment({
    required BuildContext context,
    required String
    recipientNameForUI, // Used for dialogs (e.g., User Name, Bank Name)
    required Map<String, dynamic> recipientMap,
    required Map<String, dynamic> destinationMap,
    required void Function(bool) onStateChanged,
    String purpose = "",
  }) async {
    if (_payInFlight) return;

    // 1. Show Amount Entry Dialog
    final amountResult = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnterAmount(recipient: recipientNameForUI),
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
        destination: recipientNameForUI,
      ),
    );
    if (pin == null || pin.isEmpty || !context.mounted) return;

    final txnRef = generateTxnRef();
    final amount = double.tryParse(amountResult['amount'].toString()) ?? 0;
    final currencyCode = amountResult['currencyCode'].toString();

    // 3. Build the universal payload
    final payload = _buildPayload(
      pin: pin,
      txnRef: txnRef,
      amount: amount,
      currencyCode: currencyCode,
      recipient: recipientMap,
      destination: {...destinationMap, "currencyCode":currencyCode},
      purpose: purpose,
    );

    _payInFlight = true;
    onStateChanged(_payInFlight);

    // 4. Dispatch API Request & Handle Feedback
    try {
      await PaymentsService.payment(payload: payload);
      if (!context.mounted) return;
      ZentraNotifier.success(
        "Payment Sent",
        "$currencyCode $amount sent to $recipientNameForUI.",
      );
    } catch (e) {
      if (!context.mounted) return;
      ZentraNotifier.error("Payment Failed", _extractErrorMessage(e));
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
    return "Something went wrong. Please try again.";
  }
}

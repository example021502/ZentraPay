import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/Common/app_confirm_sheet.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/core/utils/payment_currency.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';

/// The one bill-payment form (electricity, TV, airtime ...). Opened from the home
/// "Bills" row, the "More" provider picker and the Send screen's search, so a bill
/// is paid the same way wherever it was picked.
///
/// Steps: customer reference (meter / smartcard / phone) -> optional "Check" that asks
/// the biller who owns it -> amount in the user's own currency -> PIN -> pay. The wallet is
/// debited by the server first and refunded if the biller definitely refuses, so the result
/// shown here is whatever the server settled on (paid / processing / returned).
class BillPaymentSheet extends StatefulWidget {
  const BillPaymentSheet({
    super.key,
    required this.providerId,
    required this.providerName,
  });

  final String providerId;
  final String providerName;

  /// Opens the form; completes with true when a payment was made (or is processing).
  static Future<bool> show(
    BuildContext context, {
    required String providerId,
    required String providerName,
  }) async {
    if (providerId.isEmpty) {
      ZentraNotifier.error(
        "Missing Provider",
        "This provider can't be paid right now — try again later.",
      );
      return false;
    }
    final paid = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => BillPaymentSheet(
        providerId: providerId,
        providerName: providerName,
      ),
    );
    return paid == true;
  }

  @override
  State<BillPaymentSheet> createState() => _BillPaymentSheetState();
}

class _BillPaymentSheetState extends State<BillPaymentSheet> {
  final _referenceController = TextEditingController();
  final _amountController = TextEditingController();

  String _currency = '';
  bool _checking = false;
  bool _paying = false;

  // Result of the optional "Check": the name the biller holds for the reference
  String? _customerName;
  String? _checkProblem;

  @override
  void initState() {
    super.initState();
    _resolveCurrency();
    // A different reference means the earlier check no longer applies
    _referenceController.addListener(() {
      if (_customerName != null || _checkProblem != null) {
        setState(() {
          _customerName = null;
          _checkProblem = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // The user pays in the default currency of their own country; fall back to the first wallet account
  Future<void> _resolveCurrency() async {
    var code = await PaymentCurrency.ofSender();
    if (code.isEmpty) {
      try {
        final wallets = await WalletsRepository.instance.ensureLoaded();
        final accounts = wallets?.fiatAccounts ?? const [];
        if (accounts.isNotEmpty) code = accounts.first.currencyCode;
      } catch (_) {}
    }
    if (mounted) setState(() => _currency = code);
  }

  String _messageOf(Object e, String fallback) {
    if (e is DioException && e.response?.data is Map) {
      final message = (e.response!.data as Map)['message'];
      if (message is String && message.trim().isNotEmpty) return message.trim();
    }
    return fallback;
  }

  // Asks the biller who owns this meter / smartcard / number
  Future<void> _check() async {
    final reference = _referenceController.text.trim();
    if (reference.isEmpty) {
      ZentraNotifier.error(
        'Missing Reference',
        'Enter your customer reference for ${widget.providerName}.',
      );
      return;
    }
    setState(() {
      _checking = true;
      _customerName = null;
      _checkProblem = null;
    });
    try {
      final response = await ApiClient().dio.post(
        '/api/bill-providers/validate',
        data: {
          'providerId': widget.providerId,
          'customerReference': reference,
        },
      );
      final data = response.data['data'];
      final valid = data is Map && data['valid'] == true;
      final name = data is Map ? (data['customerName'] ?? '').toString().trim() : '';
      if (!mounted) return;
      setState(() {
        if (valid) {
          _customerName = name.isEmpty ? 'Reference confirmed' : name;
        } else {
          _checkProblem = "The biller doesn't recognise this reference.";
        }
      });
    } catch (e) {
      if (!mounted) return;
      // The check itself failing (biller offline) must not block paying; say so plainly
      setState(() => _checkProblem = _messageOf(e, "Couldn't check this reference right now."));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _pay() async {
    final reference = _referenceController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (reference.isEmpty) {
      ZentraNotifier.error(
        'Missing Reference',
        'Enter your customer reference for ${widget.providerName}.',
      );
      return;
    }
    if (amount == null || amount <= 0) {
      ZentraNotifier.error(
        'Invalid Amount',
        'Enter a valid amount greater than zero.',
      );
      return;
    }
    if (_currency.isEmpty) {
      ZentraNotifier.error(
        'No wallet',
        "We couldn't find the wallet to pay from. Try again in a moment.",
      );
      return;
    }

    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppConfirmPinSheet(
        name: widget.providerName,
        currencyCode: _currency,
        amount: amount.toStringAsFixed(2),
      ),
    );
    if (pin == null || pin.isEmpty || !mounted) return;

    setState(() => _paying = true);
    try {
      final response = await ApiClient().dio.post(
        '/api/bill-providers/pay',
        data: {
          'pin': pin,
          'providerId': widget.providerId,
          'customerReference': reference,
          'amount': amount.toStringAsFixed(2),
          'currencyCode': _currency,
        },
      );
      final data = response.data['data'];
      final transactionJson = data is Map ? data['transaction'] : null;
      if (transactionJson is Map) {
        TransactionsRepository.instance.prepend(
          AppTransaction.fromJson(Map<String, dynamic>.from(transactionJson)),
        );
      }
      _afterAttempt();
      final status = transactionJson is Map
          ? (transactionJson['status'] ?? '').toString().toUpperCase()
          : '';
      if (mounted) Navigator.pop(context, true);
      if (status == 'SUCCESS') {
        ZentraNotifier.success(
          'Payment Successful',
          'Paid $_currency ${amount.toStringAsFixed(2)} to ${widget.providerName}.',
        );
      } else {
        // Accepted by the biller but not confirmed yet: the history updates by itself
        ZentraNotifier.notice(
          '$_currency ${amount.toStringAsFixed(2)} to ${widget.providerName} is being processed. '
          "You'll see the result in your history.",
          icon: Icons.schedule_rounded,
        );
      }
    } catch (e) {
      // A refused bill is saved (and refunded) on the server: show it in the history too
      _afterAttempt();
      if (mounted) setState(() => _paying = false);
      ZentraNotifier.error(
        'Payment Failed',
        _messageOf(e, 'Could not complete this bill payment. Try again.'),
      );
    }
  }

  // Wallet balance and history changed on the server (debit, or debit + refund)
  void _afterAttempt() {
    WalletsRepository.instance.refresh().catchError((_) => null);
    TransactionsRepository.instance.syncLatest().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppTheme.spacingLg,
        right: AppTheme.spacingLg,
        top: AppTheme.spacingLg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Pay ${widget.providerName}", style: AppTheme.headlineSmall),
            const SizedBox(height: AppTheme.spacingMd),
            AppTextField(
              controller: _referenceController,
              labelText: 'Customer reference',
              hintText: 'e.g. meter, smartcard or phone number',
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _checking || _paying ? null : _check,
                icon: _checking
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_outlined, size: 18),
                label: const Text('Check reference'),
              ),
            ),
            if (_customerName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: AppTheme.successGreen,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(_customerName!, style: AppTheme.labelLarge),
                    ),
                  ],
                ),
              ),
            if (_checkProblem != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppTheme.warningOrange,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _checkProblem!,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.warningOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            AppTextField(
              controller: _amountController,
              labelText: _currency.isEmpty ? 'Amount' : 'Amount ($_currency)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Pay now',
                loading: _paying,
                onPressed: _checking ? null : _pay,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
          ],
        ),
      ),
    );
  }
}

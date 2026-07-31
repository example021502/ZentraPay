import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/features/auth/custom_keypad.dart';
import 'package:zentrapay_application/features/home/api_home_wallet_services.dart';

import 'api_authentication.dart';

enum PinMode { set, verify, confirmTransaction }

/// Unified PIN entry sheet, replacing SetPinDialog, PinSheet+PinVerifySheet,
/// and EnterPIN.dart's ConfirmPin with one component covering all three
/// real use cases via named constructors.
class AppPinSheet extends StatefulWidget {
  final PinMode mode;
  final Map<String, dynamic>? form;
  final int pinLength;

  const AppPinSheet.set({super.key, this.pinLength = 4})
    : mode = PinMode.set,
      form = null;

  const AppPinSheet.verify({super.key, this.pinLength = 4})
    : mode = PinMode.verify,
      form = null;

  const AppPinSheet.confirmTransaction({
    super.key,
    required Map<String, dynamic> this.form,
    this.pinLength = 4,
  }) : mode = PinMode.confirmTransaction;

  @override
  State<AppPinSheet> createState() => _AppPinSheetState();
}

class _AppPinSheetState extends State<AppPinSheet> {
  String _pin = '';
  String _firstPin = '';
  int _step = 0; // 0 = enter, 1 = confirm (PinMode.set only)
  bool _processing = false;
  bool? _resultSuccess; // confirmTransaction only
  String? _resultMessage;

  void _onDigit(String digit) {
    if (_processing || _pin.length >= widget.pinLength) return;
    setState(() => _pin += digit);
    if (_pin.length == widget.pinLength) _onComplete();
  }

  void _onDelete() {
    if (_processing || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _onComplete() async {
    switch (widget.mode) {
      case PinMode.set:
        await _handleSetStep();
        break;
      case PinMode.verify:
        await _handleVerify();
        break;
      case PinMode.confirmTransaction:
        await _handleConfirmTransaction();
        break;
    }
  }

  Future<void> _handleSetStep() async {
    if (_step == 0) {
      setState(() {
        _firstPin = _pin;
        _step = 1;
        _pin = '';
      });
      return;
    }
    if (_pin == _firstPin) {
      Navigator.of(context).pop(_pin);
    } else {
      ZentraNotifier.error("Mismatch", "PIN don't match");
      setState(() {
        _step = 0;
        _pin = '';
        _firstPin = '';
      });
    }
  }

  Future<void> _handleVerify() async {
    setState(() => _processing = true);
    final response = await Authentication(_pin);
    if (!mounted) return;
    final verified =
        response.data["success"] == true &&
        response.data["data"]?["verified"] == true;
    if (verified) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _processing = false;
        _pin = '';
      });
      ZentraNotifier.error(
        "Authentication",
        response.data['message'] ?? "Authentication Failed!",
      );
    }
  }

  Future<void> _handleConfirmTransaction() async {
    setState(() => _processing = true);

    final authResponse = await Authentication(_pin);
    if (!mounted) return;
    final pinVerified =
        authResponse.data["success"] == true &&
        authResponse.data["data"]?["verified"] == true;
    if (!pinVerified) {
      setState(() {
        _processing = false;
        _pin = '';
      });
      return ZentraNotifier.error(
        "Authentication",
        authResponse.data['message'] ?? "Authentication Failed!",
      );
    }

    try {
      final response = await makeTransfer(widget.form!, _pin);
      if (!mounted) return;
      final ok = response?["success"] == true;
      setState(() {
        _resultSuccess = ok;
        _resultMessage = response?['message'];
      });
      if (!ok) {
        ZentraNotifier.error(
          "Error",
          response?['message'] ?? 'Transfer failed',
        );
      }
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop(ok);
      });
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) {
        setState(() {
          _resultSuccess = false;
          _resultMessage = e.toString();
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop(false);
        });
      }
    }
  }

  String get _headline {
    switch (widget.mode) {
      case PinMode.set:
        return _step == 0 ? "Set Payment PIN" : "Confirm Payment PIN";
      case PinMode.verify:
        return "Verify PIN";
      case PinMode.confirmTransaction:
        return "Enter Your PIN";
    }
  }

  String get _subtitle {
    switch (widget.mode) {
      case PinMode.set:
        return _step == 0
            ? "Create a secure code to authorize transactions"
            : "Re-enter your code to confirm";
      case PinMode.verify:
        return "Enter your PIN to continue";
      case PinMode.confirmTransaction:
        final amount = widget.form?["amount"] ?? "";
        final currency = widget.form?["currency_code"] ?? "";
        final name = widget.form?["name"] ?? "N/A";
        return "Send $currency $amount to $name";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == PinMode.confirmTransaction &&
        (_processing || _resultSuccess != null)) {
      return _buildTransactionResult();
    }
    return _buildEntrySheet(context);
  }

  Widget _buildEntrySheet(BuildContext context) {
    return AnimatedPadding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingXl,
          horizontal: AppTheme.spacingLg,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.primaryWhite,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXxl),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryNavy.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 30,
                  color: AppTheme.secondaryNavy,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(_headline, style: AppTheme.headlineMedium),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.spacingXl),
              PinDots(length: widget.pinLength, filledCount: _pin.length),
              const SizedBox(height: AppTheme.spacingXl),
              if (_processing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacingXl),
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryPink,
                  ),
                )
              else
                CustomKeypad(onDigitPress: _onDigit, onDelete: _onDelete),
              if (widget.mode == PinMode.set && _step == 1) ...[
                const SizedBox(height: AppTheme.spacingMd),
                TextButton(
                  onPressed: _processing
                      ? null
                      : () => setState(() {
                          _step = 0;
                          _pin = '';
                          _firstPin = '';
                        }),
                  child: const Text("Back"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionResult() {
    final isSuccess = _resultSuccess == true;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingXxl),
        color: AppTheme.primaryWhite,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppTheme.spacingXl,
            children: [
              if (_resultSuccess == null)
                const CircularProgressIndicator(
                  color: AppTheme.primaryPink,
                  strokeWidth: 5,
                )
              else
                Column(
                  children: [
                    Icon(
                      isSuccess ? Icons.check_circle : Icons.cancel,
                      size: 30,
                      color: isSuccess
                          ? AppTheme.successGreen
                          : AppTheme.errorRed,
                    ),
                    Text(
                      isSuccess
                          ? "Transaction was successful!"
                          : (_resultMessage ?? "Transaction Failed!"),
                      textAlign: TextAlign.center,
                      style: AppTheme.headlineMedium.copyWith(
                        color: isSuccess
                            ? AppTheme.successGreen
                            : AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
                  color: AppTheme.secondaryNavy,
                ),
                child: Center(
                  child: Column(
                    spacing: AppTheme.spacingSm,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "sending:",
                        style: AppTheme.whiteBody.copyWith(fontSize: 16),
                      ),
                      Text(
                        "${widget.form?["currency_code"] ?? "Code"} ${widget.form?["amount"] ?? "Amount"}",
                        style: AppTheme.whiteHeadline.copyWith(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        'To:',
                        style: AppTheme.whiteBody.copyWith(fontSize: 16),
                      ),
                      Text(
                        widget.form?["name"] ?? "N/A",
                        style: AppTheme.whiteHeadline,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

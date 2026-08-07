import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/theme/custom_keypad.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';

// Define the operational modes for the PIN sheet component
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
  final bool _processing = false;

  // Handles digit press on the custom keypad
  void _onDigit(String digit) {
    if (_processing || _pin.length >= widget.pinLength) return;
    setState(() => _pin += digit);
    if (_pin.length == widget.pinLength) _onComplete();
  }

  // Handles backspace/delete press on the custom keypad
  void _onDelete() {
    if (_processing || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  // Triggers action upon reaching the required PIN length
  Future<void> _onComplete() async {
    switch (widget.mode) {
      case PinMode.set:
        _handleSetStep();
        break;
      case PinMode.verify:
      case PinMode.confirmTransaction:
        // Send back the entered PIN string to the caller screen
        Navigator.of(context).pop(_pin);
        break;
    }
  }

  // Manages the two-step PIN confirmation logic for PinMode.set
  void _handleSetStep() {
    if (_step == 0) {
      setState(() {
        _firstPin = _pin;
        _step = 1;
        _pin = '';
      });
      return;
    }
    if (_pin == _firstPin) {
      // PIN matches, return the confirmed PIN back to caller
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

  // Returns the appropriate headline text based on the mode and step
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

  // Returns the appropriate subtitle description based on the mode and form context
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
    return _buildEntrySheet(context);
  }

  // Builds the interactive PIN input UI sheet
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
                  child: CircularProgressIndicator(color: AppTheme.primaryPink),
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
}

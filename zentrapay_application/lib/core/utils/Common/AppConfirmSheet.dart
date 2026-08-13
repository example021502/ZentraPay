import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/theme/custom_keypad.dart';

/// Focused component for verifying an existing PIN or confirming a transaction payload.
class AppConfirmPinSheet extends StatefulWidget {
  final String name;
  final String currencyCode;
  final String amount;

  const AppConfirmPinSheet({
    super.key,
    required this.name,
    required this.currencyCode,
    required this.amount,
  });

  @override
  State<AppConfirmPinSheet> createState() => _AppConfirmPinSheetState();
}

class _AppConfirmPinSheetState extends State<AppConfirmPinSheet> {
  String _pin = '';
  final bool _processing = false;
  final int pinLength = 4;

  void _onDigit(String digit) {
    if (_processing || _pin.length >= pinLength) return;
    setState(() => _pin += digit);
    if (_pin.length == pinLength) {
      // Return the entered PIN string back to the caller screen for validation
      Navigator.of(context).pop(_pin);
    }
  }

  void _onDelete() {
    if (_processing || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  String get _headline => "Enter Your PIN";

  String get _subtitle =>
      "Enter your PIN to continue\nSending:${widget.currencyCode} ${widget.amount} to ${widget.name}";

  @override
  Widget build(BuildContext context) {
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
              PinDots(length: pinLength, filledCount: _pin.length),
              const SizedBox(height: AppTheme.spacingXl),
              if (_processing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacingXl),
                  child: CircularProgressIndicator(color: AppTheme.primaryPink),
                )
              else
                CustomKeypad(onDigitPress: _onDigit, onDelete: _onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

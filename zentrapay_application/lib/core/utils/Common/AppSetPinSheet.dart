import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/theme/custom_keypad.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';

/// Pure PIN setting sheet that handles the two-step creation and confirmation process.
class AppSetPinSheet extends StatefulWidget {
  final int pinLength;

  const AppSetPinSheet({super.key, this.pinLength = 4});

  @override
  State<AppSetPinSheet> createState() => _AppSetPinSheetState();
}

class _AppSetPinSheetState extends State<AppSetPinSheet> {
  String _pin = '';
  String _firstPin = '';
  int _step = 0; // 0 = enter new PIN, 1 = confirm PIN
  final bool _processing = false;

  void _onDigit(String digit) {
    if (_processing || _pin.length > widget.pinLength) return;
    setState(() => _pin += digit);
    if (_pin.length == widget.pinLength) _onComplete();
  }

  void _onDelete() {
    if (_processing || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _onComplete() {
    if (_step == 0) {
      setState(() {
        _firstPin = _pin;
        _step = 1;
        _pin = '';
      });
      return;
    }

    if (_pin == _firstPin) {
      // PIN matches, return the confirmed PIN back to the caller
      Navigator.of(context).pop(_pin);
    } else {
      ZentraNotifier.error("Mismatch", "PINs don't match");
      setState(() {
        _step = 0;
        _pin = '';
        _firstPin = '';
      });
    }
  }

  String get _headline =>
      _step == 0 ? "Set Payment PIN" : "Confirm Payment PIN";

  String get _subtitle => _step == 0
      ? "Create a secure code to authorize transactions"
      : "Re-enter your code to confirm";

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
              PinDots(length: widget.pinLength, filledCount: _pin.length),
              const SizedBox(height: AppTheme.spacingXl),
              if (_processing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spacingXl),
                  child: CircularProgressIndicator(color: AppTheme.primaryPink),
                )
              else
                CustomKeypad(onDigitPress: _onDigit, onDelete: _onDelete),
              if (_step == 1) ...[
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

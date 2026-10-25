import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/theme/custom_keypad.dart';

/// A 4-digit keypad entry used for the Emergency Vault PIN. The caller decides
/// what the PIN means: pass [onComplete] to check it (return an error message
/// to show and clear the dots, or null to accept and close the sheet).
class VaultPinPad extends StatefulWidget {
  final String title;
  final String subtitle;

  /// Called with the 4 digits. Return null to accept, or a message to show.
  final Future<String?> Function(String pin) onComplete;

  const VaultPinPad({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onComplete,
  });

  @override
  State<VaultPinPad> createState() => _VaultPinPadState();
}

class _VaultPinPadState extends State<VaultPinPad> {
  static const int _length = 4;
  String _pin = '';
  String? _error;
  bool _busy = false;

  Future<void> _onDigit(String digit) async {
    if (_busy || _pin.length >= _length) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == _length) {
      setState(() => _busy = true);
      final problem = await widget.onComplete(_pin);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = problem;
        if (problem != null) _pin = '';
      });
    }
  }

  void _onDelete() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: AppTheme.brand.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.lock_outline, size: 30, color: AppTheme.textBlack),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(widget.title, style: AppTheme.headlineMedium),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          widget.subtitle,
          textAlign: TextAlign.center,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        PinDots(length: _length, filledCount: _pin.length),
        SizedBox(
          height: 36,
          child: Center(
            child: _error == null
                ? null
                : Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.errorRed,
                    ),
                  ),
          ),
        ),
        CustomKeypad(onDigitPress: _onDigit, onDelete: _onDelete),
      ],
    );
  }
}

/// Asks the user to choose a vault PIN (twice) and resolves to it, or null if
/// the sheet was dismissed.
Future<String?> showCreateVaultPinSheet(BuildContext context) {
  return showAppOverlaySheet<String>(
    context: context,
    minHeightFraction: 0.6,
    maxWidth: 560,
    builder: (_) => const _CreateVaultPin(),
  );
}

class _CreateVaultPin extends StatefulWidget {
  const _CreateVaultPin();

  @override
  State<_CreateVaultPin> createState() => _CreateVaultPinState();
}

class _CreateVaultPinState extends State<_CreateVaultPin> {
  String? _first;
  String? _notice;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: VaultPinPad(
        key: ValueKey(_first == null ? 'choose' : 'confirm'),
        title: _first == null ? 'Choose a vault PIN' : 'Confirm your vault PIN',
        subtitle: _first == null
            ? (_notice ??
                  'You will need this PIN every time you take money out of '
                      'the vault. Pick one that is different from your '
                      'payment PIN.')
            : 'Enter the same 4 digits again.',
        onComplete: (pin) async {
          if (_first == null) {
            setState(() {
              _first = pin;
              _notice = null;
            });
            return null;
          }
          if (pin != _first) {
            setState(() {
              _first = null;
              _notice = 'The PINs did not match. Choose your PIN again.';
            });
            return null;
          }
          Navigator.of(context).pop(pin);
          return null;
        },
      ),
    );
  }
}

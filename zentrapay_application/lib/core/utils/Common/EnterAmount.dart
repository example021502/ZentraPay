import 'package:country_flags/country_flags.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/custom_keypad.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';

import 'package:zentrapay_application/features/home/getCurrencyISOCodeHelper.dart';

/// Bottom-anchored amount-entry overlay, driven entirely by [CustomKeypad]
/// (no system keyboard ever appears) — matches the PIN confirmation sheet
/// that follows it. Pops a {"amount": "12.50", "currencyCode": "GHS"} map,
/// or null if dismissed.
class EnterAmount extends StatefulWidget {
  const EnterAmount({
    super.key,
    required this.recipient,
    this.fixedCurrencyCode,
    this.fixedCurrencyFlag,
  });

  final String recipient;

  /// When set, the currency is locked to this code and the currency picker
  /// is disabled — used by the pay-a-contact flow, where the currency is
  /// dictated by which of the recipient's accounts money is landing in, not
  /// a free choice. When null (other callers), the currency picker behaves
  /// as before.
  final String? fixedCurrencyCode;
  final String? fixedCurrencyFlag;

  @override
  State<EnterAmount> createState() => _EnterAmountState();
}

class _EnterAmountState extends State<EnterAmount> {
  // Digits typed so far, treated as a continuous stream of cents (same
  // convention the old DecimalTextInputFormatter used) — "1234" -> "12.34".
  String _digits = '';

  late String currency_code = widget.fixedCurrencyCode ?? "GHS";
  late String country_flag = widget.fixedCurrencyFlag ?? "GH";

  bool get _isLocked => widget.fixedCurrencyCode != null;

  String get _formattedAmount {
    final padded = _digits.padLeft(3, '0');
    final whole = padded.substring(0, padded.length - 2);
    final cents = padded.substring(padded.length - 2);
    final trimmedWhole = whole.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    return "$trimmedWhole.$cents";
  }

  void _onDigit(String digit) {
    if (_digits.length >= 12) return; // sane upper bound
    setState(() => _digits += digit);
  }

  void _onDelete() {
    if (_digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  void _confirm() {
    if (_digits.isEmpty || double.parse(_formattedAmount) <= 0) {
      ZentraNotifier.error("Value Missing", "Please Enter Amount!");
      return;
    }
    Navigator.of(context).pop({
      "amount": _formattedAmount,
      "currencyCode": currency_code,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            child: Container(
              width: MediaQuery.of(context).size.width,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
                vertical: AppTheme.spacingLg,
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4.5,
                        margin: const EdgeInsets.only(
                          bottom: AppTheme.spacingMd,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.gray300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (widget.recipient != '') ...[
                      Text(
                        "Send To",
                        textAlign: TextAlign.center,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.gray500,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        widget.recipient,
                        textAlign: TextAlign.center,
                        style: AppTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppTheme.spacingLg),
                    ],
                    GestureDetector(
                      onTap: _isLocked
                          ? null
                          : () => showCurrencyPicker(
                              context: context,
                              showFlag: true,
                              showCurrencyName: true,
                              showCurrencyCode: true,
                              onSelect: (Currency currency) {
                                setState(() {
                                  currency_code = currency.code;
                                  country_flag = extractCountryIsoCode(
                                    currency.code,
                                  );
                                });
                              },
                            ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CountryFlag.fromCountryCode(
                            country_flag,
                            shape: const Circle(),
                            height: 20,
                            width: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currency_code,
                            style: AppTheme.labelLarge.copyWith(
                              color: AppTheme.gray500,
                            ),
                          ),
                          if (!_isLocked) ...[
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: AppTheme.gray500,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _formattedAmount,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    CustomKeypad(onDigitPress: _onDigit, onDelete: _onDelete),
                    const SizedBox(height: AppTheme.spacingLg),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryNavy,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          onTap: _confirm,
                          child: const Padding(
                            padding: EdgeInsets.all(14.0),
                            child: Center(
                              child: Text(
                                "Confirm",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryWhite,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        child: Text(
                          "Cancel",
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.gray500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

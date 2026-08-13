import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/repositories/converter_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/main.dart';

class ZRemitForm extends StatefulWidget {
  const ZRemitForm({super.key, this.onSendSubmitted});

  final ValueChanged<Map<String, dynamic>>? onSendSubmitted;

  @override
  State<ZRemitForm> createState() => ZRemitFormState();
}

class ZRemitFormState extends State<ZRemitForm> {
  // Initialize form state key
  final _formKey = GlobalKey<FormState>();

  // Store recipient details
  final Map<String, dynamic> recipientDetails = {
    "firstName": "",
    "lastName": "",
  };

  // Store amount details
  final Map<String, dynamic> amountDetails = {
    "amount": "0.00",
    "sourceCurrencyCode": "USD",
    "destinationCurrencyCode": "EUR",
    "purpose": "",
  };

  // Store destination details
  final Map<String, dynamic> destinationDetails = {
    "destinationCountry": "",
    "payoutOption": "Mobile Money",
    "accountIdentifier": "",
    "purpose": "",
  };

  // Controllers for text inputs
  final TextEditingController _amountController = TextEditingController(
    text: "0.00",
  );
  final TextEditingController _recipientValueController =
      TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _accountDetailController =
      TextEditingController();
  final TextEditingController _countryCodeController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  // List of available currencies
  final List<String> _currencies = ["USD", "EUR", "GBP", "KES", "NGN", "GHS"];

  // Live conversion preview state. This is a deliberate one-shot call per
  // keystroke/currency change (debounced) — not a cached resource — since a
  // rate preview is a fresh action each time the inputs change.
  Timer? _previewDebounce;
  bool _previewLoading = false;
  String? _previewError;
  String? _previewRate;

  @override
  void initState() {
    super.initState();
    _schedulePreviewUpdate();
  }

  // Debounce the live-preview call so we don't hit the converter endpoint on
  // every single keystroke.
  void _schedulePreviewUpdate() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(
      const Duration(milliseconds: 400),
      _updateRecipientDisplayValue,
    );
  }

  // Calls the real conversion endpoint and updates the destination recipient
  // amount string with the live result.
  Future<void> _updateRecipientDisplayValue() async {
    final String sourceCurr = amountDetails["sourceCurrencyCode"];
    final String destCurr = amountDetails["destinationCurrencyCode"];
    final String sourceAmount = _amountController.text;

    if (sourceCurr == destCurr) {
      setState(() {
        _previewLoading = false;
        _previewError = null;
        _previewRate = null;
        _recipientValueController.text = sourceAmount;
      });
      return;
    }

    if (sourceAmount.toAmount() <= 0) {
      setState(() {
        _previewLoading = false;
        _previewError = null;
        _previewRate = null;
        _recipientValueController.text = "0.00";
      });
      return;
    }

    setState(() => _previewLoading = true);
    try {
      final result = await ConverterService.convert(
        from: sourceCurr,
        to: destCurr,
        amount: sourceAmount,
      );
      if (!mounted) return;
      setState(() {
        _previewLoading = false;
        _previewError = null;
        _previewRate = result.rate;
        _recipientValueController.text = formatMoney(result.convertedAmount);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewLoading = false;
        _previewError = "Rate unavailable";
      });
    }
  }

  // Resets all form fields/controllers back to their initial state — called
  // by the parent screen after a successful send.
  void reset() {
    setState(() {
      recipientDetails["firstName"] = "";
      recipientDetails["lastName"] = "";
      amountDetails["amount"] = "0.00";
      amountDetails["purpose"] = "";
      destinationDetails["destinationCountry"] = "";
      destinationDetails["payoutOption"] = "Mobile Money";
      destinationDetails["accountIdentifier"] = "";
      destinationDetails["purpose"] = "";
      _amountController.text = "0.00";
      _recipientValueController.clear();
      _firstNameController.clear();
      _lastNameController.clear();
      _accountDetailController.clear();
      _countryCodeController.clear();
      _reasonController.clear();
      _previewError = null;
      _previewRate = null;
    });
    _formKey.currentState?.reset();
  }

  // Input decoration helper
  InputDecoration _inputDecoration({
    String? hintText,
    String? prefixText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AppColors.textBlack.withAlpha(128)),
      prefixText: prefixText,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: AppColors.lightGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: AppColors.secondary, width: 2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: AppColors.lightGrey),
      ),
    );
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _amountController.dispose();
    _recipientValueController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _accountDetailController.dispose();
    _countryCodeController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  // Format amount input as user types
  void _formatAmount(String value) {
    String clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      _amountController.text = "0.00";
      _amountController.selection = TextSelection.fromPosition(
        TextPosition(offset: _amountController.text.length),
      );
      _schedulePreviewUpdate();
      return;
    }
    double parsed = double.parse(clean) / 100;
    String formatted = parsed.toStringAsFixed(2);
    _amountController.text = formatted;
    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: _amountController.text.length),
    );
    _schedulePreviewUpdate();
  }

  // Get dynamic field label based on selected payout option
  String _getDynamicLabel() {
    switch (destinationDetails["payoutOption"]) {
      case "Bank":
        return "Bank Account Number";
      case "Wallet":
        return "Wallet Phone Number / Zentag";
      case "Mobile Money":
      default:
        return "Mobile Phone Number";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_currencies.contains(amountDetails["sourceCurrencyCode"])) {
      amountDetails["sourceCurrencyCode"] = _currencies.first;
    }
    if (!_currencies.contains(amountDetails["destinationCurrencyCode"])) {
      amountDetails["destinationCurrencyCode"] = _currencies.length > 1
          ? _currencies[1]
          : _currencies.first;
    }

    bool isSameCurrency =
        amountDetails["sourceCurrencyCode"] ==
        amountDetails["destinationCurrencyCode"];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: AppTheme.cardDecoration,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 15,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Make Cross-Border Payment",
                    style: AppTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    "Amount",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    cursorColor: AppColors.textBlack,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: _inputDecoration(
                      suffixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: amountDetails["sourceCurrencyCode"],
                            items: _currencies
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      c,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  amountDetails["sourceCurrencyCode"] = val;
                                  _updateRecipientDisplayValue();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      _formatAmount(val);
                      amountDetails["amount"] = _amountController.text;
                    },
                    validator: (val) {
                      if (val == null || val.isEmpty || val == "0.00") {
                        return "Please enter a valid amount";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  Text(
                    isSameCurrency
                        ? "Same Currency Transfer"
                        : "Recipient Gets (Approx.)",
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textBlack,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: _recipientValueController,
                    enabled: true,
                    readOnly: true,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: _inputDecoration(
                      suffixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: amountDetails["destinationCurrencyCode"],
                            items: _currencies
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                      c,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  amountDetails["destinationCurrencyCode"] =
                                      val;
                                  destinationDetails["destinationCurrencyCode"] =
                                      val;
                                  _updateRecipientDisplayValue();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!isSameCurrency) ...[
                    const SizedBox(height: 6),
                    if (_previewLoading)
                      Row(
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Fetching live rate…",
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textBlack.withAlpha(150),
                            ),
                          ),
                        ],
                      )
                    else if (_previewError != null)
                      Text(
                        _previewError!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.main,
                        ),
                      )
                    else if (_previewRate != null)
                      Text(
                        "1 ${amountDetails["sourceCurrencyCode"]} = $_previewRate ${amountDetails["destinationCurrencyCode"]}",
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textBlack.withAlpha(150),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            decoration: AppTheme.cardDecoration,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 15,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "First Name",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _firstNameController,
                              cursorColor: AppColors.textBlack,
                              decoration: _inputDecoration(
                                hintText: "First Name",
                              ),
                              onChanged: (val) {
                                recipientDetails["firstName"] = val;
                              },
                              validator: (val) => val == null || val.isEmpty
                                  ? "Required"
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Last Name",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _lastNameController,
                              cursorColor: AppColors.textBlack,
                              decoration: _inputDecoration(
                                hintText: "Last Name",
                              ),
                              onChanged: (val) {
                                recipientDetails["lastName"] = val;
                              },
                              validator: (val) => val == null || val.isEmpty
                                  ? "Required"
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  const Text(
                    "Payout Option",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: destinationDetails["payoutOption"],
                    decoration: _inputDecoration(),
                    items: ["Mobile Money", "Bank", "Wallet"]
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          destinationDetails["payoutOption"] = val;
                          destinationDetails["accountIdentifier"] = "";
                          _accountDetailController.clear();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text(
                    _getDynamicLabel(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _accountDetailController,
                    cursorColor: AppColors.textBlack,
                    decoration: _inputDecoration(
                      hintText: "Enter ${_getDynamicLabel().toLowerCase()}",
                    ),
                    onChanged: (val) {
                      destinationDetails["accountIdentifier"] = val;
                    },
                    validator: (val) => val == null || val.isEmpty
                        ? "This field is required"
                        : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            decoration: AppTheme.cardDecoration,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20.0,
                horizontal: 15,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Reason / Purpose",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 3,
                    cursorColor: AppColors.textBlack,
                    decoration: _inputDecoration(
                      hintText: "Enter reason for transfer...",
                    ),
                    onChanged: (val) {
                      amountDetails["purpose"] = val;
                      destinationDetails["purpose"] = val;
                    },
                    validator: (val) => val == null || val.isEmpty
                        ? "Please provide a reason"
                        : null,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final combinedData = {
                            "recipientDetails": recipientDetails,
                            "amountDetails": amountDetails,
                            "destinationDetails": destinationDetails,
                          };
                          widget.onSendSubmitted?.call(combinedData);
                        }
                      },
                      child: const Text(
                        "Continue to Payment",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:country_flags/country_flags.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Ensure intl dependency is in pubspec.yaml
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/main.dart';

import 'package:zentrapay_application/features/home/getCurrencyISOCodeHelper.dart';

class EnterAmount extends StatefulWidget {
  const EnterAmount({super.key, required this.recipient});

  final String recipient;

  @override
  State<EnterAmount> createState() => _EnterAmountState();
}

class _EnterAmountState extends State<EnterAmount> {
  // Controller to handle the amount text input
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize with a default zeroed currency state string layout
    _amountController.text = "0.00";
  }

  @override
  void dispose() {
    _amountController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String currency_code = "GHS";
  String country_flag = "GH";

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Align(
        alignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            width: MediaQuery.of(context).size.width * 0.95,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.lightGrey.withAlpha(50),
                  spreadRadius: 2.0,
                  blurRadius: 10.0,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            // 1. Wrap the core container body inside a Stack
            child: Stack(
              children: [
                // 2. The scrollable content layer (padded to prevent content from going behind the close button)
                Padding(
                  padding: const EdgeInsets.only(
                    top: 25,
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.recipient != '')
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            // Clean edge alignment
                            leading: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withAlpha(20),
                                borderRadius: BorderRadius.circular(200),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 30,
                                color: AppColors.secondary,
                              ),
                            ),
                            title: Text(
                              "Send To: ${widget.recipient}",
                              style: AppStyles.header,
                            ),
                            subtitle: Text(
                              "Confirm Amount below and Send",
                              style: AppStyles.text.copyWith(
                                color: AppColors.lightGrey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Text(
                          "Enter Amount",
                          style: AppStyles.header.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _amountController,
                          focusNode: _focusNode,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 30,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            DecimalTextInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            hintText: "0.00",
                            hintStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 30,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: AppColors.lightGrey.withAlpha(100),
                                width: 1.0,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: AppColors.secondary,
                                width: 1.5,
                              ),
                            ),
                            prefixIcon: GestureDetector(
                              onTap: () => showCurrencyPicker(
                                context: context,
                                showFlag: true,
                                showCurrencyName: true,
                                showCurrencyCode: true,
                                onSelect: (Currency currency) {
                                  String isoCode = extractCountryIsoCode(
                                    currency.code,
                                  );
                                  setState(() {
                                    currency_code = currency.code;
                                    country_flag = isoCode;
                                  });
                                },
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 10,
                                children: [
                                  const SizedBox(width: 2),
                                  const Icon(Icons.arrow_drop_down),
                                  CountryFlag.fromCountryCode(
                                    country_flag,
                                    shape: const Circle(),
                                    height: 24,
                                    width: 24,
                                  ),
                                  Text(
                                    currency_code,
                                    style: TextStyle(
                                      color: AppColors.lightGrey,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: InkWell(
                              onTap: () {
                                final String finalAmount = _amountController
                                    .text
                                    .trim();
                                if (finalAmount == "" ||
                                    finalAmount == "0.00") {
                                  return ZentraNotifier.error(
                                    "Value Missing",
                                    "Please Enter Amount!",
                                  );
                                }
                                Navigator.of(context).pop({
                                  "amount": finalAmount,
                                  "currency_code": currency_code,
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Center(
                                  child: Text(
                                    "Confirm",
                                    style: AppStyles.header.copyWith(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Floating Close Button Layer anchored to the Top-Right Corner
                Positioned(
                  top: 15,
                  right: 15,
                  child: FloatingActionButton.small(
                    // .small keeps it clean & compact
                    onPressed: () {
                      Navigator.of(context).pop(null);
                    },
                    backgroundColor: AppColors.primary,
                    elevation: 2,
                    shape: const CircleBorder(),
                    child: Icon(Icons.close, color: AppColors.main, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Formatter that treats entries as a continuous stream of cents shifted right by 2 decimals
class DecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(
        text: "0.00",
        selection: const TextSelection.collapsed(offset: 4),
      );
    }

    // Parse incoming values to a double representation of absolute cents
    double value = double.parse(newValue.text);

    // Divide by 100 to shift the integer rightward into decimal fractions
    final formatter = NumberFormat("0.00", "en_US");
    String newText = formatter.format(value / 100);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

import 'package:country_flags/country_flags.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Add intl dependency to pubspec.yaml for clean currency math
import 'package:zentrapay_application/main.dart';

import '../home_wallet/widgets/getCurrencyISOCodeHelper.dart';

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
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
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
                      style: AppStyles.text,
                    ),
                  ),
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
                      // Only pass raw numbers to our custom formatter
                      DecimalTextInputFormatter(),
                      // Dynamic cents translation formatter
                    ],
                    decoration: InputDecoration(
                      hintText: "0.00",
                      hintStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 30,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
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
                            String iso_code = extractCountryIsoCode(
                              currency.code,
                            );
                            setState(() {
                              currency_code = currency.code;
                              country_flag = iso_code;
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop(null);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.main.withAlpha(20),
                              borderRadius: BorderRadius.circular(200),
                            ),
                            child: Text(
                              "Cancel",
                              style: AppStyles.text.copyWith(
                                color: AppColors.main,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 30),
                        ElevatedButton(
                          onPressed: () {
                            // Reads the exact current text value from the controller (guaranteed to be structured as XX.XX)
                            final String finalAmount = _amountController.text
                                .trim();
                            Navigator.of(context).pop({
                              "amount": finalAmount,
                              "currency_code": currency_code,
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              AppColors.secondary,
                            ),
                            padding: WidgetStateProperty.all(
                              const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                          ),
                          child: Text(
                            "Send",
                            style: AppStyles.header.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

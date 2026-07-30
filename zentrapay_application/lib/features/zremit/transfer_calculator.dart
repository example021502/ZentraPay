import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/main.dart';

class TransferCalculator extends StatefulWidget {
  final TextEditingController amountController;
  final String selectedSourceCurrency;
  final String selectedTargetCurrency;
  final double exchangeRate;
  final List<String> currencies;
  final ValueChanged<String> onSourceCurrencyChanged;
  final ValueChanged<String> onTargetCurrencyChanged;

  const TransferCalculator({
    super.key,
    required this.amountController,
    required this.selectedSourceCurrency,
    required this.selectedTargetCurrency,
    required this.exchangeRate,
    required this.currencies,
    required this.onSourceCurrencyChanged,
    required this.onTargetCurrencyChanged,
  });

  @override
  State<TransferCalculator> createState() => _TransferCalculatorState();
}

class _TransferCalculatorState extends State<TransferCalculator> {
  late double _destinationAmount;
  final FocusNode _amountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _calculateDestinationAmount();
    widget.amountController.addListener(_calculateDestinationAmount);
  }

  @override
  void dispose() {
    widget.amountController.removeListener(_calculateDestinationAmount);
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _calculateDestinationAmount() {
    final amount = double.tryParse(widget.amountController.text) ?? 0.0;
    setState(() {
      _destinationAmount = amount * widget.exchangeRate;
    });
  }

  String _formatAmountWithDecimal(String value) {
    // Remove any non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return '0.00';
    }

    // Convert to integer and divide by 100 to get decimal representation
    final intValue = int.tryParse(digitsOnly) ?? 0;
    final decimalValue = intValue / 100.0;

    return decimalValue.toStringAsFixed(2);
  }

  void _onAmountChanged(String value) {
    final originalText = widget.amountController.text;
    final formattedValue = _formatAmountWithDecimal(value);

    // Only update if the formatted value is different
    if (formattedValue != originalText) {
      final selection = widget.amountController.selection;
      final newSelection = TextSelection.collapsed(
        offset: formattedValue.length,
      );

      widget.amountController.value = TextEditingValue(
        text: formattedValue,
        selection: newSelection,
      );
    }
  }

  bool _validateFields() {
    final amount = double.tryParse(widget.amountController.text) ?? 0.0;

    if (amount <= 0) {
      ZentraNotifier.error(
        "Missing Value",
        "Please enter a valid amount to send",
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Send Money",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.lightGrey.withAlpha(40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "You Send",
                style: TextStyle(color: AppColors.textBlack, fontSize: 12),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      focusNode: _amountFocusNode,
                      controller: widget.amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onChanged: _onAmountChanged,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: widget.selectedSourceCurrency,
                    items: widget.currencies.map((String currency) {
                      return DropdownMenuItem<String>(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      widget.onSourceCurrencyChanged(newValue!);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "They Receive",
                style: TextStyle(color: AppColors.textBlack, fontSize: 12),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _destinationAmount.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: widget.selectedTargetCurrency,
                    items: widget.currencies.map((String currency) {
                      return DropdownMenuItem<String>(
                        value: currency,
                        child: Text(currency),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      widget.onTargetCurrencyChanged(newValue!);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Rate: 1 ${widget.selectedSourceCurrency} = ${widget.exchangeRate} ${widget.selectedTargetCurrency}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Text(
                        "Updated: just now",
                        style: TextStyle(fontSize: 10, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Fee: \$0.00",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

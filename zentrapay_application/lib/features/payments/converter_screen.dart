import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/repositories/converter_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/main.dart';

/// Modernized screen for performing smart currency conversions with live exchange rates.
class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  // Local state variables for managing source/destination currencies, amounts, and statuses
  String fromCurrency = 'GHS';
  String toCurrency = 'USD';
  double fromAmount = 1000.00;
  double toAmount = 0;
  double exchangeRate = 0;
  bool isSmartConversion = true;
  bool isLoading = false;
  String? errorMessage;

  // Controller to handle text editing dynamically for the input amount
  late final TextEditingController _amountController;

  // Supported currency configurations with symbols, names, and flags
  final List<Map<String, dynamic>> currencies = [
    {'code': 'GHS', 'symbol': '₵', 'name': 'Ghanaian Cedi', 'flag': '🇬🇭'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar', 'flag': '🇺🇸'},
    {'code': 'KES', 'symbol': 'KSh', 'name': 'Kenyan Shilling', 'flag': '🇰🇪'},
    {'code': 'NGN', 'symbol': '₦', 'name': 'Nigerian Naira', 'flag': '🇳🇬'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize text controller with formatted amount string
    _amountController = TextEditingController(
      text: fromAmount.toStringAsFixed(2),
    );
    _performConversion();
  }

  @override
  void dispose() {
    // Clean up controller to prevent memory leaks
    _amountController.dispose();
    super.dispose();
  }

  /// Asynchronously fetches live conversion rates and updates local state values.
  Future<void> _performConversion() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final result = await ConverterService.convert(
        from: fromCurrency,
        to: toCurrency,
        amount: fromAmount.toStringAsFixed(2),
      );
      final converted = double.tryParse(result.convertedAmount);
      final rate = double.tryParse(result.rate);
      if (converted != null) {
        setState(() {
          toAmount = converted;
          exchangeRate = rate ?? (fromAmount == 0 ? 0 : converted / fromAmount);
        });
      }
    } catch (e) {
      setState(() => errorMessage = 'Could not fetch live rates');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.main,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Smart Converter",
          style: TextStyle(color: AppColors.primary, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            _buildConverterCard(),
            const SizedBox(height: 20),
            _buildBestRateInfo(),
            const SizedBox(height: 20),
            _buildConversionOptions(),
            const SizedBox(height: 20),
            _buildConversionSummary(),
            const SizedBox(height: 20),
            _buildConvertButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Builds the modern interactive converter card with an overlapping floating swap button.
  Widget _buildConverterCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                _buildCurrencyInputField(
                  label: 'Convert from',
                  currency: fromCurrency,
                  amount: fromAmount,
                  isReadOnly: false,
                  controller: _amountController,
                  onCurrencyChanged: (value) {
                    setState(() => fromCurrency = value);
                    _performConversion();
                  },
                  onAmountChanged: (value) {
                    setState(() => fromAmount = value);
                    _performConversion();
                  },
                ),
                const SizedBox(height: 48),
                // Spacer to prevent text overlap with the floating button
                _buildCurrencyInputField(
                  label: 'Converted to',
                  currency: toCurrency,
                  amount: toAmount,
                  isReadOnly: true,
                  onCurrencyChanged: (value) {
                    setState(() => toCurrency = value);
                    _performConversion();
                  },
                ),
              ],
            ),
            // Floating center swap button
            Positioned(
              child: GestureDetector(
                onTap: _swapCurrencies,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.swap_vert,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a uniform, standardized input or output field block for currencies.
  Widget _buildCurrencyInputField({
    required String label,
    required String currency,
    required double amount,
    bool isReadOnly = false,
    TextEditingController? controller,
    required Function(String) onCurrencyChanged,
    Function(double)? onAmountChanged,
  }) {
    final currencyData = currencies.firstWhere(
      (c) => c['code'] == currency,
      orElse: () => currencies[0],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGrey, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textBlack,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                currencyData['name'],
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: isReadOnly
                    ? Text(
                        '${currencyData['symbol']} ${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                      )
                    : TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.secondary,
                              width: 2,
                              strokeAlign: 1.2,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 10,
                          ),
                        ),

                        onChanged: (val) {
                          final parsed = double.tryParse(val) ?? 0.0;
                          if (onAmountChanged != null) {
                            onAmountChanged(parsed);
                          }
                        },
                      ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.lightGrey),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currency,
                    isDense: true,
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.textBlack,
                    ),
                    items: currencies.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['code'],
                        child: Text(
                          '${c['flag']} ${c['code']}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textBlack,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onCurrencyChanged(value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the modern best-rate container styled with cardDecoration.
  Widget _buildBestRateInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Best Rate Guaranteed",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      "Live",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$fromCurrency 1 = $toCurrency ${exchangeRate.toStringAsFixed(3)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBlack,
                  ),
                ),
                const Text(
                  "Updated just now",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the conversion options list within a bounded scroll view to prevent overflow.
  Widget _buildConversionOptions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Conversion Option",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildOptionTile(
                      title: "Smart Conversion",
                      subtitle: "(Recommended)",
                      description: "Best available live rate liquidity route",
                      amount: '$toCurrency ${toAmount.toStringAsFixed(2)}',
                      fee:
                          '$fromCurrency ${(fromAmount * 0.005).toStringAsFixed(2)}',
                      isSelected: isSmartConversion,
                      onTap: () => setState(() => isSmartConversion = true),
                    ),
                    const SizedBox(height: 10),
                    _buildOptionTile(
                      title: "Low Fee Tier",
                      subtitle: "Economy spread",
                      description: "Reduced percentage charges",
                      amount:
                          '$toCurrency ${(toAmount * 0.98).toStringAsFixed(2)}',
                      fee:
                          '$fromCurrency ${(fromAmount * 0.002).toStringAsFixed(2)}',
                      isSelected: !isSmartConversion,
                      onTap: () => setState(() => isSmartConversion = false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an individual selectable option tile.
  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    String? description,
    required String amount,
    required String fee,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.lightGrey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<bool>(
              value: isSelected,
              groupValue: true,
              onChanged: (_) => onTap(),
              activeColor: AppColors.secondary,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (description != null)
                    Text(
                      description,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green,
                  ),
                ),
                Text(
                  'Fee: $fee',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textBlack,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the summary container with cardDecoration.
  Widget _buildConversionSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Conversion Summary",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              "Exchange rate:",
              "1 $fromCurrency = ${exchangeRate.toStringAsFixed(4)} $toCurrency",
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              "You receive:",
              "$toCurrency ${toAmount.toStringAsFixed(2)}",
              isHighlighted: true,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Helper row builder for summary details.
  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted ? AppColors.green : AppColors.textBlack,
          ),
        ),
      ],
    );
  }

  /// Builds the primary button using secondary color and 15 vertical padding.
  Widget _buildConvertButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : _performConversion,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : const Text(
                  "Convert Now",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
        ),
      ),
    );
  }

  /// Handles swapping currencies and syncing inputs.
  void _swapCurrencies() {
    setState(() {
      final tempCurrency = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = tempCurrency;

      final tempAmount = fromAmount;
      fromAmount = toAmount;
      toAmount = tempAmount;

      _amountController.text = fromAmount.toStringAsFixed(2);
    });
  }
}

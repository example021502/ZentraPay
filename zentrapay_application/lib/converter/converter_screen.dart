import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  String fromCurrency = 'GHS';
  String toCurrency = 'USD';
  double fromAmount = 1000.00;
  double toAmount = 87.03;
  double exchangeRate = 0.087;
  bool isSmartConversion = true;

  final List<Map<String, dynamic>> currencies = [
    {'code': 'GHS', 'symbol': '₵', 'name': 'Ghanaian Cedi', 'flag': '🇬🇭'},
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar', 'flag': '🇺🇸'},
    {'code': 'KES', 'symbol': 'KSh', 'name': 'Kenyan Shilling', 'flag': '🇰🇪'},
    {'code': 'NGN', 'symbol': '₦', 'name': 'Nigerian Naira', 'flag': '🇳🇬'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.main,
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

  Widget _buildConverterCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.main,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildCurrencyInput(
            label: 'Convert:',
            currency: fromCurrency,
            amount: fromAmount,
            onCurrencyChanged: (value) {
              setState(() => fromCurrency = value);
            },
            onAmountChanged: (value) {
              setState(() => fromAmount = value);
            },
          ),
          const SizedBox(height: 20),
          IconButton(
            onPressed: _swapCurrencies,
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.swap_vert, color: AppColors.main),
            ),
          ),
          const SizedBox(height: 20),
          _buildCurrencyInput(
            label: 'To:',
            currency: toCurrency,
            amount: toAmount,
            isReadOnly: true,
            onCurrencyChanged: (value) {
              setState(() => toCurrency = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyInput({
    required String label,
    required String currency,
    required double amount,
    bool isReadOnly = false,
    required Function(String) onCurrencyChanged,
    Function(double)? onAmountChanged,
  }) {
    final currencyData = currencies.firstWhere(
      (c) => c['code'] == currency,
      orElse: () => currencies[0],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${currencyData['symbol']} ${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      '${currencyData['code']}(${currencyData['symbol']})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.textBlack,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            currencyData['name'],
            style: const TextStyle(fontSize: 12, color: AppColors.textBlack),
          ),
        ),
      ],
    );
  }

  Widget _buildBestRateInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Best Rate Guaranteed",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              Row(
                children: [
                  const Text(
                    "Live",
                    style: TextStyle(
                      fontSize: 14,
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
                'GHS 1 = USD ${exchangeRate.toStringAsFixed(3)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              Row(
                children: [
                  const Text(
                    "Updated just now",
                    style: TextStyle(fontSize: 12, color: AppColors.textBlack),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.info_outline, size: 16),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConversionOptions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select Conversion Option",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 16),
          _buildOptionTile(
            title: "Smart Conversion",
            subtitle: "(Recommended)",
            description: "Best rate with lowest fees",
            amount: "USD 87.03",
            fee: "GHS 5.00",
            isSelected: isSmartConversion,
            onTap: () => setState(() => isSmartConversion = true),
          ),
          const SizedBox(height: 12),
          _buildOptionTile(
            title: "Low fee",
            subtitle: "Lower fee Standard rate",
            amount: "USD 80.00",
            fee: "GHS 2.00",
            isSelected: !isSmartConversion,
            onTap: () => setState(() => isSmartConversion = false),
          ),
        ],
      ),
    );
  }

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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lightGrey.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.main : AppColors.lightGrey,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<bool>(
              value: isSelected,
              groupValue: true,
              onChanged: (_) => onTap(),
              activeColor: AppColors.main,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textBlack,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (description != null)
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textBlack,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green,
                  ),
                ),
                Text(
                  'Fee: $fee',
                  style: const TextStyle(
                    fontSize: 12,
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

  Widget _buildConversionSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Conversion Summary",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow("Exchange rate:", "GHS 1 = USD 0.087"),
          const SizedBox(height: 8),
          _buildSummaryRow("Transfer fee", "-GHS 5.00", isNegative: true),
          const SizedBox(height: 8),
          _buildSummaryRow("You receive", "USD 87.03", isHighlighted: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isNegative = false,
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: AppColors.textBlack)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isNegative
                ? AppColors.textBlack
                : isHighlighted
                ? AppColors.green
                : AppColors.textBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildConvertButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Convert Now",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  void _swapCurrencies() {
    setState(() {
      final temp = fromCurrency;
      fromCurrency = toCurrency;
      toCurrency = temp;
      final tempAmount = fromAmount;
      fromAmount = toAmount;
      toAmount = tempAmount;
    });
  }
}

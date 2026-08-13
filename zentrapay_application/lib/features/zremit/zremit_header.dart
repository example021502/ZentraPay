import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/converter.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/repositories/converter_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/main.dart';

/// Live example conversion (1000 GHS -> USD) card sourced from the cached
/// [RatesRepository] — shows the real, live exchange rate for GHS. No
/// transfer-fee figure is shown since the backend doesn't expose one for
/// plain conversion; asserting a fee policy here would be unverified.
class ZRemitHeader extends StatefulWidget {
  // Optional heading, kept for callers (e.g. InstantTransferScreen) that
  // still want a title bar above the rate card. The redesigned ZRemitScreen
  // carries its own heading in a separate hero card, so it omits these.
  final String? title;
  final bool showBack;

  const ZRemitHeader({super.key, this.title, this.showBack = false});

  @override
  State<ZRemitHeader> createState() => _ZRemitHeaderState();
}

class _ZRemitHeaderState extends State<ZRemitHeader> {
  static const String _exampleSendAmount = '1000';
  static const String _quoteCurrency = 'USD';
  static const String _baseCurrency = 'GHS';

  @override
  void initState() {
    super.initState();
    RatesRepository.instance.loadForBase(_baseCurrency);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final contentFontSize = isTablet ? 18.0 : 16.0;
    final rateFontSize = isTablet ? 16.0 : 12.0;

    return ListenableBuilder(
      listenable: RatesRepository.instance,
      builder: (context, _) {
        final RatesSnapshot? snapshot = RatesRepository.instance.data;
        final bool isLoading = RatesRepository.instance.isLoading;
        final Object? error = RatesRepository.instance.error;
        final String? rate = snapshot?.rates[_quoteCurrency];

        final amountSendText = "$_baseCurrency $_exampleSendAmount";
        String amountReceivedText;
        String rateText;
        if (rate != null) {
          final converted = _exampleSendAmount.toAmount() * rate.toAmount();
          amountReceivedText = formatMoney(
            converted.toString(),
            symbol: '$_quoteCurrency ',
          );
          rateText =
              "1 $_baseCurrency = ${rate.toAmount().toStringAsFixed(4)} $_quoteCurrency";
        } else if (error != null) {
          amountReceivedText = "--";
          rateText = "Rate unavailable";
        } else {
          amountReceivedText = isLoading ? "..." : "--";
          rateText = isLoading ? "Loading..." : "--";
        }

        return _buildCard(
          context,
          isTablet: isTablet,
          contentFontSize: contentFontSize,
          rateFontSize: rateFontSize,
          amountSendText: amountSendText,
          amountReceivedText: amountReceivedText,
          rateText: rateText,
          error: error,
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required bool isTablet,
    required double contentFontSize,
    required double rateFontSize,
    required String amountSendText,
    required String amountReceivedText,
    required String rateText,
    required Object? error,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: AppTheme.coloredCardDecoration(
        AppColors.secondary,
      ).copyWith(gradient: AppTheme.secondaryGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Live Exchange Rates",
                style: AppTheme.headlineSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Icon(Icons.bolt, color: AppColors.primary, size: 20),
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.secondary, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  _rateRow("You send", amountSendText, contentFontSize),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Exchange rate",
                        style: TextStyle(
                          color: AppTheme.textBlack,
                          fontSize: rateFontSize,
                        ),
                      ),
                      Text(
                        rateText,
                        style: TextStyle(
                          color: AppTheme.textBlack,
                          fontWeight: FontWeight.w600,
                          fontSize: rateFontSize,
                        ),
                      ),
                    ],
                  ),
                  _rateRow("They receive", amountReceivedText, contentFontSize),
                ],
              ),
            ),
          ),
          if (error != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Couldn't load live rates.",
                    style: TextStyle(
                      color: AppTheme.primaryWhite,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      RatesRepository.instance.loadForBase(_baseCurrency),
                  child: Text(
                    "Retry",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              "Rates update live. Compare before you send.",
              style: TextStyle(color: AppTheme.primaryWhite, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _rateRow(String label, String value, double fontSize) => SizedBox(
    width: double.infinity,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textBlack,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          value,
          style: AppTheme.titleLarge.copyWith(
            color: AppColors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

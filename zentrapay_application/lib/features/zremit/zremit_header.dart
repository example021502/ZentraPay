import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/models/reference_data.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/payment_currency.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/features/payments/repository/cache_payments_data.dart';

/// The card inside the ZRemit [SectionHeader], styled like the ZBank header
/// card: a brand-tinted icon, the title with a status chip, a divider and the
/// money row (the wallet the transfer is paid from, with its eye toggle).
/// A line underneath shows a live example rate so users can compare before
/// they send.
class ZRemitHeader extends StatefulWidget {
  const ZRemitHeader({super.key});

  @override
  State<ZRemitHeader> createState() => _ZRemitHeaderState();
}

class _ZRemitHeaderState extends State<ZRemitHeader> {
  bool _balanceHidden = false;

  // The currency the sender pays in: the default currency of their country.
  String _home = '';
  // Another supported country's currency, used for the example rate line.
  String _example = '';

  @override
  void initState() {
    super.initState();
    WalletsRepository.instance.ensureLoaded().catchError((_) => null);
    _resolveCurrencies();
  }

  Future<void> _resolveCurrencies() async {
    final home = await PaymentCurrency.ofSender();
    if (!mounted || home.isEmpty) return;
    final countries =
        await CountriesRepository.instance.ensureLoaded().catchError(
          (_) => <AppCountry>[],
        ) ??
        const <AppCountry>[];
    var example = '';
    for (final c in countries) {
      final code = c.defaultCurrencyCode.toUpperCase();
      if (code.isNotEmpty && code != home) {
        example = code;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _home = home;
      _example = example;
    });
    RatesRepository.instance.loadForBase(home).catchError((_) => null);
  }

  double? _balance() {
    final accounts = WalletsRepository.instance.data?.fiatAccounts;
    if (accounts == null || _home.isEmpty) return null;
    for (final a in accounts) {
      if (a.currencyCode.toUpperCase() == _home) return a.balance;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(AppTheme.isDark ? 70 : 28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.brand.withAlpha(AppTheme.isDark ? 60 : 24),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.public_rounded,
                  size: 20,
                  color: AppTheme.textBlack,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send abroad',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.labelLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _home.isEmpty ? 'Cross-border transfer' : 'From your $_home wallet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingXs),
              _liveChip(),
            ],
          ),
          Divider(color: AppTheme.dividerColor, height: AppTheme.spacingLg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available to send',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.gray500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _balanceAmount(),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              _visibilityToggle(),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _rateLine(),
        ],
      ),
    );
  }

  Widget _liveChip() {
    final tone = AppTheme.successGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withAlpha(32),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: tone),
          ),
          const SizedBox(width: 5),
          Text(
            'Live rates',
            style: AppTheme.bodySmall.copyWith(
              color: tone,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceAmount() {
    final style = AppTheme.headlineMedium.copyWith(fontWeight: FontWeight.w700);
    final label = _home.isEmpty ? '' : '$_home ';
    if (_balanceHidden) {
      return Text('$label••••••', style: style.copyWith(letterSpacing: 1.2));
    }
    return ListenableBuilder(
      listenable: WalletsRepository.instance,
      builder: (context, _) {
        final balance = _balance();
        if (balance == null) {
          return Text('$label--', style: style.copyWith(color: AppTheme.gray500));
        }
        return Text(
          formatMoney(balance.toStringAsFixed(2), symbol: label),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }

  Widget _visibilityToggle() {
    return GestureDetector(
      onTap: () => setState(() => _balanceHidden = !_balanceHidden),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppTheme.brand.withAlpha(AppTheme.isDark ? 60 : 20),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _balanceHidden ? Icons.visibility : Icons.visibility_off,
          size: 18,
          color: AppTheme.textBlack,
        ),
      ),
    );
  }

  // "1 GHS = 0.0800 NGN" once rates are in; nothing while there is no rate.
  Widget _rateLine() {
    return ListenableBuilder(
      listenable: RatesRepository.instance,
      builder: (context, _) {
        final repo = RatesRepository.instance;
        final rate = _example.isEmpty ? null : repo.data?.rates[_example];
        String text;
        if (rate != null) {
          text = '1 $_home = ${rate.toAmount().toStringAsFixed(4)} $_example';
        } else if (repo.error != null) {
          text = 'Live rate unavailable right now';
        } else {
          text = 'Rates update live. Compare before you send.';
        }
        return Row(
          children: [
            Icon(Icons.bolt, size: 16, color: AppTheme.gray500),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
              ),
            ),
          ],
        );
      },
    );
  }
}

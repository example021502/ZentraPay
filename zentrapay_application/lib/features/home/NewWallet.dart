import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/wallet.dart';
import 'package:zentrapay_application/core/repositories/wallets_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/features/home/getCurrencyISOCodeHelper.dart';
import 'package:zentrapay_application/main.dart';

/// New wallet creation dialog — consumes the backend-fetched [SupportedCurrencies] list
/// directly, avoiding reference data repository mismatches.
class CustomInputDialog extends StatefulWidget {
  const CustomInputDialog({
    super.key,
    required this.type,
    required this.currencies,
  });

  /// List of supported currencies fetched directly from the backend API.
  final List<SupportedCurrencies> currencies;

  /// "Fiat" or "Crypto".
  final String type;

  @override
  State<CustomInputDialog> createState() => _CustomInputDialogState();
}

class _CustomInputDialogState extends State<CustomInputDialog> {
  final TextEditingController _accountNameController = TextEditingController();
  late String _type;

  SupportedCurrencies? _selectedCurrency;
  bool isLoading = false;

  @override
  void initState() {
    _type = widget.type;
    super.initState();
    // Initialize default selected currency if available in the passed list
    if (widget.currencies.isNotEmpty) {
      _selectedCurrency = widget.currencies.first;
    }
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Builder(
        builder: (localContext) {
          return SafeArea(
            child: Material(
              color: Colors.transparent,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      physics: const ScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 15,
                        ),
                        child: _accountField(localContext, widget.currencies),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _accountField(
    BuildContext localContext,
    List<SupportedCurrencies> currencies,
  ) {
    final isCrypto = _type == "Crypto";
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 15,
      children: [
        if (isLoading)
          const Center(
            child: CircularProgressIndicator(
              color: AppColors.main,
              strokeWidth: 2.0,
            ),
          ),
        Text(
          isCrypto ? "New Crypto Wallet" : "New Wallet",
          style: AppStyles.header,
        ),
        TextField(
          enabled: !isLoading,
          controller: _accountNameController,
          decoration: InputDecoration(
            label: const Text("Wallet Name", style: AppTheme.labelSmall),
            hintText: isCrypto ? "eg. BTC Wallet" : "eg. GHS Wallet",
            hintStyle: AppStyles.text.copyWith(color: AppColors.lightGrey),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.lightGrey.withAlpha(50),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.secondary.withAlpha(50),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Text(
              "Choose Currency",
              style: AppStyles.text.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
            if (currencies.isEmpty)
              Text(
                "No supported currencies found.",
                style: AppStyles.text.copyWith(color: AppColors.lightGrey),
              )
            else
              GestureDetector(
                onTap: () => _showCurrencyPicker(currencies),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.lightGrey.withAlpha(50),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    spacing: 10,
                    children: [
                      const Icon(Icons.arrow_drop_down),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(200),
                        ),
                        child: isCrypto
                            ? const Icon(Icons.token, size: 30)
                            : CountryFlag.fromCountryCode(
                                _selectedCurrency?.countryIsoCode.isNotEmpty ==
                                        true
                                    ? _selectedCurrency!.countryIsoCode
                                    : extractCountryIsoCode(
                                        _selectedCurrency?.currencyCode ?? 'GH',
                                      ),
                                shape: const Circle(),
                                width: 40,
                                height: 40,
                              ),
                      ),
                      Expanded(
                        child: Text(
                          _selectedCurrency != null
                              ? "${_selectedCurrency!.currencyName ?? _selectedCurrency!.currencyCode} (${_selectedCurrency!.currencyCode})"
                              : "Select currency",
                          style: AppStyles.text.copyWith(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 20,
          children: [
            InkWell(
              onTap: () => isLoading ? null : Navigator.pop(context),
              splashColor: AppColors.secondary.withAlpha(30),
              highlightColor: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Close",
                  style: AppStyles.text.copyWith(color: AppColors.main),
                ),
              ),
            ),
            InkWell(
              splashColor: AppColors.secondary.withAlpha(30),
              highlightColor: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              onTap: isLoading
                  ? null
                  : () => isCrypto
                        ? _submitCrypto(localContext)
                        : _submitFiat(localContext),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Submit",
                  style: AppStyles.header.copyWith(color: AppColors.secondary),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCurrencyPicker(List<SupportedCurrencies> currencies) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          color: AppTheme.gray50,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                final currency = currencies[index];
                final isCryptoItem = _type == "Crypto";
                return ListTile(
                  leading: isCryptoItem
                      ? const Icon(Icons.token)
                      : CountryFlag.fromCountryCode(
                          currency.countryIsoCode.isNotEmpty
                              ? currency.countryIsoCode
                              : extractCountryIsoCode(currency.currencyCode),
                          shape: const Circle(),
                        ),
                  title: Text(
                    "${currency.currencyName ?? currency.currencyCode} (${currency.currencyCode})",
                  ),
                  onTap: () {
                    setState(() => _selectedCurrency = currency);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitFiat(BuildContext localContext) async {
    if (_accountNameController.text.trim() == "" || _selectedCurrency == null) {
      ScaffoldMessenger.of(localContext).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Please enter a wallet name and pick a currency.'),
          backgroundColor: AppColors.main,
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await WalletsRepository.instance.createFiatAccount(
        accountName: _accountNameController.text.trim(),
        currencyCode: _selectedCurrency!.currencyCode,
      );
      ZentraNotifier.success("Success", "Wallet created successfully!");
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ZentraNotifier.error(
        "Error creating wallet",
        "Something went wrong, try again!",
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _submitCrypto(BuildContext localContext) async {
    if (_accountNameController.text.trim() == "" || _selectedCurrency == null) {
      ScaffoldMessenger.of(localContext).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Please enter a wallet name and pick a currency.'),
          backgroundColor: AppColors.main,
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await ApiClient().dio.post(
        '/api/wallets/crypto',
        data: {
          'currencyCode': _selectedCurrency!.currencyCode,
          'network': 'MAINNET',
          'walletAddress': '',
        },
      );
      ZentraNotifier.success("Success", "Crypto wallet created successfully!");
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ZentraNotifier.warning(
        "Coming Soon",
        "Crypto wallets are not supported yet — check back soon!",
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}

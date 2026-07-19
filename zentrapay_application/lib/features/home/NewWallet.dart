import 'dart:convert';

import 'package:country_flags/country_flags.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/features/home/api_home_wallet_services.dart';
import 'package:zentrapay_application/features/home/getCurrencyISOCodeHelper.dart';
import 'package:zentrapay_application/main.dart';

class CustomInputDialog extends StatefulWidget {
  const CustomInputDialog({
    super.key,
    required this.type,
    required this.refresh,
  });

  final String type;
  final VoidCallback refresh;

  @override
  State<CustomInputDialog> createState() => _CustomInputDialogState();
}

class _CustomInputDialogState extends State<CustomInputDialog> {
  final TextEditingController _fiatAccountNameController =
      TextEditingController();
  final TextEditingController _cryptoAccountNameController =
      TextEditingController();
  late String _type;

  final Map<String, dynamic> newFiatAccount = {
    "fiat_currency": "GHS",
    "fiat_name": "Ghanaian Cedi",
    "fiat_iso_code": "GH",
  };
  final Map<String, dynamic> newCryptoAccount = {
    "crypto_currency": "btc",
    "crypto_name": "Bitcoin",
    "crypto_iso_code":
        "https://assets.coingecko.com/coins/images/1/large/bitcoin.png",
  };

  bool isLoading = false;

  @override
  void initState() {
    _type = widget.type;
    super.initState();
  }

  @override
  void dispose() {
    _fiatAccountNameController.dispose();
    _cryptoAccountNameController.dispose();
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
                        child: _type == "Fiat"
                            ? _fiatAccountField(localContext, _type)
                            : _cryptoAccountField(localContext, _type),
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

  // ==========================================
  // FIAT ACCOUNT FIELDS
  // ===========================================
  Widget _fiatAccountField(BuildContext localContext, String type) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 15,
      children: [
        if (isLoading)
          Center(
            child: const CircularProgressIndicator(
              backgroundColor: AppColors.main,
              strokeWidth: 2.0,
            ),
          ),
        TextField(
          enabled: !isLoading,
          controller: _fiatAccountNameController,
          decoration: InputDecoration(
            label: const Text("Account Name"),
            hint: Text(
              "eg. GHS Account",
              style: AppStyles.text.copyWith(color: AppColors.lightGrey),
            ),
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
              "Choose Target Currency",
              style: AppStyles.text.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
            GestureDetector(
              onTap: () => showCurrencyPicker(
                context: context,
                physics: const ScrollPhysics(),
                showFlag: true,
                showCurrencyName: true,
                showCurrencyCode: true,
                theme: CurrencyPickerThemeData(
                  // Restricting the maximum height of the bottom sheet to exactly half the viewport height
                  bottomSheetHeight: MediaQuery.sizeOf(context).height * 0.5,

                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                ),
                onSelect: (Currency currency) {
                  String iso_code = extractCountryIsoCode(currency.code);

                  setState(() {
                    newFiatAccount["fiat_currency"] = currency.code;
                    newFiatAccount["fiat_name"] = currency.name;
                    newFiatAccount["fiat_iso_code"] = iso_code;
                  });
                },
              ),
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lightGrey.withAlpha(50)),
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
                      child: CountryFlag.fromCountryCode(
                        newFiatAccount["fiat_iso_code"] ?? "GH",
                        shape: const Circle(),
                        width: 40,
                        height: 40,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "${newFiatAccount["fiat_name"]} (${newFiatAccount["fiat_currency"]})",
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
                  : () async {
                      if (_fiatAccountNameController.text.trim() == "") {
                        if (context.mounted) {
                          ScaffoldMessenger.of(localContext).showSnackBar(
                            const SnackBar(
                              duration: Duration(seconds: 2),
                              content: Text('PLease, Enter Account Name.'),
                              backgroundColor: AppColors.main,
                            ),
                          );
                        }
                        return;
                      }

                      setState(() {
                        isLoading = true;
                      });
                      final fiatForm = {
                        "fiat_name": _fiatAccountNameController.text.trim(),
                        "fiat_currency": newFiatAccount['fiat_currency'],
                        "fiat_iso_code": newFiatAccount['fiat_iso_code'],
                      };
                      print(fiatForm);
                      try {
                        final response = await createFiatAccount(fiatForm);

                        if (!response?['success']) {
                          return ZentraNotifier.error(
                            "Error creating account",
                            response?['message'] ??
                                "Something went wrong, try again!",
                          );
                        }
                        widget.refresh();
                        ZentraNotifier.success(
                          "Success",
                          response?['message'] ??
                              "Account created Successfully!",
                        );
                        Future.delayed(
                          const Duration(seconds: 2),
                          () => Navigator.pop(context),
                        );
                      } catch (e) {
                        debugPrint("ERROR:: $e");
                      } finally {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    },
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

  // ==========================================
  // CRYPTO ACCOUNT FIELDS
  // ===========================================
  Widget _cryptoAccountField(BuildContext localContext, String type) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 15,
      children: [
        if (isLoading)
          CircularProgressIndicator(
            color: AppColors.main,
            strokeWidth: 2,
            constraints: BoxConstraints(maxHeight: 60, maxWidth: 60),
          ),
        TextField(
          enabled: !isLoading,
          controller: _cryptoAccountNameController,
          decoration: InputDecoration(
            label: const Text("Account Name"),
            hint: Text(
              "eg. BTC Account",
              style: AppStyles.text.copyWith(color: AppColors.lightGrey),
            ),
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
              "Choose Target Crypto Currency",
              style: AppStyles.text.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
            GestureDetector(
              onTap: () => _showCryptoCoinPicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lightGrey.withAlpha(50)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  spacing: 5,
                  children: [
                    const Icon(Icons.arrow_drop_down),
                    Container(
                      height: 24,
                      width: 24,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        newCryptoAccount["crypto_iso_code"],
                        width: 60,
                        height: 60,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.token, size: 40),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "${newCryptoAccount["crypto_name"]} (${newCryptoAccount["crypto_currency"].toUpperCase()})",
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
                  : () async {
                      if (_cryptoAccountNameController.text.trim() == "") {
                        if (context.mounted) {
                          ScaffoldMessenger.of(localContext).showSnackBar(
                            const SnackBar(
                              duration: Duration(seconds: 2),
                              content: Text('PLease, Enter Account Name.'),
                              backgroundColor: AppColors.main,
                            ),
                          );
                        }
                        return;
                      }
                      try {
                        setState(() {
                          isLoading = true;
                        });
                        final newCrypto = {
                          "wallet_name": newCryptoAccount['crypto_name'],
                          "currency": newCryptoAccount['crypto_currency'],
                          "country_iso_code":
                              newCryptoAccount['crypto_iso_code'],
                          "asset_plateform_id": "",
                        };
                        print(newCrypto);

                        final response = await createCryptoAccount(newCrypto);

                        if (!response?['success']) {
                          return ZentraNotifier.error(
                            "Error creating account",
                            response?['message'] ??
                                "Something went wrong, try again!",
                          );
                        }
                        widget.refresh();
                        ZentraNotifier.success(
                          "Success",
                          response?['message'] ??
                              "Account created Successfully!",
                        );
                        Future.delayed(
                          const Duration(seconds: 2),
                          () => Navigator.pop(context),
                        );
                      } catch (e) {
                        debugPrint("ERROR:: $e");
                      } finally {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    },
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

  // ==========================================
  // DYNAMIC COINGECKO CRYPTO MODAL PICKER
  // ===========================================
  void _showCryptoCoinPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return FutureBuilder<http.Response>(
          future: http.get(
            Uri.parse(
              'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=15&page=1&sparkline=false',
            ),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.statusCode != 200) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "Failed to load tokens. Please check your internet connection.",
                  ),
                ),
              );
            }

            final List<dynamic> coins = jsonDecode(snapshot.data!.body);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Select Cryptocurrency",
                    style: AppStyles.header.copyWith(fontSize: 16),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: coins.length,
                    itemBuilder: (context, index) {
                      final coin = coins[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          backgroundImage: NetworkImage(coin['image']),
                        ),
                        title: Text(
                          coin['name'],
                          style: AppStyles.text.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(coin['symbol'].toString().toUpperCase()),
                        trailing: Text(
                          "\$${coin['current_price'].toString()}",
                          style: AppStyles.text.copyWith(
                            fontSize: 12,
                            color: AppColors.lightGrey,
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            newCryptoAccount['crypto_name'] = coin['name'];
                            newCryptoAccount['crypto_code'] = coin['symbol'];
                            newCryptoAccount['crypto_iso_code'] = coin['image'];
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

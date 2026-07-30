import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/features/home/api_home_wallet_services.dart';
import 'package:zentrapay_application/main.dart';

import '../../core/utils/Notifier.dart';
import 'NewWallet.dart';
import 'getCurrencyISOCodeHelper.dart';

class HomeHeader extends StatefulWidget {
  final String title;
  final String id;

  const HomeHeader({super.key, required this.title, required this.id});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  // Key is safely initialized ONCE in the State lifetime
  final GlobalKey<TabsContainerState> tabsContainerKey =
      GlobalKey<TabsContainerState>();

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 470;
    final titleFontSize = isTablet ? 18.0 : 15.0;
    final fabSize = isTablet ? 42.0 : 36.0;
    final cardWidth = MediaQuery.of(context).size.width * 0.92;

    return SizedBox(
      width: isTablet ? 450 : cardWidth,
      child: Card(
        margin: EdgeInsets.zero,
        color: AppColors.primary,
        elevation: 0,
        shadowColor: AppColors.textBlack.withAlpha(40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          // Outer padding removed as requested
          padding: EdgeInsets.symmetric(vertical: 30, horizontal: 10),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.title,
                        style: AppStyles.header.copyWith(
                          color: AppColors.secondary,
                          fontSize: titleFontSize,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Material(
                        color: AppColors.secondary.withAlpha(20),
                        borderRadius: BorderRadius.circular(200),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(200),
                          onTap:
                              tabsContainerKey.currentState?.createNewAccount,
                          child: Padding(
                            padding: EdgeInsets.all(isTablet ? 10.0 : 8.0),
                            child: Icon(
                              Icons.add,
                              color: AppColors.secondary,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TabsContainer(key: tabsContainerKey, id: widget.id),
                ],
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: SizedBox(
                  height: fabSize,
                  width: fabSize,
                  child: FloatingActionButton(
                    heroTag: null,
                    onPressed: () {
                      tabsContainerKey.currentState?.reloadBalances();
                    },
                    backgroundColor: AppColors.secondary.withAlpha(30),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(200),
                    ),
                    child: Icon(
                      Icons.refresh,
                      color: AppColors.secondary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TabsContainer extends StatefulWidget {
  const TabsContainer({super.key, required this.id});

  final String id;

  @override
  State<TabsContainer> createState() => TabsContainerState();
}

class TabsContainerState extends State<TabsContainer>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> walletData = [];

  int selectedIndex = 0;
  bool isLoading = true;
  bool show = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    reloadBalances();
  }

  void reloadBalances() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final response = await getAllBalances();
      if (!mounted) return;
      if (!response?['success']) {
        return;
      }
      final fiatAccounts = response?['data']['fiatBalances'];
      setState(() {
        walletData = List<Map<String, dynamic>>.from(fiatAccounts);
        if (selectedIndex >= walletData.length) {
          selectedIndex = 0;
        }
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint("$e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void createNewAccount() async {
    if (!context.mounted) return;
    setState(() {
      isLoading = true;
    });
    final supportedCurrencies = await getSupportedCurrencies();
    if (!supportedCurrencies?["success"]) {
      setState(() {
        isLoading = false;
      });

      return ZentraNotifier.error(
        "Error",
        supportedCurrencies?["message"] ?? "Something went wrong! try again",
      );
    }
    setState(() {
      isLoading = false;
    });
    final List<String> currencies = List<String>.from(
      supportedCurrencies?["accounts"],
    ).map((currency) => currency.toUpperCase()).toList();

    final account = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => CustomInputDialog(
        type: widget.id == "fiat" ? "Fiat" : "Crypto",
        refresh: reloadBalances,
        currencies: currencies,
      ),
    );
    if (account != null) {
      setState(() {
        walletData.insert(0, account);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      );
    }

    if (walletData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wallet_outlined, size: 40, color: AppColors.lightGrey),
              const SizedBox(height: 12),
              Text(
                "No wallets found",
                style: TextStyle(
                  color: AppColors.lightGrey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: createNewAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Create Wallet",
                  style: AppStyles.text.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final activeWallet = walletData[selectedIndex];
    final String currencyCode = activeWallet["currency"] ?? "N/A";
    final String currentBalance = activeWallet["balance"]?.toString() ?? "0.00";

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${activeWallet["walletName"] ?? "Unnamed Wallet"}',
                    style: AppStyles.text.copyWith(
                      color: AppColors.lightGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currencyCode,
                        style: AppStyles.header.copyWith(
                          fontSize: 14,
                          color: AppColors.textBlack,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          show ? currentBalance : "••••••••",
                          style: AppStyles.header.copyWith(
                            fontSize: 22,
                            color: AppColors.textBlack,
                            fontWeight: FontWeight.bold,
                            letterSpacing: show ? 0.5 : 2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => setState(() => show = !show),
              icon: Icon(
                show
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.secondary,
                size: 24,
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < walletData.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    right: i == walletData.length - 1 ? 0 : 16.0,
                  ),
                  child: _tab(
                    country_iso_code: extractCountryIsoCode(
                      walletData[i]["currency"],
                    ),
                    currency_code: walletData[i]["currency"] ?? "N/A",
                    active: selectedIndex == i,
                    index: i,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tab({
    required String currency_code,
    required String country_iso_code,
    required bool active,
    required int index,
  }) => GestureDetector(
    onTap: () => setState(() => selectedIndex = index),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.secondary.withAlpha(15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? AppColors.secondary.withAlpha(50)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 24,
            width: 24,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: CountryFlag.fromCountryCode(
              country_iso_code,
              shape: const Circle(),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            currency_code,
            style: TextStyle(
              color: active ? AppColors.textBlack : AppColors.lightGrey,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
  );
}

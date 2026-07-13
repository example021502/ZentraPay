import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

import '../api_home_wallet_services.dart';
import 'NewWallet.dart';

// CHANGED: Converted to StatefulWidget to preserve the GlobalKey instance across scroll rebuilds
class HomeHeader extends StatefulWidget {
  final String title;
  final String id;

  const HomeHeader({super.key, required this.title, required this.id});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  // Key is now safely initialized ONCE in the State lifetime
  final GlobalKey<TabsContainerState> tabsContainerKey =
      GlobalKey<TabsContainerState>();

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 470;
    final titleFontSize = isTablet ? 20.0 : 16.0;
    final fabSize = isTablet ? 48.0 : 40.0;
    final iconSize = isTablet ? 24.0 : 20.0;
    final cardWidth = MediaQuery.of(context).size.width * 0.90;

    return SizedBox(
      width: isTablet ? 450 : cardWidth,
      child: Card(
        color: AppColors.primary,
        elevation: 0,
        shadowColor: AppColors.textBlack,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Stack(
            children: [
              Column(
                spacing: 5,
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
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          if (!context.mounted) return;
                          await showDialog<Map<String, dynamic>>(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) =>
                                CustomInputDialog(
                                  type: widget.id == "fiat" ? "Fiat" : "Crypto",
                                  refresh: tabsContainerKey
                                      .currentState!
                                      .reloadBalances,
                                ),
                          );
                        },
                        padding: EdgeInsets.all(isTablet ? 6.0 : 5.0),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                            AppColors.secondary,
                          ),
                        ),
                        icon: Icon(
                          Icons.add,
                          color: AppColors.primary,
                          size: iconSize,
                        ),
                      ),
                    ],
                  ),
                  TabsContainer(key: tabsContainerKey, id: widget.id),
                ],
              ),
              Positioned(
                bottom: isTablet ? 10.0 : 5.0,
                right: isTablet ? 15.0 : 10.0,
                child: SizedBox(
                  height: fabSize,
                  width: fabSize,
                  child: FloatingActionButton(
                    onPressed: () {
                      tabsContainerKey.currentState?.reloadBalances();
                    },
                    backgroundColor: AppColors.secondary,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(200),
                    ),
                    child: Icon(
                      Icons.refresh,
                      color: AppColors.primary,
                      size: iconSize * 1.2,
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

// CHANGED: Added AutomaticKeepAliveClientMixin so cached pages don't wipe data when scrolled away
class TabsContainerState extends State<TabsContainer>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> walletData = [];
  int selectedIndex = 0;
  bool isLoading = true;
  bool show = false;

  @override
  bool get wantKeepAlive => true; // Tells Flutter to keep this state alive in scrollable views

  @override
  void initState() {
    super.initState();
    reloadBalances();
  }

  void reloadBalances() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final isFiat = widget.id == "fiat";
      final dynamic response = isFiat
          ? await getFiatBalances()
          : await getCryptoBalances();

      if (!mounted) return;

      setState(() {
        walletData = List<Map<String, dynamic>>.from(response?['result'] ?? []);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint("SOMETHING WENT WRONG! $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // REQUIRED when using AutomaticKeepAliveClientMixin

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      );
    }

    if (walletData.isEmpty) {
      return Center(
        child: Column(
          spacing: 10,
          children: [
            Text(
              "No wallets found",
              style: TextStyle(color: AppColors.lightGrey),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!context.mounted) return;
                await showDialog<Map<String, dynamic>>(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) => CustomInputDialog(
                    type: widget.id == "fiat" ? "Fiat" : "Crypto",
                    refresh: reloadBalances,
                  ),
                );
              },
              child: Text(
                "Add Wallet",
                style: AppStyles.text.copyWith(color: AppColors.textBlack),
              ),
            ),
          ],
        ),
      );
    }

    final activeWallet = walletData[selectedIndex];
    final String currencyCode = activeWallet["currency_code"] ?? "N/A";
    final String currentBalance = activeWallet["balance"]?.toString() ?? "0.00";

    return Column(
      spacing: 10,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            Text(
              'Name: ${activeWallet["wallet_name"] ?? "Unnamed Wallet"}',
              style: AppStyles.text.copyWith(
                color: AppColors.textBlack,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
            Row(
              spacing: 10,
              children: [
                Text(currencyCode, style: AppStyles.header),
                Text(
                  show ? currentBalance : "____.__",
                  style: AppStyles.header.copyWith(
                    fontSize: show ? 26 : 20,
                    color: AppColors.textBlack,
                    fontWeight: show ? FontWeight.w900 : FontWeight.w600,
                    letterSpacing: show ? null : 5,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => show = !show),
                  child: Icon(
                    show
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        GestureDetector(
          onHorizontalDragUpdate: (details) {},
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 20,
              children: [
                for (int i = 0; i < walletData.length; i++)
                  _tab(
                    country_iso_code:
                        walletData[i]["country_iso_code"] ?? "N/A",
                    currency_code: walletData[i]["currency_code"] ?? "N/A",
                    active: selectedIndex == i,
                    index: i,
                  ),
                SizedBox(width: 50),
              ],
            ),
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
  }) => Column(
    children: [
      GestureDetector(
        onTap: () => setState(() => selectedIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 5,
          children: [
            Container(
              height: 40,
              width: 40,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: CountryFlag.fromCountryCode(
                country_iso_code,
                shape: const Circle(),
              ),
            ),
            Text(
              currency_code,
              style: TextStyle(
                color: active ? AppColors.secondary : AppColors.lightGrey,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      if (active)
        Container(
          margin: const EdgeInsets.only(top: 4),
          height: 2.5,
          width: 30,
          color: AppColors.secondary,
        ),
    ],
  );
}

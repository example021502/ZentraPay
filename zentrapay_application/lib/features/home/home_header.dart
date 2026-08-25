import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/wallet.dart';
import 'package:zentrapay_application/core/repositories/wallets_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/main.dart';

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
  @override
  Widget build(BuildContext context) {
    // Wrapping the header in a padding and Stack to create the layered wallet visual effect
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: AppTheme.titleLarge.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _headerIconButton(
                          icon: Icons.refresh,
                          onTap: () => WalletsRepository.instance.ensureLoaded(
                            forceRefresh: true,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingLg),
                        _headerIconButton(
                          icon: Icons.add,
                          onTap: () => _createNewWallet(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingLg),
                TabsContainer(id: widget.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fetches supported currencies from the backend and opens the wallet creation dialog
  Future<void> _createNewWallet(BuildContext context) async {
    try {
      // Fetch the correctly typed List<SupportedCurrencies> from the repository
      final List<SupportedCurrencies> currencies = await WalletsRepository
          .instance
          .getSupportedCurrencies();

      if (!context.mounted) return;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => CustomInputDialog(
          type: widget.id == "fiat" ? "Fiat" : "Crypto",
          currencies: currencies,
        ),
      );
    } catch (e) {
      print("ERROR:: $e");
      ZentraNotifier.warning("Warning", "Something went wrong, try again!");
    }
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(200),
      child: InkWell(
        borderRadius: BorderRadius.circular(200),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, color: AppColors.main, size: 22),
          ),
        ),
      ),
    );
  }
}

/// A unified view of either a fiat or a crypto wallet, just enough to drive
/// the tab UI below regardless of which snapshot list it came from.
class _WalletAccountData {
  final String name;
  final String currencyCode;
  final String balance;

  _WalletAccountData({
    required this.name,
    required this.currencyCode,
    required this.balance,
  });

  factory _WalletAccountData.fromFiat(FiatAccount a) => _WalletAccountData(
    name: a.accountName,
    currencyCode: a.currencyCode,
    balance: a.balance.toStringAsFixed(2),
  );

  factory _WalletAccountData.fromCrypto(CryptoAccount c) => _WalletAccountData(
    name: c.network.isNotEmpty ? c.network : c.currencyCode,
    currencyCode: c.currencyCode,
    balance: c.balance,
  );
}

class TabsContainer extends StatefulWidget {
  const TabsContainer({super.key, required this.id});

  final String id;

  @override
  State<TabsContainer> createState() => TabsContainerState();
}

class TabsContainerState extends State<TabsContainer>
    with AutomaticKeepAliveClientMixin {
  int selectedIndex = 0;
  bool show = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WalletsRepository.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListenableBuilder(
      listenable: WalletsRepository.instance,
      builder: (context, _) {
        final repo = WalletsRepository.instance;

        if (repo.isLoading && !repo.isLoaded) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: AppColors.secondary),
            ),
          );
        }

        final snapshot = repo.data;
        final walletData = widget.id == "fiat"
            ? (snapshot?.fiatAccounts ?? [])
                  .map(_WalletAccountData.fromFiat)
                  .toList()
            : (snapshot?.cryptoAccounts ?? [])
                  .map(_WalletAccountData.fromCrypto)
                  .toList();

        if (walletData.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.wallet_outlined, size: 40, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  "No wallets found",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      try {
                        // Fetch supported currencies for the empty state creation button
                        final List<SupportedCurrencies> currencies =
                            await WalletsRepository.instance
                                .getSupportedCurrencies();
                        print("The currencies received are:: $currencies");
                        if (!context.mounted) return;

                        showDialog<void>(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) => CustomInputDialog(
                            type: widget.id == "fiat" ? "Fiat" : "Crypto",
                            currencies: currencies,
                          ),
                        );
                      } catch (e) {
                        print("ERROR:: $e");
                        ZentraNotifier.warning(
                          "Warning",
                          "Something went wrong, try again!",
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 15.0,
                        ),
                        child: Text(
                          "Create Wallet",
                          style: AppStyles.text.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final index = selectedIndex >= walletData.length ? 0 : selectedIndex;
        final activeWallet = walletData[index];

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
                        activeWallet.name,
                        style: AppStyles.text.copyWith(
                          color: AppColors.primary,
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
                            activeWallet.currencyCode,
                            style: AppStyles.header.copyWith(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              show ? activeWallet.balance : "••••••••",
                              style: AppStyles.header.copyWith(
                                fontSize: 22,
                                color: AppColors.primary,
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
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ],
            ),
            AppTheme.divider(context, AppTheme.primaryWhite),
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
                          walletData[i].currencyCode,
                        ),
                        currency_code: walletData[i].currencyCode,
                        balance: walletData[i].balance,
                        active: index == i,
                        index: i,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tab({
    required String currency_code,
    required String country_iso_code,
    required String balance,
    required bool active,
    required int index,
  }) => GestureDetector(
    onTap: () => setState(() => selectedIndex = index),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.primary.withAlpha(15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? AppColors.primary.withAlpha(50) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5.0, 2.0, 5.0, 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
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
            const SizedBox(width: 10),
            Text(
              currency_code,
              style: TextStyle(
                color: active ? AppColors.primary : AppTheme.primaryWhite,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

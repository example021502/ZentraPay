import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

import 'api_home_wallet_services.dart';
import 'home_cards_carousel.dart';
import 'home_header.dart';
import 'home_quick_actions.dart';
import 'home_services_grid.dart';
import 'home_transactions.dart';

class HomeWalletMain extends StatefulWidget {
  const HomeWalletMain({super.key});

  @override
  State<HomeWalletMain> createState() => _HomeWalletMainState();
}

class _HomeWalletMainState extends State<HomeWalletMain> {
  List<Map<String, dynamic>> cards = [];
  List<Map<String, dynamic>> bills = [];
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    if (!mounted) return;
    // setState(() => isLoading = true);

    try {
      final response = await loadHomeData();
      setState(() {
        cards = List<Map<String, dynamic>>.from(response?['cards']);
        bills = List<Map<String, dynamic>>.from(response?['bills']);
        services = List<Map<String, dynamic>>.from(response?['services']);
        history = List<Map<String, dynamic>>.from(response?['history']);
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint("$e");
    } finally {
      // setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    // ======================================================
    // THE CARDS MAP TO BE IMPLEMENTED LATER
    // ======================================================

    // final headers = [
    //   {
    //     "key": "fiat_balances_card",
    //     "title": "Your Fiat Balances",
    //     "id": "fiat",
    //   },
    //   {
    //     "key": "crypto_balances_card",
    //     "title": "Your Crypto Balances",
    //     "id": "crypto",
    //   },
    // ];

    return SingleChildScrollView(
      child: Container(
        color: AppColors.primary,
        width: MediaQuery.of(context).size.width,
        child: Column(
          spacing: 20,
          children: [
            HomeHeader(
              key: ValueKey("fiat_balances"),
              title: "You wallet balances",
              id: "fiat",
            ),
            _buildWhiteSheet(isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteSheet(bool isTablet) {
    final maxWidth = isTablet ? 800.0 : double.infinity;
    final horizontalPadding = isTablet ? 40.0 : 0.0;

    return Container(
      width: maxWidth,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Center(
        child: Column(
          children: [
            const HomeQuickActions(),
            HomeCardsCarousel(cards: cards),
            HomeServicesGrid(services: services, bills: bills),
            HomeTransactions(history: history),
            if (!isTablet)
              const SizedBox(
                height: 120,
              ), // Space for floating bottom nav on mobile
          ],
        ),
      ),
    );
  }
}

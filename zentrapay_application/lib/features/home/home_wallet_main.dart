import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

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
  final PageController _controller = PageController();
  int _index = 0;

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
            const HomeCardsCarousel(),
            const HomeServicesGrid(),
            const HomeTransactions(),
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

import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

import 'widgets/home_cards_carousel.dart';
import 'widgets/home_header.dart';
import 'widgets/home_quick_actions.dart';
import 'widgets/home_services_grid.dart';
import 'widgets/home_transactions.dart';

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

    final headers = [
      {
        "key": "fiat_balances_card",
        "title": "Your Fiat Balances",
        "id": "fiat",
      },
      {
        "key": "crypto_balances_card",
        "title": "Your Crypto Balances",
        "id": "crypto",
      },
    ];

    return SingleChildScrollView(
      child: Container(
        color: AppColors.primary,
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            // FIXED: Replaced horizontal SingleChildScrollView with a constrained SizedBox
            SizedBox(
              height: isTablet ? 320 : 260,
              // Gives the PageView a definitive height barrier
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: headers.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  // Keeps padding clean between cards
                  child: HomeHeader(
                    key: ValueKey(headers[i]['key']),
                    title: headers[i]['title']!,
                    id: headers[i]['id']!,
                  ),
                ),
              ),
            ),

            // Optional: Indicator dots to show there are 2 pages
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                headers.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  width: _index == index ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _index == index
                        ? AppColors.secondary
                        : Colors.grey.shade600,
                  ),
                ),
              ),
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

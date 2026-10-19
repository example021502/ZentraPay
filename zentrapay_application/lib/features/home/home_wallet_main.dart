import 'package:flutter/material.dart';
import 'package:zentrapay_application/features/home/repository/cache_homeData.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

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
  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final maxWidth = isTablet ? 400.0 : MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: maxWidth,
              child: const HomeHeader(
                key: ValueKey("fiat_balances"),
                title: "You wallet balances",
                id: "fiat",
              ),
            ),
            SizedBox(height: AppTheme.spacingXl),
            _buildContent(isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isTablet) {
    final width = isTablet ? 400.0 : MediaQuery.of(context).size.width;
    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * (4 / 5),
      ),
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            // QUICK ACTIONS HERE
            const HomeQuickActions(),
            SizedBox(height: AppTheme.spacingMd),
            // ALL USER CARDS HERE
            // ListenableBuilder(
            //   listenable: UserCardsRepository.instance,
            //   builder: (context, _) =>
            //       LinkedCards(cards: UserCardsRepository.instance.data ?? []),
            // ),
            // ALL THE USER'S SERVICE PROVIDERS HERE
            ListenableBuilder(
              listenable: Listenable.merge([
                BillProvidersRepository.instance,
                ServiceProvidersRepository.instance,
              ]),
              builder: (context, _) => HomeServicesGrid(
                services: (ServiceProvidersRepository.instance.data ?? [])
                    .map(
                      (p) => {
                        'providerName': p.providerName,
                        'logoUrl': p.logoUrl ?? '',
                        'category': p.categoryCode,
                        'countryCode': p.countryCode,
                      },
                    )
                    .toList(),
                bills: (BillProvidersRepository.instance.data ?? [])
                    .map(
                      (p) => {
                        'billerName': p.billerName,
                        'logoUrl': p.logoUrl ?? '',
                        'category': p.categoryCode,
                        // Drives the flag fallback when the biller has no logo.
                        'countryCode': p.countryCode ?? '',
                      },
                    )
                    .toList(),
              ),
            ),
            SizedBox(height: AppTheme.spacingSm),
            // ALL THE RECENT TRANSACTIONS HERE
            ListenableBuilder(
              listenable: TransactionsRepository.instance,
              builder: (context, _) => HomeTransactions(
                history: TransactionsRepository.instance.items
                    .map(
                      (t) => {
                        'title': t.receiverName,
                        'time': t.completedAt,
                        // Signed amount straight from the backend — the "+"/"-"
                        // sign drives the icon and amount color downstream
                        // (TransactionListItem, AmountText).
                        'amount': t.amount,
                        'icon': t.isCredit
                            ? Icons.call_received_rounded
                            : Icons.call_made_rounded,
                        'type': t.transactionType,
                        // Full record so the details sheet can offer
                        // "Send Again" and show the real status/reference.
                        'transaction': t,
                      },
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

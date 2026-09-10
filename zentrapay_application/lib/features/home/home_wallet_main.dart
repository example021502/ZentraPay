import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/card.dart';
import 'package:zentrapay_application/features/home/repository/cache_homeData.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/home/widgets/LinkedCards.dart';

import 'home_header.dart';
import 'home_quick_actions.dart';
import 'home_services_grid.dart';
import 'home_transactions.dart';

// Comment: matches the transactions API's sign convention — a type_code
// ending in _CREDIT (wallet-to-wallet transfers — see PaymentsService) is
// also a credit, on top of the older fixed list below.
bool _isCreditType(String typeCode) =>
    typeCode == 'credit' || _creditTypes.contains(typeCode);

const _creditTypes = {
  'wallet_funding',
  'savings_withdrawal',
  'loan_disbursement',
  'investment_sell',
  'reward_credit',
  'refund',
};

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
      width: width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spacingMd),
            // QUICK ACTIONS HERE
            const HomeQuickActions(),
            SizedBox(height: AppTheme.spacingXl),
            // ALL USER CARDS HERE
            ListenableBuilder(
              listenable: WalletsRepository.instance,
              builder: (context, _) => LinkedCards(
                cards: ([])
                    .map(
                      (a) => AppCard(
                        cardId: '',
                        brand: '',
                        cardType: '',
                        last4: '',
                        expiryMonth: 12,
                        expiryYear: 12,
                        nfcEnabled: false,
                        qrEnabled: false,
                        status: '',
                        balance: '',
                        currencyCode: '',
                        createdAt: '',
                      ),
                    )
                    .toList(),
              ),
            ),
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
                      },
                    )
                    .toList(),
                bills: (BillProvidersRepository.instance.data ?? [])
                    .map(
                      (p) => {
                        'billerName': p.billerName,
                        'logoUrl': p.logoUrl ?? '',
                        'category': p.categoryCode,
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
                        'time': t.createdAt,
                        'amount': t.amount,
                        'icon': _isCreditType(t.transactionType)
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        'type': t.transactionType,
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

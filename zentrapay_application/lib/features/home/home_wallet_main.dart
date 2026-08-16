import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/repositories/cards_repository.dart';
import 'package:zentrapay_application/core/repositories/providers_repository.dart';
import 'package:zentrapay_application/core/repositories/transactions_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

import 'home_cards_carousel.dart';
import 'home_header.dart';
import 'home_quick_actions.dart';
import 'home_services_grid.dart';
import 'home_transactions.dart';

// Comment: matches the transactions API's sign convention — a type_code
// ending in _CREDIT (wallet-to-wallet transfers — see PaymentsService) is
// also a credit, on top of the older fixed list below.
bool _isCreditType(String typeCode) =>
    typeCode.endsWith('_CREDIT') || _creditTypes.contains(typeCode);

const _creditTypes = {
  'WALLET_FUNDING',
  'SAVINGS_WITHDRAWAL',
  'LOAN_DISBURSEMENT',
  'INVESTMENT_SELL',
  'REWARD_CREDIT',
  'REFUND',
};

class HomeWalletMain extends StatefulWidget {
  const HomeWalletMain({super.key});

  @override
  State<HomeWalletMain> createState() => _HomeWalletMainState();
}

class _HomeWalletMainState extends State<HomeWalletMain> {
  @override
  void initState() {
    super.initState();
    // Fires once per app session — each repository is a load-once cache, so
    // revisiting this tab (it stays mounted via IndexedStack) never refetches.
    CardsRepository.instance.ensureLoaded();
    BillProvidersRepository.instance.ensureLoaded();
    ServiceProvidersRepository.instance.ensureLoaded();
    TransactionsRepository.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final maxWidth = isTablet ? 400.0 : MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
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
          _buildContent(isTablet),
        ],
      ),
    );
  }

  Widget _buildContent(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            const HomeQuickActions(),
            SizedBox(height: AppTheme.spacingMd),

            ListenableBuilder(
              listenable: CardsRepository.instance,
              builder: (context, _) => HomeCardsCarousel(
                cards: (CardsRepository.instance.data ?? [])
                    .map(
                      (c) => {
                        'cardId': c.cardId,
                        'cardName': c.brand,
                        'type': c.cardType,
                        'last4': c.last4,
                        'expiry':
                            '${c.expiryMonth.toString().padLeft(2, '0')}/${c.expiryYear.toString().substring(c.expiryYear.toString().length - 2)}',
                        'status': c.status,
                      },
                    )
                    .toList(),
              ),
            ),
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

            ListenableBuilder(
              listenable: TransactionsRepository.instance,
              builder: (context, _) => HomeTransactions(
                history: TransactionsRepository.instance.items
                    .map(
                      (t) => {
                        'title': t.counterpartyName ?? t.typeCode,
                        'time': t.createdAt,
                        'amount': formatMoney(
                          t.amount,
                          symbol: '${t.currencyCode} ',
                        ),
                        'icon': _isCreditType(t.typeCode)
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        'type': t.typeCode,
                      },
                    )
                    .toList(),
              ),
            ),
            SizedBox(height: AppTheme.spacingSm),

            const SizedBox(
              height: 120,
            ), // Space for floating bottom nav on mobile
          ],
        ),
      ),
    );
  }
}

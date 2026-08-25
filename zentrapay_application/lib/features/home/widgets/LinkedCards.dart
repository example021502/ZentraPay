import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

import '../../../core/models/card.dart';
import '../../../core/theme/common_widgets.dart' as common;

/// Horizontal carousel of a user's linked bank / wallet cards.
///
/// Mirrors the Home "Your Cards" carousel (PageView) but renders each item as
/// a bank-account style tile — bank name/account number/currency/balance —
/// for the home page's "Linked Bank Accounts" section (and the ZBanking
/// overview). Accepts a flat list of account maps so callers can feed it from
/// whatever account-shaped list they already hold (fiat cards, cards, ...).
class LinkedCards extends StatefulWidget {
  const LinkedCards({super.key, required this.cards});

  final List<AppCard> cards;

  @override
  State<LinkedCards> createState() => _LinkedCardsState();
}

class _LinkedCardsState extends State<LinkedCards> {
  final PageController _controller = PageController(viewportFraction: 0.72);

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Your Cards", style: AppTheme.bodyMedium),
            const SizedBox(width: AppTheme.spacingSm),
            InkWell(
              onTap: () => common.showComingSoon(
                context,
                "Linking a card is coming soon.",
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(200),
                  color: AppTheme.secondaryNavy.withAlpha(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Icon(Icons.add_outlined, size: 22),
                ),
              ),
            ),
          ],
        ),
        cards.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(10.0),
                child: Center(
                  child: Text(
                    "No linked cards yet.",
                    style: AppTheme.labelLarge.copyWith(
                      color: AppTheme.lightGrey,
                    ),
                  ),
                ),
              )
            : Container(
                constraints: BoxConstraints(maxHeight: 210),
                child: PageView.builder(
                  controller: _controller,
                  itemCount: cards.length,
                  padEnds: false,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(left: AppTheme.spacingMd),
                    child: _accountTile(cards[i]),
                  ),
                ),
              ),
      ],
    );
  }

  /// Compact date label for the account card (e.g. "19 Aug 2026").
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _accountTile(AppCard card) {
    final name = card.brand;
    final maskedNumber = '•••• •••• •••• ${card.last4}';
    final currency = card.currencyCode;
    final balance = '$currency ${card.balance}';
    final createdAt = card.createdAt;

    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: AppTheme.secondaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: 26,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: AppTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  _formatDate(createdAt as DateTime),
                  style: AppTheme.whiteBodySmall.copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            maskedNumber,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.whiteDisplayMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Account", style: AppTheme.whiteBodySmall),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.whiteHeadline.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Balance", style: AppTheme.whiteBodySmall),
                  Text(
                    balance,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.whiteHeadline.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

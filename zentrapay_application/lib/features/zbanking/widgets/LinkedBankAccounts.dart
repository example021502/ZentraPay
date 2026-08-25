import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';

/// Horizontal carousel of a user's linked bank / wallet accounts.
///
/// Mirrors the Home "Your Cards" carousel (PageView) but renders each item as
/// a bank-account style tile — bank name/account number/currency/balance —
/// for the home page's "Linked Bank Accounts" section (and the ZBanking
/// overview). Accepts a flat list of account maps so callers can feed it from
/// whatever account-shaped list they already hold (fiat accounts, cards, ...).
class LinkedBankAccounts extends StatefulWidget {
  const LinkedBankAccounts({super.key, required this.accounts});

  final List<BankAccounts> accounts;

  @override
  State<LinkedBankAccounts> createState() => _LinkedBankAccountsState();
}

class _LinkedBankAccountsState extends State<LinkedBankAccounts> {
  final PageController _controller = PageController(viewportFraction: 0.72);

  @override
  Widget build(BuildContext context) {
    final accounts = widget.accounts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Linked Bank Accounts", style: AppTheme.bodyMedium),
              const SizedBox(width: AppTheme.spacingSm),
              InkWell(
                onTap: () => showComingSoon(
                  context,
                  "Linking a bank account is coming soon.",
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
        ),
        Container(
          constraints: BoxConstraints(maxHeight: 210),
          child: accounts.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Center(
                    child: Text(
                      "No linked bank accounts yet.",
                      style: AppTheme.labelLarge.copyWith(
                        color: AppTheme.lightGrey,
                      ),
                    ),
                  ),
                )
              : PageView.builder(
                  controller: _controller,
                  itemCount: accounts.length,
                  padEnds: false,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(left: AppTheme.spacingMd),
                    child: _accountTile(accounts[i]),
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

  Widget _accountTile(BankAccounts account) {
    final name = account.bankName;
    final maskedNumber = '•••• •••• •••• ${account.lastDigits}';
    final currency = account.currencyCode;
    final balance = '$currency ${account.balance.toStringAsFixed(2)}';
    final createdAt = account.createdAt;

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
                  _formatDate(createdAt),
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

import 'package:flutter/material.dart';

import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/zbanking/repository/cache_zbanking_data.dart';
import 'package:zentrapay_application/features/zbanking/widgets/link_bank_sheet.dart';

/// Bottom section of the ZBank screen: the horizontally scrollable strip of
/// every linked account that isn't the primary (the primary lives in the
/// header). Each card carries all the important information for that bank —
/// name, masked number, balance, currency/country and link date — plus the
/// two actions that apply to a non-primary account: make primary, unlink.
class OtherBankAccountsStrip extends StatelessWidget {
  const OtherBankAccountsStrip({super.key, required this.accounts});

  /// Non-primary accounts; the primary is filtered out by the caller.
  final List<BankAccounts> accounts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context),
        const SizedBox(height: AppTheme.spacingMd),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
            itemCount: accounts.length + 1,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppTheme.spacingMd),
            itemBuilder: (context, index) {
              if (index == accounts.length) {
                return _AddBankCard(onTap: () => showLinkBankSheet(context));
              }
              return _BankAccountCard(account: accounts[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: Row(
        children: [
          Expanded(child: Text('Other accounts', style: AppTheme.bodyMedium)),
          Text(
            '${accounts.length}',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
          ),
        ],
      ),
    );
  }
}

/// Trailing "add" card so the strip itself is the entry point for linking.
class _AddBankCard extends StatelessWidget {
  const _AddBankCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.gray50,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.brand, width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppTheme.brand.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_outlined,
                  color: AppTheme.textBlack,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text('Link a bank', style: AppTheme.labelLarge),
              const SizedBox(height: 2),
              Text(
                'Connect another account',
                textAlign: TextAlign.center,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One bank in the horizontal strip. Tapping the card promotes it to primary;
/// the overflow menu unlinks it.
class _BankAccountCard extends StatelessWidget {
  const _BankAccountCard({required this.account});

  final BankAccounts account;

  Future<void> _confirmAndRun(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required Future<void> Function() action,
    bool destructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: destructive
                ? TextButton.styleFrom(foregroundColor: AppTheme.errorRed)
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await action();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Something went wrong.')));
    }
  }

  void _makePrimary(BuildContext context) => _confirmAndRun(
    context,
    title: 'Make primary?',
    body:
        '${account.displayName} will be shown at the top of your ZBank screen.',
    confirmLabel: 'Make primary',
    action: () =>
        BankAccountsRepository.instance.setPrimary(account.userBankId),
  );

  void _unlink(BuildContext context) => _confirmAndRun(
    context,
    title: 'Unlink account?',
    body: '${account.displayName} will be removed from your ZBank screen.',
    confirmLabel: 'Unlink',
    destructive: true,
    action: () =>
        BankAccountsRepository.instance.unlinkBank(account.userBankId),
  );
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          gradient: AppTheme.secondaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.account_balance_outlined,
                  color: AppTheme.textBlack,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    account.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.whiteHeadline.copyWith(fontSize: 14),
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Account options',
                  color: AppTheme.primaryWhite,
                  icon: Icon(
                    Icons.more_vert,
                    color: AppTheme.textBlack,
                    size: 18,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'primary':
                        _makePrimary(context);
                      case 'unlink':
                        _unlink(context);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'primary',
                      child: Text('Make primary'),
                    ),
                    PopupMenuItem(value: 'unlink', child: Text('Unlink')),
                  ],
                ),
              ],
            ),
            Text(
              account.maskedNumber,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.whiteDisplayMedium.copyWith(
                fontSize: 15,
                letterSpacing: 1.2,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Balance', style: AppTheme.whiteBodySmall),
                Text(
                  account.formattedBalance,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.whiteHeadline.copyWith(fontSize: 14),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _subtitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.whiteBodySmall.copyWith(fontSize: 10),
                  ),
                ),
                Icon(Icons.nfc_outlined, color: AppTheme.textBlack, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Second line under the balance: country · currency · linked date.
  String _subtitle() {
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
    final linked = account.linkedAt;
    final linkedOn = '${linked.day} ${months[linked.month - 1]} ${linked.year}';
    return [
      if (account.countryCode.isNotEmpty) account.countryCode,
      if (account.currencyCode.isNotEmpty) account.currencyCode,
      'linked $linkedOn',
    ].join(' · ');
  }
}

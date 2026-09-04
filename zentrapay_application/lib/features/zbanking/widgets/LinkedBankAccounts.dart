import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';

/// Stacked wallet view displaying linked bank accounts.
///
/// Features a layered wallet structure where background cards peek out from behind
/// the active top card with lower height profiles, custom offsets, and fading opacities.
class LinkedBankAccounts extends StatefulWidget {
  const LinkedBankAccounts({super.key, required this.accounts});

  final List<BankAccounts> accounts;

  @override
  State<LinkedBankAccounts> createState() => _LinkedBankAccountsState();
}

class _LinkedBankAccountsState extends State<LinkedBankAccounts> {
  // Track active top card index
  int _activeIndex = 0;

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
                    color: AppTheme.gray50,
                    border: Border.all(color: AppTheme.secondaryNavy, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.textBlack.withAlpha(20),
                        spreadRadius: 5,
                        blurRadius: 8,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Icon(Icons.add_outlined, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          child: SizedBox(
            width: double.infinity,
            height:
                195, // Container height to account for card height + top offsets
            child: accounts.isEmpty
                ? _emptyAccountTile()
                : Stack(
                    clipBehavior: Clip.none,
                    children: List.generate(accounts.length, (index) {
                      // Calculate depth relative to active index
                      final depth =
                          (index - _activeIndex + accounts.length) %
                          accounts.length;

                      // Limit visible stack depth to 3 cards
                      if (depth > 2) return const SizedBox.shrink();

                      // Calculate vertical offset and opacity shift for lower wallet layers
                      final double topOffset = depth * 14.0;
                      final double opacity =
                          1.0 - (depth * 0.35); // Gradual color fade

                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        top: topOffset,
                        left: 0,
                        right: 0,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: opacity,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                // Rotate cards on tap
                                _activeIndex = (index + 1) % accounts.length;
                              });
                            },
                            child: _accountTile(
                              accounts[index],
                              isTopCard: depth == 0,
                            ),
                          ),
                        ),
                      );
                    }).reversed.toList(), // Render lower background layers first
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

  /// Placeholder empty state showing layered wallet edges behind the main empty card.
  Widget _emptyAccountTile() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Layer 3 (Deepest back layer)
        Positioned(
          bottom: 28,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: 0.3,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppTheme.secondaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
            ),
          ),
        ),
        // Layer 2 (Middle layer)
        Positioned(
          bottom: 14,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: 0.65,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppTheme.secondaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
            ),
          ),
        ),
        // Main front layer (Empty State Content)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            width: double.infinity,
            height: 160,
            padding: const EdgeInsets.all(AppTheme.spacingLg),
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white70,
                    size: 28,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    "No linked bank accounts yet.",
                    style: AppTheme.whiteHeadline.copyWith(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Card representation of bank account layer.
  Widget _accountTile(BankAccounts account, {required bool isTopCard}) {
    final name = account.bankName;
    final maskedNumber = '•••• •••• •••• ${account.lastDigits}';
    final currency = account.currencyCode;
    final balance = '$currency ${account.balance.toStringAsFixed(2)}';
    final createdAt = account.createdAt;

    return Container(
      width: double.infinity,
      height: 155, // Compact height across full width
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.whiteHeadline.copyWith(fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: 2.0,
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
          Text(
            maskedNumber,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.whiteDisplayMedium.copyWith(
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Balance", style: AppTheme.whiteBodySmall),
                  Text(
                    balance,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.whiteHeadline.copyWith(fontSize: 14),
                  ),
                ],
              ),
              const Icon(Icons.nfc_outlined, color: Colors.white70, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

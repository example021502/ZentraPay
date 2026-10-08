import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/Common/FormatDateTimeString.dart';
import 'package:zentrapay_application/features/home/widgets/NewCardOverlay.dart';
import 'package:zentrapay_application/main.dart';

import '../../../core/models/card.dart';
import '../../../core/theme/common_widgets.dart' as common;

/// Horizontal carousel of a user's linked bank / wallet cards.
class LinkedCards extends StatefulWidget {
  const LinkedCards({super.key, required this.cards});

  final List cards;

  @override
  State createState() => _LinkedCardsState();
}

class _LinkedCardsState extends State with TickerProviderStateMixin {
  final PageController _controller = PageController(viewportFraction: 0.72);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Your Cards", style: AppTheme.bodyMedium),
            const SizedBox(width: AppTheme.spacingSm),
            InkWell(
              onTap: () => _onLinkCard(context),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(200),
                  color: AppTheme.secondaryNavy.withAlpha(20),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
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
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.lightGrey,
                    ),
                  ),
                ),
              )
            : Container(
                constraints: const BoxConstraints(maxHeight: 210),
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

  Widget _accountTile(UserCard card) {
    final name = card.name;
    final maskedNumber = '•••• •••• •••• ${card.last4}';
    final currency = card.currencyCode;
    final balance = '(currency){card.balance}';
    final createdAt = card.issuedAt;

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
                  formatDateTimeString(createdAt),
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

  /// Show Link Card bottom sheet
  void _onLinkCard(BuildContext context) {
    // Create a fresh animation controller for each modal presentation
    final AnimationController customAnimationController =
        BottomSheet.createAnimationController(this)
          ..duration = const Duration(milliseconds: 1000)
          ..reverseDuration = const Duration(milliseconds: 600);

    showModalBottomSheet(
      transitionAnimationController: customAnimationController,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      backgroundColor: AppColors.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width,
            maxHeight: MediaQuery.of(context).size.height * 0.3,
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Center(
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    children: [
                      Text("Not Supported at the moment!"),
                      Icon(
                        Icons.info_outline,
                        color: AppColors.lightGrey,
                        size: 30,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

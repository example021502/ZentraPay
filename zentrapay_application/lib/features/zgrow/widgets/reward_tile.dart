import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

/// One reward tile — shared by the inline ZGrow section and the full-list
/// [RewardsAllScreen] so both render exactly the same row.
class RewardTile extends StatelessWidget {
  const RewardTile({super.key, required this.reward});

  final Reward reward;

  @override
  Widget build(BuildContext context) {
    final bool isPoints = reward.rewardType.toLowerCase() == "points";
    final bool isCash = reward.rewardType.toLowerCase() == "cash";
    final bool isBadge = reward.rewardType.toLowerCase() == "badge";
    final bool isGiftCard = reward.rewardType.toLowerCase() == "gift_card";
    final IconData icon = isGiftCard
        ? Icons.card_giftcard_outlined
        : isPoints
        ? Icons.stars_outlined
        : isCash
        ? Icons.attach_money_outlined
        : isBadge
        ? Icons.military_tech_outlined
        : Icons.redeem_outlined;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tileColor: AppTheme.brand.withAlpha(20),
        dense: true,
        leading: Container(
          decoration: BoxDecoration(
            color: AppTheme.brand.withAlpha(20),
            borderRadius: BorderRadius.circular(200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Icon(icon, size: 20, color: AppTheme.textBlack, weight: 1.5),
          ),
        ),
        title: Text(
          reward.title,
          style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          reward.description,
          style: AppTheme.labelSmall.copyWith(
            color: AppTheme.textBlack.withAlpha(100),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "worth",
              style: AppTheme.labelSmall.copyWith(
                color: AppTheme.textBlack.withAlpha(100),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${reward.currencyCode} ${reward.worth}',
              style: AppTheme.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.successGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

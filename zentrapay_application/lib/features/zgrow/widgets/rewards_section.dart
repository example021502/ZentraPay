import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrowData.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';

/// "Rewards" header + summary, collapsed entirely until RewardsRepository
/// actually has data.
class RewardsSection extends StatelessWidget {
  const RewardsSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Never collapse while loading or on error — _body() owns those states,
    // otherwise a failed request renders as blank space with no retry.

    return ListenableBuilder(
      listenable: RewardsRepository.instance,
      builder: (context, _) {
        final RewardsList? rewards = RewardsRepository.instance.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Rewards", style: AppTheme.bodyMedium),
                GestureDetector(
                  onTap: () {
                    showComingSoon(context, "More rewards");
                  },
                  child: Text(
                    "See more",
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.primaryPink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Pass the inner list of items directly instead of casting to RewardsList
            _body(rewards?.rewards.take(4).toList()),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _body(List<Reward>? rewardItems) {
    // Debug aid — `Reward`/`RewardsList` have readable toString() overrides,
    // so this prints the actual rows instead of "Instance of ...".
    if (rewardItems == null) {
      if (RewardsRepository.instance.isLoading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (RewardsRepository.instance.error != null) {
        return EmptyStateWidget(
          icon: Icons.error_outline,
          message: "Could not load rewards.",
          actionLabel: "Retry",
          onAction: () =>
              RewardsRepository.instance.ensureLoaded(forceRefresh: true),
        );
      }
      return const SizedBox.shrink();
    }

    // Check if the list of items is empty
    if (rewardItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text("No rewards yet.", style: AppTheme.labelSmall),
      );
    }

    return Column(
      spacing: 15,
      children: [
        ...rewardItems.map((reward) {
          final bool isPoints = reward.rewardType.toLowerCase() == "points";
          final bool isCash = reward.rewardType.toLowerCase() == "cash";
          final bool isBadge = reward.rewardType.toLowerCase() == "badge";
          final bool isGiftCard =
              reward.rewardType.toLowerCase() == "gift_card";
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
              contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              tileColor: AppTheme.secondaryNavy.withAlpha(20),
              dense: true,
              leading: Container(
                decoration: BoxDecoration(
                  color: AppTheme.secondaryNavy.withAlpha(20),
                  borderRadius: BorderRadius.circular(200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Icon(
                    icon,
                    size: 20,
                    color: AppTheme.textBlack,
                    weight: 1.5,
                  ),
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
        }),
      ],
    );
  }
}

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
            _body(rewards?.rewards.take(4).toList() as RewardsList),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _body(RewardsList? rewards) {
    // Debug aid — `Reward`/`RewardsList` have readable toString() overrides,
    // so this prints the actual rows instead of "Instance of ...".
    if (rewards == null) {
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

    // The cache holds a single [rewards] payload — the rows live under
    // its `.rewards` field.
    if (rewards.rewards.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text("No rewards yet.", style: AppTheme.labelSmall),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: rewards.rewards.length,
        itemBuilder: (context, index) {
          final Reward reward = rewards.rewards[index];
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

          return ListTile(
            contentPadding: EdgeInsets.zero,
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
                  color: AppTheme.secondaryNavy,
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
              children: [
                Text(
                  "worth",
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.textBlack.withAlpha(100),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${reward.currencyCode} ${reward.worth}',
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successGreen,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrowData.dart';
import 'package:zentrapay_application/features/zgrow/widgets/reward_tile.dart';
import 'package:zentrapay_application/features/zgrow/widgets/rewards_all_screen.dart';

/// "Rewards" header + latest tiles. Only the first 4 render inline; a
/// "See more" link (right of the heading) opens the full-list screen and only
/// appears when MORE than 4 rewards exist.
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
                if ((rewards?.rewards.length ?? 0) > 4)
                  GestureDetector(
                    onTap: () => RewardsAllScreen.show(context),
                    child: Text(
                      "See more",
                      style: AppTheme.bodyMedium.copyWith(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondaryNavy,
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
      children: [for (final reward in rewardItems) RewardTile(reward: reward)],
    );
  }
}

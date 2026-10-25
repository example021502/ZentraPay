import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/section_header.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrow_data.dart';
import 'package:zentrapay_application/features/zgrow/widgets/reward_tile.dart';

/// Full-list screen opened by the Rewards "See more" link. Shows every reward
/// with the same tiles as the inline section.
class RewardsAllScreen extends StatelessWidget {
  const RewardsAllScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RewardsAllScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Column(
        children: [
          SectionHeader(
            title: "Rewards",
            subtitle: "Everything you have earned",
            icon: Icons.card_giftcard_rounded,
            showBack: true,
            sheetColor: AppTheme.gray50,
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: RewardsRepository.instance,
              builder: (context, _) {
                if (RewardsRepository.instance.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<Reward> rewards =
                    RewardsRepository.instance.data?.rewards ?? const [];
                if (rewards.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingXl),
                      child: Text(
                        "Nothing here yet.",
                        style: AppTheme.bodyMedium,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingMd,
                    AppTheme.spacingSm,
                    AppTheme.spacingMd,
                    AppTheme.spacingXl,
                  ),
                  itemCount: rewards.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: RewardTile(reward: rewards[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

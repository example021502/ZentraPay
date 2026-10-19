import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrowData.dart';
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
      backgroundColor: AppTheme.primaryWhite,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text("Rewards", style: AppTheme.bodyMedium),
        backgroundColor: AppTheme.primaryWhite,
        foregroundColor: AppTheme.textBlack,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: RewardsRepository.instance,
        builder: (context, _) {
          if (RewardsRepository.instance.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<Reward> rewards =
              RewardsRepository.instance.data?.rewards ?? const [];
          if (rewards.isEmpty) {
            return const Center(
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
    );
  }
}

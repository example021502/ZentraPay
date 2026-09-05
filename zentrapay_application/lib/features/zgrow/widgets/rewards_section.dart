import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/repositories/zgrow_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/features/zgrow/widgets/rewards_card.dart';

/// "Rewards" header + summary, collapsed entirely until RewardsRepository
/// actually has data.
class RewardsSection extends StatelessWidget {
  const RewardsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: RewardsRepository.instance,
      builder: (context, _) {
        if (RewardsRepository.instance.data == null) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Rewards", style: AppTheme.bodyMedium),
            const SizedBox(height: 10),
            _body(),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Widget _body() {
    final rewards = RewardsRepository.instance.data;
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
    return RewardsCard(rewards: rewards);
  }
}

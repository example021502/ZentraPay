import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/zgrow/widgets/reward_ledger_row.dart';
import 'package:zentrapay_application/main.dart';

/// Points/tier summary + recent ledger, given a loaded RewardsSummary.
class RewardsCard extends StatelessWidget {
  const RewardsCard({super.key, required this.rewards});

  final RewardsSummary rewards;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.zgrowColor.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: AppTheme.zgrowColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${rewards.totalPoints} pts",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${rewards.tier} tier",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (rewards.recentLedger.isNotEmpty) ...[
            AppTheme.divider(context, AppColors.textBlack),
            ...rewards.recentLedger.map((e) => RewardLedgerRow(entry: e)),
          ] else ...[
            const SizedBox(height: 10),
            const Text(
              "No rewards activity yet.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}

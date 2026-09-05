import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/zgrow/widgets/reward_ledger_row.dart';
import 'package:zentrapay_application/main.dart';

/// Points/tier summary + recent ledger, given a loaded RewardsSummary.
class RewardsCard extends StatelessWidget {
  const RewardsCard({super.key, required this.reward});

  final Reward reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          
        ],
      ),
    );
  }
}

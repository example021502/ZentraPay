import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/zgrow/widgets/challenge_card_badges.dart';
import 'package:zentrapay_application/features/zgrow/widgets/challenge_card_footer.dart';

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.joining,
    required this.declining,
    required this.onJoin,
    required this.onDecline,
  });

  final Challenge challenge;
  final bool joining;
  final bool declining;
  final VoidCallback onJoin;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChallengeCardBadges(challenge: challenge),
          const SizedBox(height: 4),
          Text(
            challenge.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            challenge.description,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${challenge.participantsCount} participants",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                "Reward: ${challenge.pointsReward} pts",
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.zgrowColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ChallengeCardFooter(
            challenge: challenge,
            joining: joining,
            declining: declining,
            onJoin: onJoin,
            onDecline: onDecline,
          ),
        ],
      ),
    );
  }
}

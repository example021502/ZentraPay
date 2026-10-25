import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/zgrow/widgets/challenge_card_badges.dart';
import 'package:zentrapay_application/features/zgrow/widgets/challenge_card_footer.dart';

/// One challenge tile.
///
/// [userChallenge] is non-null only when the current user has enrolled — that
/// enrollment owns the progress figure, the saved/target amounts and the
/// Decline action. When it is null the tile renders the available-challenges
/// view instead, which only shows the catalog fields on [challenge].
class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    super.key,
    required this.challenge,
    this.userChallenge,
    this.joining = false,
    this.declining = false,
    this.onJoin,
    this.onDecline,
  });

  final Challenge challenge;
  final UserChallenge? userChallenge;
  final bool joining;
  final bool declining;
  final VoidCallback? onJoin;
  final VoidCallback? onDecline;

  bool get isJoined => userChallenge != null;

  @override
  Widget build(BuildContext context) {
    final enrollment = userChallenge;
    final target = enrollment?.targetAmount ?? challenge.targetAmount;
    final reward = challenge.rewardLabel;

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
            style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            challenge.description,
            style: AppTheme.labelSmall.copyWith(color: AppTheme.textBlack),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // durationDays is the catalog field that replaced the old
              // (never-populated) participantsCount.
              Text(
                challenge.durationDays > 0
                    ? "${challenge.durationDays} day challenge"
                    : "Ongoing challenge",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              if (reward.isNotEmpty)
                Text(
                  reward,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.textBlack,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          if (isJoined && target > 0) ...[
            const SizedBox(height: 4),
            Text(
              "Saved ${enrollment!.currentAmount.toStringAsFixed(2)} of "
              "${target.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 10),
          ChallengeCardFooter(
            challenge: challenge,
            userChallenge: enrollment,
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

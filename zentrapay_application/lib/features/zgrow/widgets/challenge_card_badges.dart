import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

/// Category + difficulty + joined/duration badges row at the top of a card.
class ChallengeCardBadges extends StatelessWidget {
  const ChallengeCardBadges({super.key, required this.challenge});

  final Challenge challenge;

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'HARD':
        return AppTheme.errorRed;
      case 'MEDIUM':
        return AppTheme.warningOrange;
      default:
        return AppTheme.zgrowColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              challenge.category.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              challenge.difficulty,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _difficultyColor(challenge.difficulty),
              ),
            ),
          ],
        ),
        Text(
          challenge.joined ? "Joined" : "${challenge.durationDays}d",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: challenge.joined ? AppTheme.zgrowColor : Colors.grey,
          ),
        ),
      ],
    );
  }
}

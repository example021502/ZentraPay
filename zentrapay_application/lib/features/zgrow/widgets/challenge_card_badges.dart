import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/Common/FormatDateTimeString.dart';

/// Category + difficulty + joined/duration badges row at the top of a card.
class ChallengeCardBadges extends StatelessWidget {
  const ChallengeCardBadges({super.key, required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          challenge.category.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          // startDate/endDate are nullable in the schema and arrive as "" when
          // unset, so fall back to durationDays rather than formatting an
          // empty timestamp.
          challenge.startDate.isNotEmpty
              ? formatDateTimeString(challenge.startDate)
              : "${challenge.durationDays} days",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.zgrowColor,
          ),
        ),
      ],
    );
  }
}

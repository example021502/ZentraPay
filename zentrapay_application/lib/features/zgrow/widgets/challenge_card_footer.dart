import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

/// Progress bar + "Decline" button when the user has enrolled, or a
/// "Join Challenge" button when they have not.
///
/// The enrollment ([userChallenge]) is what carries `progressPercentage` — a
/// bare [Challenge] from the catalog has no per-user progress, so joining and
/// declining are driven off the same object instead of a type mismatch.
class ChallengeCardFooter extends StatelessWidget {
  const ChallengeCardFooter({
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

  @override
  Widget build(BuildContext context) {
    final enrollment = userChallenge;

    if (enrollment == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: joining ? null : onJoin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.zgrowColor,
            foregroundColor: Colors.white,
          ),
          child: joining
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text("Join Challenge"),
        ),
      );
    }

    final percent = enrollment.progressPercentage.clamp(0.0, 100.0);
    final progress = (percent / 100.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.zgrowColor),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${percent.toStringAsFixed(0)}% complete",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: declining ? null : onDecline,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorRed,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: declining
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Decline", style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }
}

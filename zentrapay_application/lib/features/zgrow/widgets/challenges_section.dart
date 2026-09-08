import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrowData.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/features/zgrow/widgets/challenge_card.dart';
import 'package:zentrapay_application/main.dart';

/// Active saving challenges header + list, toggled via switch control.
class ChallengesSection extends StatefulWidget {
  const ChallengesSection({super.key});

  @override
  State<ChallengesSection> createState() => _ChallengesSectionState();
}

class _ChallengesSectionState extends State<ChallengesSection> {
  // Tracking IDs for challenges currently undergoing join network calls
  final Set<String> _joiningIds = {};

  // Tracking IDs for challenges currently undergoing decline network calls
  final Set<String> _decliningIds = {};

  // Toggle state to control visibility of challenges list content
  bool showChallenges = false;

  // Asynchronously handles joining (or re-accepting) a specific challenge
  Future<void> _joinChallenge(Challenge challenge) async {
    setState(() => _joiningIds.add(challenge.challengeId));
    try {
      await ChallengesRepository.instance.join(challenge.challengeId);
    } catch (_) {
      if (mounted) {
        ZentraNotifier.error(
          "Could not join",
          "Something went wrong joining this challenge. Try again.",
        );
      }
    } finally {
      if (mounted) setState(() => _joiningIds.remove(challenge.challengeId));
    }
  }

  // Asynchronously handles declining a joined challenge
  Future<void> _declineChallenge(Challenge challenge) async {
    setState(() => _decliningIds.add(challenge.challengeId));
    try {
      await ChallengesRepository.instance.decline(challenge.challengeId);
    } catch (_) {
      if (mounted) {
        ZentraNotifier.error(
          "Could not decline",
          "Something went wrong declining this challenge. Try again.",
        );
      }
    } finally {
      if (mounted) setState(() => _decliningIds.remove(challenge.challengeId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ChallengesRepository.instance,
      builder: (context, _) {
        final challenges = ChallengesRepository.instance.data;
        final hasChallenges = challenges != null && challenges.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  showChallenges = !showChallenges;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Gamified Savings",
                            style: AppTheme.headlineSmall,
                          ),
                          const SizedBox(width: 10),
                          // Toggle switch controlling list visibility
                          Switch(
                            value: showChallenges,
                            // Color of the thumb (circle) when the switch is ON
                            activeThumbColor: AppColors.primary,
                            // Color of the track (background bar) when the switch is ON
                            activeTrackColor: AppColors.green,
                            // Color of the thumb (circle) when the switch is OFF
                            inactiveThumbColor: AppColors.primary,
                            // Color of the track (background bar) when the switch is OFF
                            inactiveTrackColor: AppColors.main,
                            onChanged: (bool value) {
                              setState(() {
                                showChallenges = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Transform financial goals into rewarding daily habits through engaging challenges, points, and milestone badges.",
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            // Only show heading and content if toggled on and challenges data is available/non-empty
            if (showChallenges && hasChallenges) ...[
              const Text("Active Challenges", style: AppTheme.bodyMedium),
              const SizedBox(height: AppTheme.spacingMd),
              _list(),
            ],
          ],
        );
      },
    );
  }

  // Renders the dynamic challenges list, loading spinner, or error/empty states.
  // Joined challenges are grouped and shown ahead of the rest of the
  // AI-suggested pool the user hasn't joined yet.
  Widget _list() {
    final challenges = ChallengesRepository.instance.data;

    if (ChallengesRepository.instance.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (challenges == null || challenges.isEmpty) {
      return const SizedBox.shrink();
    }

    final joined = challenges.where((c) => c.joined).toList();
    final others = challenges.where((c) => !c.joined).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (joined.isNotEmpty) ...[
          Text("Joined Challenges", style: AppTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingSm),
          ..._cards(joined),
          if (others.isNotEmpty) const SizedBox(height: AppTheme.spacingMd),
        ],
        if (others.isNotEmpty) ...[
          Text("Other Challenges", style: AppTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingSm),
          ..._cards(others),
        ],
      ],
    );
  }

  List<Widget> _cards(List<Challenge> challenges) => [
    for (final challenge in challenges)
      Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: ChallengeCard(
          challenge: challenge,
          joining: _joiningIds.contains(challenge.challengeId),
          declining: _decliningIds.contains(challenge.challengeId),
          onJoin: () => _joinChallenge(challenge),
          onDecline: () => _declineChallenge(challenge),
        ),
      ),
  ];
}

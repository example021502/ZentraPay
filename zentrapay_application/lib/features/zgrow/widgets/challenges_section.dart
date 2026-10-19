import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrowData.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/features/zgrow/widgets/challenge_card.dart';
import 'package:zentrapay_application/features/zgrow/widgets/challenges_all_screen.dart';

/// Gamified challenges switch + the two challenge groups.
///
/// Layout contract (see the section header below the toggle):
/// * the whole challenge area sits in ONE constrained white card
///   (ConstrainedBox, max 620px tall) — no nested infinite scroll;
/// * group order is fixed: ALL CHALLENGES first, ACCEPTED second;
/// * each group renders at most 4 cards inline;
/// * a "See more" link sits on the far right of a group heading and only
///   appears when that group holds MORE than 4 records — it opens the
///   full-list screen for exactly that group.
class ChallengesSection extends StatefulWidget {
  const ChallengesSection({super.key});

  @override
  State createState() => _ChallengesSectionState();
}

class _ChallengesSectionState extends State {
  /// Hard cap of cards rendered inline per group; anything beyond this is
  /// reached through the group's "See more" button instead.
  static const int _inlineCap = 3;

  // Tracking IDs for challenges currently undergoing join network calls
  final Set _joiningIds = {};

  // Tracking IDs for challenges currently undergoing decline network calls
  final Set _decliningIds = {};

  // Toggle state to control visibility of challenges list content
  bool showChallenges = false;

  // Challenge ids the user declined — excluded from the "All" group so the
  // two groups never overlap.
  final Set<String> _declinedIds = {};

  @override
  void initState() {
    super.initState();
    _loadDeclined();
  }

  Future<void> _loadDeclined() async {
    try {
      final ids = await ChallengesRepository.instance.fetchDeclinedIds();
      if (mounted) setState(() => _declinedIds.addAll(ids));
    } catch (_) {
      // Best-effort: a failed declined-list fetch just means declined
      // challenges stay visible in the "All" group rather than blocking it.
    }
  }

  // Asynchronously handles joining (or re-accepting) a specific challenge.
  // After a successful join the catalog entry leaves the "All" group and
  // the enrollment lands in "Accepted": refresh enrollments (the enroll
  // response's enrollment object is appended by the repository) and let
  // the group derivation below re-split the two lists.
  Future _joinChallenge(Challenge challenge) async {
    setState(() => _joiningIds.add(challenge.id));
    try {
      await UserChallengesRepository.instance.join(challenge.id);
      await UserChallengesRepository.instance.ensureLoaded(forceRefresh: true);
    } catch (_) {
      if (mounted) {
        ZentraNotifier.error(
          "Could not join",
          "Something went wrong joining this challenge. Try again.",
        );
      }
    } finally {
      if (mounted) setState(() => _joiningIds.remove(challenge.id));
    }
  }

  // Asynchronously handles declining a challenge, whether it was accepted
  // or only offered. Both caches are updated in place:
  //  - UserChallenges drops the enrollment (if any),
  //  - the catalog row is marked declined locally so it leaves "All"
  //    immediately and stays out until the user rejoins.
  Future _declineChallenge({Challenge? challenge, UserChallenge? user}) async {
    final String id = challenge?.id ?? user?.challenge.id ?? '';
    if (id.isEmpty) return;
    setState(() => _decliningIds.add(id));
    try {
      await UserChallengesRepository.instance.decline(id);
      if (mounted) setState(() => _declinedIds.add(id));
    } catch (_) {
      if (mounted) {
        ZentraNotifier.error(
          "Could not decline",
          "Something went wrong declining this challenge. Try again.",
        );
      }
    } finally {
      if (mounted) setState(() => _decliningIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ChallengesRepository.instance,
        UserChallengesRepository.instance,
      ]),
      builder: (context, _) {
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
                            // Set border/outline color to transparent to remove switch border
                            trackOutlineColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                            // Color of the thumb (circle) when the switch is ON
                            activeThumbColor: AppTheme.primaryWhite,
                            // Color of the track (background bar) when the switch is ON
                            activeTrackColor: AppTheme.zgrowColor,
                            // Color of the thumb (circle) when the switch is OFF
                            inactiveThumbColor: AppTheme.primaryWhite,
                            // Color of the track (background bar) when the switch is OFF
                            inactiveTrackColor: AppTheme.primaryPink,
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
            // The two challenge groups render only while the toggle is on.
            if (showChallenges) _groups(),
          ],
        );
      },
    );
  }

  /// The whole challenge area: one constrained white card holding BOTH
  /// groups — "All Challenges" first, "Accepted Challenges" second.
  ///
  /// Each group shows at most [_inlineCap] cards inline. The "See more" link
  /// on the far right of a group heading appears ONLY when that group's
  /// total count exceeds the cap, and opens the full-list screen for
  /// exactly that group.
  Widget _groups() {
    final bool catalogLoading = ChallengesRepository.instance.isLoading;
    final bool acceptedLoading = UserChallengesRepository.instance.isLoading;

    final List<Challenge> catalog =
        ChallengesRepository.instance.data ?? const [];
    final List<UserChallenge> enrollments =
        UserChallengesRepository.instance.data ?? const [];

    // Accepted = enrollments that are still live (in progress or completed).
    final List<UserChallenge> accepted = enrollments
        .where((u) => u.status == 'IN_PROGRESS' || u.status == 'COMPLETED')
        .toList();

    // "All" = catalog minus anything accepted or declined locally.
    final Set<String> acceptedIds = {
      for (final u in enrollments) u.challenge.id,
    };
    final List<Challenge> all = [
      for (final c in catalog)
        if (!acceptedIds.contains(c.id) && !_declinedIds.contains(c.id)) c,
    ];

    if (catalogLoading || acceptedLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (all.isEmpty && accepted.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          "No challenges available right now. Check back soon.",
          style: AppTheme.bodySmall,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _group(
          title: "All Challenges",
          group: ChallengeGroup.all,
          total: all.length,
          cards: [
            for (final challenge in all.take(_inlineCap))
              Padding(
                key: ValueKey('all-${challenge.id}'),
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ChallengeCard(
                  challenge: challenge,
                  joining: _joiningIds.contains(challenge.id),
                  declining: _decliningIds.contains(challenge.id),
                  onJoin: () => _joinChallenge(challenge),
                  onDecline: () => _declineChallenge(challenge: challenge),
                ),
              ),
          ],
        ),
        if (all.isNotEmpty && accepted.isNotEmpty)
          const SizedBox(height: AppTheme.spacingMd),
        _group(
          title: "Accepted Challenges",
          group: ChallengeGroup.accepted,
          total: accepted.length,
          cards: [
            for (final enrollment in accepted.take(_inlineCap))
              Padding(
                key: ValueKey('accepted-${enrollment.id}'),
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ChallengeCard(
                  challenge: enrollment.challenge,
                  userChallenge: enrollment,
                  joining: _joiningIds.contains(enrollment.challenge.id),
                  declining: _decliningIds.contains(enrollment.challenge.id),
                  onJoin: () => _joinChallenge(enrollment.challenge),
                  onDecline: () => _declineChallenge(user: enrollment),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// One group heading + its inline cards. A heading with zero cards renders
  /// nothing extra; "See more" appears only when the group exceeds the cap.
  Widget _group({
    required String title,
    required ChallengeGroup group,
    required int total,
    required List<Widget> cards,
  }) {
    final bool showSeeMore = total > _inlineCap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTheme.bodyMedium),
            if (showSeeMore)
              GestureDetector(
                onTap: () => ChallengesAllScreen.show(context, group: group),
                child: Text(
                  "See more",
                  style: AppTheme.bodyMedium.copyWith(
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        // Cards stack vertically at the section width. They used to sit in a
        // horizontal SingleChildScrollView, which handed the cards UNBOUNDED
        // width and tripped the framework's "BoxConstraints forces an
        // infinite width" assertion on the footer's
        // `SizedBox(width: double.infinity)`.
        ...cards,
      ],
    );
  }
}

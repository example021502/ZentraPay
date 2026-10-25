import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/section_header.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrow_data.dart';
import 'package:zentrapay_application/features/zgrow/widgets/challenge_card.dart';

/// Which challenge group a full-list view shows.
enum ChallengeGroup { all, accepted }

/// Full-list screen opened by a group's "See more" link. Shows every card of
/// exactly one group (all catalog challenges, or all accepted enrollments)
/// with the same join/decline wiring as the inline section.
class ChallengesAllScreen extends StatefulWidget {
  const ChallengesAllScreen({super.key, required this.group});

  final ChallengeGroup group;

  static Future<void> show(
    BuildContext context, {
    required ChallengeGroup group,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChallengesAllScreen(group: group)),
    );
  }

  @override
  State<ChallengesAllScreen> createState() => _ChallengesAllScreenState();
}

class _ChallengesAllScreenState extends State<ChallengesAllScreen> {
  final Set<String> _joiningIds = {};
  final Set<String> _decliningIds = {};

  bool get _isAccepted => widget.group == ChallengeGroup.accepted;

  Future<void> _join(Challenge challenge) async {
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

  Future<void> _decline({Challenge? challenge, UserChallenge? user}) async {
    final String id = challenge?.id ?? user?.challenge.id ?? '';
    if (id.isEmpty) return;
    setState(() => _decliningIds.add(id));
    try {
      await UserChallengesRepository.instance.decline(id);
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
    final String title = _isAccepted ? "Accepted Challenges" : "All Challenges";
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Column(
        children: [
          SectionHeader(
            title: title,
            subtitle: "Join a challenge and build your savings",
            icon: Icons.emoji_events_rounded,
            showBack: true,
            sheetColor: AppTheme.gray50,
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                ChallengesRepository.instance,
                UserChallengesRepository.instance,
              ]),
              builder: (context, _) {
                final bool loading =
                    ChallengesRepository.instance.isLoading ||
                    UserChallengesRepository.instance.isLoading;
                if (loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<Widget> cards = _isAccepted
                    ? _acceptedCards()
                    : _catalogCards();
                if (cards.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingXl),
                      child: Text(
                        "Nothing here yet.",
                        style: AppTheme.bodyMedium,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingMd,
                    AppTheme.spacingSm,
                    AppTheme.spacingMd,
                    AppTheme.spacingXl,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: cards[i],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _catalogCards() {
    final List<UserChallenge> enrollments =
        UserChallengesRepository.instance.data ?? const [];
    final Set<String> acceptedIds = {
      for (final u in enrollments) u.challenge.id,
    };
    return [
      for (final c in (ChallengesRepository.instance.data ?? const []))
        if (!acceptedIds.contains(c.id))
          ChallengeCard(
            challenge: c,
            joining: _joiningIds.contains(c.id),
            declining: _decliningIds.contains(c.id),
            onJoin: () => _join(c),
            onDecline: () => _decline(challenge: c),
          ),
    ];
  }

  List<Widget> _acceptedCards() {
    final List<UserChallenge> enrollments =
        UserChallengesRepository.instance.data ?? const [];
    return [
      for (final u in enrollments)
        ChallengeCard(
          challenge: u.challenge,
          userChallenge: u,
          joining: _joiningIds.contains(u.challenge.id),
          declining: _decliningIds.contains(u.challenge.id),
          onJoin: () => _join(u.challenge),
          onDecline: () => _decline(user: u),
        ),
    ];
  }
}

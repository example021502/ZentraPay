import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/repositories/zgrow_repository.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/features/zgrow/widgets/learn_earn_carousel.dart';

/// "Learn & Earn" header + horizontal carousel, collapsed entirely until
/// LiteracyRepository actually has data.
class LearnEarnSection extends StatefulWidget {
  const LearnEarnSection({super.key});

  @override
  State<LearnEarnSection> createState() => _LearnEarnSectionState();
}

class _LearnEarnSectionState extends State<LearnEarnSection> {
  final Set<String> _completingIds = {};

  Future<void> _complete(LiteracyContent content) async {
    setState(() => _completingIds.add(content.contentId));
    try {
      final pointsEarned = await LiteracyRepository.instance.complete(
        content.contentId,
      );
      if (mounted) {
        ZentraNotifier.success(
          "Nice work!",
          "You earned $pointsEarned points.",
        );
      }
    } catch (_) {
      if (mounted) {
        ZentraNotifier.error(
          "Could not complete",
          "Something went wrong. Try again.",
        );
      }
    } finally {
      if (mounted) setState(() => _completingIds.remove(content.contentId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LiteracyRepository.instance,
      builder: (context, _) {
        if (LiteracyRepository.instance.data == null) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Learn & Earn",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            LearnEarnCarousel(
              completingIds: _completingIds,
              onComplete: _complete,
            ),
          ],
        );
      },
    );
  }
}

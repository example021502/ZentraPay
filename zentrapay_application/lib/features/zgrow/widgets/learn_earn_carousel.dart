import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/repositories/zgrow_repository.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/features/zgrow/widgets/learn_earn_card.dart';

class LearnEarnCarousel extends StatelessWidget {
  const LearnEarnCarousel({
    super.key,
    required this.completingIds,
    required this.onComplete,
  });

  final Set<String> completingIds;
  final void Function(LiteracyContent) onComplete;

  @override
  Widget build(BuildContext context) {
    final items = LiteracyRepository.instance.data;
    if (items == null) {
      if (LiteracyRepository.instance.isLoading) {
        return const SizedBox(
          height: 165,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (LiteracyRepository.instance.error != null) {
        return EmptyStateWidget(
          icon: Icons.error_outline,
          message: "Could not load learning content.",
          actionLabel: "Retry",
          onAction: () =>
              LiteracyRepository.instance.ensureLoaded(forceRefresh: true),
        );
      }
      return const SizedBox.shrink();
    }
    if (items.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: Text(
            "No lessons available yet.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    }
    return SizedBox(
      height: 165,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => LearnEarnCard(
          content: items[index],
          completing: completingIds.contains(items[index].contentId),
          onComplete: () => onComplete(items[index]),
        ),
      ),
    );
  }
}

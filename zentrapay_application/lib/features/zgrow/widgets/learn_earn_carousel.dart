import 'package:flutter/material.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrowData.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/features/zgrow/widgets/learn_earn_card.dart';

class LearnEarnCarousel extends StatelessWidget {
  const LearnEarnCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final tutorials = TutorialsRepository.instance.data?.tutorials
        .take(5)
        .toList();
    if (tutorials == null) {
      if (TutorialsRepository.instance.isLoading) {
        return const SizedBox(
          height: 165,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (TutorialsRepository.instance.error != null) {
        return EmptyStateWidget(
          icon: Icons.error_outline,
          message: "Could not load learning content.",
          actionLabel: "Retry",
          onAction: () =>
              TutorialsRepository.instance.ensureLoaded(forceRefresh: true),
        );
      }
      return const SizedBox.shrink();
    }
    if (tutorials.isEmpty) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: Text(
            "No tutorials available yet.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    }
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tutorials.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () {
            showComingSoon(context, "Playing tutorials");
          },
          child: LearnEarnCard(content: tutorials[index]),
        ),
      ),
    );
  }
}

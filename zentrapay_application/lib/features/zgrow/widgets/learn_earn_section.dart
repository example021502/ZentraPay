import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrowData.dart';
import 'package:zentrapay_application/features/zgrow/widgets/learn_earn_carousel.dart';

/// "Learn & Earn" header + horizontal carousel, collapsed entirely until
/// TutorialsRepository actually has data.
class LearnEarnSection extends StatefulWidget {
  const LearnEarnSection({super.key});

  @override
  State<LearnEarnSection> createState() => _LearnEarnSectionState();
}

class _LearnEarnSectionState extends State<LearnEarnSection> {
  @override
  Widget build(BuildContext context) {
    // Listens for changes in TutorialsRepository
    return ListenableBuilder(
      listenable: TutorialsRepository.instance,
      builder: (context, _) {
        final tutorialData = TutorialsRepository.instance.data;

        // Hide section entirely until data is available
        if (tutorialData == null) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Learn & Earn", style: AppTheme.bodyMedium),
                GestureDetector(
                  onTap: () {
                    showComingSoon(context, "See more tutorials");
                  },
                  child: Text(
                    "See more",
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.primaryPink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Learn & Earn carousel component populated with repository details
            LearnEarnCarousel(),
          ],
        );
      },
    );
  }
}

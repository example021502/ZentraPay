import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrow_data.dart';
import 'package:zentrapay_application/features/zgrow/widgets/learn_earn_carousel.dart';
import 'package:zentrapay_application/features/zgrow/widgets/tutorials_all_screen.dart';

/// "Learn & Earn" header + horizontal carousel (first 4 tutorials only),
/// collapsed entirely until TutorialsRepository actually has data.
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
        if (TutorialsRepository.instance.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

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
                Text("Tutorials", style: AppTheme.bodyMedium),
                if (tutorialData.tutorials.length > 4)
                  GestureDetector(
                    onTap: () => TutorialsAllScreen.show(context),
                    child: Text(
                      "See more",
                      style: AppTheme.bodyMedium.copyWith(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brand,
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

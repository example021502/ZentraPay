import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/section_header.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrow_data.dart';
import 'package:zentrapay_application/features/zgrow/widgets/learn_earn_card.dart';

/// Full-list screen opened by the Tutorials "See more" link. Shows every
/// tutorial with the same cards as the inline carousel.
class TutorialsAllScreen extends StatelessWidget {
  const TutorialsAllScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TutorialsAllScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Column(
        children: [
          SectionHeader(
            title: "Tutorials",
            subtitle: "Learn about money and earn",
            icon: Icons.school_rounded,
            showBack: true,
            sheetColor: AppTheme.gray50,
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: TutorialsRepository.instance,
              builder: (context, _) {
                if (TutorialsRepository.instance.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<Tutorial> tutorials =
                    TutorialsRepository.instance.data?.tutorials ?? const [];
                if (tutorials.isEmpty) {
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
                  itemCount: tutorials.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: SizedBox(
                      height: 170,
                      child: LearnEarnCard(
                        content: tutorials[i],
                        width: double.infinity,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

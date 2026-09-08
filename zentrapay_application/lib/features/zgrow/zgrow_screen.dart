import 'package:flutter/material.dart';
import 'package:zentrapay_application/features/zbanking/repository/cache_zbankingData.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrowData.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/zgrow/widgets/challenges_section.dart';
import 'package:zentrapay_application/features/zgrow/widgets/financial_tools_section.dart';
import 'package:zentrapay_application/features/zgrow/widgets/learn_earn_section.dart';
import 'package:zentrapay_application/features/zgrow/widgets/quick_actions_row.dart';
import 'package:zentrapay_application/features/zgrow/widgets/rewards_section.dart';
import 'package:zentrapay_application/features/zgrow/widgets/zgrow_hero_card.dart';

/// ZGrow tab — savings, challenges, rewards, and financial tools. Purely an
/// orchestrator: every section below is its own component under
/// features/zgrow/widgets/, each owning whatever repository/local state it
/// needs, so this file just lays them out.
class ZGrowScreen extends StatefulWidget {
  const ZGrowScreen({super.key});

  @override
  State<ZGrowScreen> createState() => _ZGrowScreenState();
}

class _ZGrowScreenState extends State<ZGrowScreen> {
  @override
  void initState() {
    super.initState();
    ChallengesRepository.instance.ensureLoaded();
    TutorialsRepository.instance.ensureLoaded();
    RewardsRepository.instance.ensureLoaded();
    BankAccountsRepository.instance.ensureLoaded();
    BankingInsightsRepository.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width > 470;
    final double maxWidth = isTablet ? 400 : MediaQuery.of(context).size.width;
    return SizedBox(
      width: maxWidth,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ZGrowHeroCard(),
            const SizedBox(height: AppTheme.spacingXl),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.gray50,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppTheme.spacingSm),
                    QuickActionsRow(),
                    SizedBox(height: AppTheme.spacingXl),
                    ChallengesSection(),
                    SizedBox(height: AppTheme.spacingMd),
                    Text("Financial Tools", style: AppTheme.bodyMedium),
                    SizedBox(height: AppTheme.spacingMd),
                    FinancialToolsSection(),
                    SizedBox(height: AppTheme.spacingMd),
                    RewardsSection(),
                    SizedBox(height: AppTheme.spacingMd),
                    LearnEarnSection(),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

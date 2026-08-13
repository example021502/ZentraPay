import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/repositories/zbanking_repository.dart';
import 'package:zentrapay_application/core/repositories/zgrow_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/zgrow/widgets/challenges_section.dart';
import 'package:zentrapay_application/features/zgrow/widgets/financial_tools_section.dart';
import 'package:zentrapay_application/features/zgrow/widgets/learn_earn_section.dart';
import 'package:zentrapay_application/features/zgrow/widgets/quick_actions_row.dart';
import 'package:zentrapay_application/features/zgrow/widgets/rewards_section.dart';
import 'package:zentrapay_application/features/zgrow/widgets/zgrow_header_section.dart';

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
    LiteracyRepository.instance.ensureLoaded();
    RewardsRepository.instance.ensureLoaded();
    SavingsRepository.instance.ensureLoaded();
    BankingInsightsRepository.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.gray50,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ZGrowHeaderSection(),
              const SizedBox(height: AppTheme.spacingMd),
              const QuickActionsRow(),
              const SizedBox(height: AppTheme.spacingMd),
              const ChallengesSection(),
              const SizedBox(height: AppTheme.spacingMd),
              const Text("Financial Tools", style: AppTheme.headlineSmall),
              const SizedBox(height: AppTheme.spacingMd),
              const FinancialToolsSection(),
              const SizedBox(height: AppTheme.spacingMd),
              const RewardsSection(),
              const SizedBox(height: AppTheme.spacingMd),
              const LearnEarnSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

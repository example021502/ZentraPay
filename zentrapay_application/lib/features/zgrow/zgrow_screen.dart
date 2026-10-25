import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/section_header.dart';
import 'package:zentrapay_application/features/zbanking/repository/cache_zbanking_data.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrow_data.dart';
import 'package:zentrapay_application/features/zgrow/widgets/challenges_section.dart';
import 'package:zentrapay_application/features/zgrow/widgets/learn_earn_section.dart';
import 'package:zentrapay_application/features/zgrow/widgets/quick_actions_row.dart';
import 'package:zentrapay_application/features/zgrow/widgets/rewards_section.dart';
import 'package:zentrapay_application/features/zgrow/widgets/zgrow_hero_card.dart';

/// ZGrow tab — savings, challenges and rewards. Purely an orchestrator: every
/// section below is its own component under features/zgrow/widgets/, each
/// owning whatever repository/local state it needs, so this file just lays
/// them out under the shared titled [SectionHeader].
class ZGrowScreen extends StatefulWidget {
  const ZGrowScreen({super.key});

  @override
  State<ZGrowScreen> createState() => _ZGrowScreenState();
}

class _ZGrowScreenState extends State<ZGrowScreen> {
  @override
  void initState() {
    super.initState();
    _loadRepositories();
  }

  /// Kicks off the first load of every repository this tab renders. Each
  /// `ensureLoaded()` rethrows on failure, so the futures are aggregated here
  /// and logged — an unreachable backend must not surface as unhandled
  /// asynchronous exceptions the moment the tab opens. The per-section
  /// ListenableBuilders already own the loading/error UI.
  Future<void> _loadRepositories() async {
    try {
      await Future.wait([
        ChallengesRepository.instance.ensureLoaded(),
        UserChallengesRepository.instance.ensureLoaded(),
        TutorialsRepository.instance.ensureLoaded(),
        RewardsRepository.instance.ensureLoaded(),
        BankAccountsRepository.instance.ensureLoaded(),
        BankingInsightsRepository.instance.ensureLoaded(),
      ]);
    } catch (e) {
      debugPrint('ZGrow initial load failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SectionScrollView(
      header: SectionHeader(
        title: "ZGrow",
        subtitle: "Save, take on challenges and earn rewards",
        icon: Icons.trending_up_rounded,
        sheetColor: AppTheme.gray50,
        child: const ZGrowHeroCard(),
      ),
      sheet: SectionSheet(
        color: AppTheme.gray50,
        topPadding: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            QuickActionsRow(),
            SizedBox(height: AppTheme.spacingXl),
            ChallengesSection(),
            SizedBox(height: AppTheme.spacingMd),
            RewardsSection(),
            SizedBox(height: AppTheme.spacingMd),
            LearnEarnSection(),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

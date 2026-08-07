import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/repositories/zbanking_repository.dart';
import 'package:zentrapay_application/core/repositories/zgrow_repository.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/features/payments/milestones_screen.dart';

import '../../core/theme/app_theme.dart';
import '../../main.dart';

class ZGrowScreen extends StatefulWidget {
  const ZGrowScreen({super.key});

  @override
  State<ZGrowScreen> createState() => _ZGrowScreenState();
}

class _ZGrowScreenState extends State<ZGrowScreen> {
  // Ids currently mid-flight for their respective POST actions, so the
  // relevant button can show a spinner and be disabled against double-taps.
  final Set<String> _joiningChallengeIds = {};
  final Set<String> _completingContentIds = {};

  @override
  void initState() {
    super.initState();
    ChallengesRepository.instance.ensureLoaded();
    LiteracyRepository.instance.ensureLoaded();
    RewardsRepository.instance.ensureLoaded();
    SavingsRepository.instance.ensureLoaded();
  }

  Future<void> _joinChallenge(Challenge challenge) async {
    setState(() => _joiningChallengeIds.add(challenge.challengeId));
    try {
      await ChallengesRepository.instance.join(challenge.challengeId);
    } catch (_) {
      if (mounted) {
        ZentraNotifier.error(
          "Could not join",
          "Something went wrong joining this challenge. Try again.",
        );
      }
    } finally {
      if (mounted) {
        setState(() => _joiningChallengeIds.remove(challenge.challengeId));
      }
    }
  }

  Future<void> _completeLiteracy(LiteracyContent content) async {
    setState(() => _completingContentIds.add(content.contentId));
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
      if (mounted) {
        setState(() => _completingContentIds.remove(content.contentId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.gray50,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActiveChallengesHeader(),
                  const SizedBox(height: 16),
                  _buildChallengesSection(),
                  const SizedBox(height: 16),
                  _buildQuickActionButtons(),
                  const SizedBox(height: 32),
                  const Text(
                    "Financial Tools",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildFinancialTools(context),
                  const SizedBox(height: 32),
                  const Text(
                    "Rewards",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildRewardsSection(),

                  const SizedBox(height: 32),
                  const Text(
                    "Learn & Earn",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildLearnAndEarnCarousel(),
                  const SizedBox(height: 32),
                  const Text(
                    "AI Couch",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildAiCouchCard(),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // Sum of savings account balances sharing the primary account's currency —
  // display-only aggregation, never sent back to the server.
  String _totalSavingsLabel() {
    final accounts = SavingsRepository.instance.data;
    if (accounts == null) {
      return SavingsRepository.instance.isLoading ? "…" : "GHS 0.00";
    }
    if (accounts.isEmpty) return "GHS 0.00";
    final currency = accounts.first.currencyCode;
    final total = accounts
        .where((a) => a.currencyCode == currency)
        .fold<double>(0, (sum, a) => sum + a.balance.toAmount());
    return formatMoney(total.toStringAsFixed(2), symbol: "$currency ");
  }

  // Build the top header section including the points-over-time fl_chart
  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            decoration: AppTheme.coloredCardDecoration(AppColors.secondary),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 15.0,
                horizontal: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Build Your Future, One Tap at a Time.",
                    style: AppTheme.titleLarge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  AppTheme.divider(context, AppColors.primary),
                  SizedBox(height: AppTheme.spacingMd),
                  const Text(
                    "Your Overall savings",
                    style: TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                  SizedBox(height: AppTheme.spacingSm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ListenableBuilder(
                        listenable: SavingsRepository.instance,
                        builder: (context, _) => Text(
                          _totalSavingsLabel(),
                          style: AppTheme.displaySmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {},
                        child: Icon(
                          Icons.visibility_off_outlined,
                          size: 22,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MilestonesScreen(),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 6, 15, 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(200),
                                color: AppColors.primary.withAlpha(70),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Icon(
                                  Icons.arrow_downward,
                                  size: 22,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingSm),
                            Text(
                              "Save Now",
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          Container(
            decoration: AppTheme.cardDecoration,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 25.0,
                horizontal: 20,
              ),
              child: _buildPointsChart(),
            ),
          ),
        ],
      ),
    );
  }

  // Derived "points over time" visualization built from RewardsRepository's
  // recentLedger — there's no dedicated chart-backing endpoint for zgrow, so
  // this reconstructs a running-total timeline from the ledger deltas
  // (recentLedger is assumed newest-first, so it's reversed to walk it
  // chronologically). Falls back to a plain summary when there's no ledger
  // activity to plot yet.
  Widget _buildPointsChart() {
    return ListenableBuilder(
      listenable: RewardsRepository.instance,
      builder: (context, _) {
        final rewards = RewardsRepository.instance.data;
        if (rewards == null) {
          if (RewardsRepository.instance.isLoading) {
            return const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (RewardsRepository.instance.error != null) {
            return SizedBox(
              height: 160,
              child: EmptyStateWidget(
                icon: Icons.error_outline,
                message: "Could not load your points activity.",
                actionLabel: "Retry",
                onAction: () =>
                    RewardsRepository.instance.ensureLoaded(forceRefresh: true),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        final entries = rewards.recentLedger;
        if (entries.isEmpty) {
          return SizedBox(
            height: 160,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${rewards.totalPoints} pts",
                    style: AppTheme.displaySmall,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "No recent points activity yet.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // Walk the ledger oldest -> newest, reconstructing a running total so
        // the earliest plotted point is the balance before these entries.
        final chronological = entries.reversed.toList();
        final deltaSum = entries.fold<int>(0, (sum, e) => sum + e.points);
        double running = (rewards.totalPoints - deltaSum).toDouble();
        final spots = <FlSpot>[FlSpot(0, running)];
        for (var i = 0; i < chronological.length; i++) {
          running += chronological[i].points;
          spots.add(FlSpot((i + 1).toDouble(), running));
        }

        return Column(
          children: [
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withAlpha(50),
                      strokeWidth: 0.8,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: AppColors.textBlack,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppTheme.zgrowColor,
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Points earned over time (${rewards.totalPoints} pts total, ${rewards.tier} tier)",
              style: const TextStyle(color: AppColors.textBlack, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  // Build header for active saving challenges
  Widget _buildActiveChallengesHeader() {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Active Saving Challenges",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.add, color: AppColors.textBlack),
                onPressed: () => ZentraNotifier.success(
                  "New Challenge",
                  "Not yet implemented",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ChallengesRepository-backed list of challenge cards.
  Widget _buildChallengesSection() {
    return ListenableBuilder(
      listenable: ChallengesRepository.instance,
      builder: (context, _) {
        final challenges = ChallengesRepository.instance.data;
        if (challenges == null) {
          if (ChallengesRepository.instance.isLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (ChallengesRepository.instance.error != null) {
            return EmptyStateWidget(
              icon: Icons.error_outline,
              message: "Could not load challenges.",
              actionLabel: "Retry",
              onAction: () => ChallengesRepository.instance.ensureLoaded(
                forceRefresh: true,
              ),
            );
          }
          return const SizedBox.shrink();
        }
        if (challenges.isEmpty) {
          return const EmptyStateWidget(
            message: "No saving challenges available right now.",
          );
        }
        return Column(
          children: [
            for (final challenge in challenges)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildChallengeCard(challenge),
              ),
          ],
        );
      },
    );
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'HARD':
        return AppTheme.errorRed;
      case 'MEDIUM':
        return AppTheme.warningOrange;
      default:
        return AppTheme.zgrowColor;
    }
  }

  // Build card UI for a single Challenge, supporting joined/not-joined states.
  Widget _buildChallengeCard(Challenge challenge) {
    final joined = challenge.joined;
    final progress = (challenge.progressPercent / 100.0).clamp(0.0, 1.0);
    final joining = _joiningChallengeIds.contains(challenge.challengeId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    challenge.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    challenge.difficulty,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _difficultyColor(challenge.difficulty),
                    ),
                  ),
                ],
              ),
              Text(
                joined ? "Joined" : "${challenge.durationDays}d",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: joined ? AppTheme.zgrowColor : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            challenge.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            challenge.description,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${challenge.participantsCount} participants",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                "Reward: ${challenge.pointsReward} pts",
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.zgrowColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (joined) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.zgrowColor,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "${challenge.progressPercent}% complete",
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: joining ? null : () => _joinChallenge(challenge),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.zgrowColor,
                  foregroundColor: Colors.white,
                ),
                child: joining
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Join Challenge"),
              ),
            ),
        ],
      ),
    );
  }

  // Build layout for quick action buttons wrapped in cardDecoration
  Widget _buildQuickActionButtons() {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _quickActionButton(Icons.verified_user_outlined, "Emergence\nFund"),
          _quickActionButton(
            Icons.account_balance_wallet_outlined,
            "Pay-Loans",
          ),
          _quickActionButton(Icons.trending_up, "Z-Invest"),
        ],
      ),
    );
  }

  // Build a single quick action button widget
  Widget _quickActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.secondary.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.textBlack, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // RewardsRepository-backed summary: totalPoints, tier, and recent ledger.
  Widget _buildRewardsSection() {
    return ListenableBuilder(
      listenable: RewardsRepository.instance,
      builder: (context, _) {
        final rewards = RewardsRepository.instance.data;
        if (rewards == null) {
          if (RewardsRepository.instance.isLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (RewardsRepository.instance.error != null) {
            return EmptyStateWidget(
              icon: Icons.error_outline,
              message: "Could not load rewards.",
              actionLabel: "Retry",
              onAction: () =>
                  RewardsRepository.instance.ensureLoaded(forceRefresh: true),
            );
          }
          return const SizedBox.shrink();
        }

        return Container(
          decoration: AppTheme.cardDecoration,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.zgrowColor.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          color: AppTheme.zgrowColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${rewards.totalPoints} pts",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${rewards.tier} tier",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (rewards.recentLedger.isNotEmpty) ...[
                AppTheme.divider(context, AppColors.textBlack),
                ...rewards.recentLedger.map(_ledgerRow),
              ] else ...[
                const SizedBox(height: 10),
                const Text(
                  "No rewards activity yet.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _ledgerRow(PointsLedgerEntry entry) {
    final positive = entry.points >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              entry.reason,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "${positive ? '+' : ''}${entry.points} pts",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: positive ? AppTheme.zgrowColor : AppTheme.errorRed,
            ),
          ),
        ],
      ),
    );
  }

  // LiteracyRepository-backed horizontal carousel for learn & earn modules.
  Widget _buildLearnAndEarnCarousel() {
    return ListenableBuilder(
      listenable: LiteracyRepository.instance,
      builder: (context, _) {
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
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _learnCard(items[index]),
          ),
        );
      },
    );
  }

  // Build card component for a single LiteracyContent item.
  Widget _learnCard(LiteracyContent content) {
    final completing = _completingContentIds.contains(content.contentId);
    return Container(
      width: 190,
      decoration: BoxDecoration(
        color: const Color(0xFF1A0059),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.video_library_outlined, color: Colors.white, size: 28),
              Text(
                "${content.durationMinutes} mins",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          Text(
            content.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (content.completed)
            Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                SizedBox(width: 4),
                Text(
                  "Completed",
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: completing ? null : () => _completeLiteracy(content),
                child: completing
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        "Complete (+${content.pointsReward})",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  // Build section for interactive financial tools using cardDecoration
  Widget _buildFinancialTools(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          _toolTile(
            Icons.list_alt,
            "Budget Planner",
            onTap: () => ZentraNotifier.success(
              "Financial Tool",
              "This feature is coming soon",
            ),
          ),
          const SizedBox(height: 8),
          _toolTile(
            Icons.access_time,
            "Saving Goal",
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MilestonesScreen()),
            ),
          ),
          const SizedBox(height: 8),
          _toolTile(
            Icons.balance,
            "Debt Tracker",
            onTap: () => ZentraNotifier.success(
              "Financial Tool",
              "This feature is coming soon",
            ),
          ),
        ],
      ),
    );
  }

  // Build single tile widget for financial tools
  Widget _toolTile(IconData icon, String title, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(20),
                    borderRadius: BorderRadius.circular(200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Icon(icon, color: AppColors.secondary, size: 22),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),

            Container(
              margin: EdgeInsets.only(top: 10),
              color: AppColors.secondary.withAlpha(20),
              width: MediaQuery.of(context).size.width,
              height: 0.5,
            ),
          ],
        ),
      ),
    );
  }

  // Build AI coach interaction card container.
  // NOTE: This remains static sample copy — there is no zgrow-scoped
  // AI-coach/chat endpoint to back it in this pass.
  Widget _buildAiCouchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEFE6FF),
                child: Icon(
                  Icons.smart_toy,
                  color: Color(0xFF4A00E0),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Hi Desire! You successfully avoided weekend splurges. You have an extra \$15 left over. Should we tuck this into your project vault or look over your budget lines for next week?",
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxWidth: 240),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4EDDA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "How can i effectively manage my financial wellbeing",
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey,
                child: Text(
                  "You",
                  style: TextStyle(fontSize: 9, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Ask your couch anything",
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A0059),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 16),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

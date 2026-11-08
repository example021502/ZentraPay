import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zentrapay_application/core/models/goals.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/theme/section_header.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/goals/goals_sheets.dart';
import 'package:zentrapay_application/features/goals/repository/cache_goals_data.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';

/// Save Goal: set financial goals, save towards them by hand or automatically, watch the progress,
/// freeze a goal for up to a week, delete it, and see the recent saving activity at the bottom.
/// Everything is stored on the backend; this screen only reads [GoalsRepository].
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    GoalsRepository.instance.ensureLoaded().catchError((_) => null);
    WalletsRepository.instance.ensureLoaded().catchError((_) => null);
  }

  Future<void> _refresh() async {
    try {
      await Future.wait([
        GoalsRepository.instance.refresh(),
        WalletsRepository.instance.refresh(),
      ]);
    } catch (_) {
      // The error state is drawn from the repositories.
    }
  }

  void _sheet(Widget Function(BuildContext) builder, {double min = 0.5, double max = 0.9}) {
    showAppOverlaySheet<void>(
      context: context,
      minHeightFraction: min,
      maxHeightFraction: max,
      maxWidth: 560,
      builder: builder,
    );
  }

  void _openNewGoal() =>
      _sheet((_) => const NewGoalSheet(), min: 0.6, max: 0.92);

  void _openMove(SavingsGoal goal, {required bool deposit}) {
    if (deposit && goal.isFrozen) {
      ZentraNotifier.warning(
        'Goal is frozen',
        '${goal.savingsName} is frozen until ${_when(goal.frozenUntil!)}. Unfreeze it to save again.',
      );
      return;
    }
    _sheet((_) => MoveMoneySheet(goal: goal, deposit: deposit));
  }

  void _openFreeze(SavingsGoal goal) => _sheet((_) => FreezeSheet(goal: goal));

  void _openAutoSave(SavingsGoal goal) =>
      _sheet((_) => AutoSaveSheet(goal: goal), min: 0.55);

  Future<void> _unfreeze(SavingsGoal goal) async {
    try {
      await GoalsRepository.instance.unfreeze(goal.savingsId);
      ZentraNotifier.success('Goal unfrozen', 'You can save into ${goal.savingsName} again.');
    } catch (e) {
      ZentraNotifier.error(
        "Couldn't unfreeze",
        errorMessage(e, fallback: 'Please try again.'),
      );
    }
  }

  Future<void> _confirmDelete(SavingsGoal goal) async {
    final money = formatMoney(goal.balance.toStringAsFixed(2), symbol: '${goal.currencyCode} ');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${goal.savingsName}"?'),
        content: Text(
          goal.balance > 0
              ? '$money saved in this goal will be returned to your ${goal.currencyCode} wallet, '
                    'and auto-save will stop. This cannot be undone.'
              : 'This goal is empty. It will be removed and auto-save will stop. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final returned = await GoalsRepository.instance.delete(goal.savingsId);
      ZentraNotifier.success(
        'Goal deleted',
        returned > 0
            ? '${formatMoney(returned.toStringAsFixed(2), symbol: '${goal.currencyCode} ')} was returned to your ${goal.currencyCode} wallet.'
            : '${goal.savingsName} was removed.',
      );
    } catch (e) {
      ZentraNotifier.error(
        "Couldn't delete the goal",
        errorMessage(e, fallback: 'Nothing was changed. Please try again.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SectionAppBar(),
      backgroundColor: AppTheme.headerPink,
      body: ListenableBuilder(
        listenable: Listenable.merge([
          GoalsRepository.instance,
          WalletsRepository.instance,
        ]),
        builder: (context, _) {
          final repo = GoalsRepository.instance;
          final goals = repo.goals ?? const <SavingsGoal>[];
          return SectionScrollView(
            onRefresh: _refresh,
            header: SectionHeader(
              title: 'Save Goal',
              subtitle: 'Set a goal, save towards it, watch it grow',
              icon: Icons.flag_rounded,
              showBack: true,
              sheetColor: AppTheme.gray50,
              actions: [
                SectionHeaderButton(
                  icon: Icons.add,
                  tooltip: 'New goal',
                  onTap: _openNewGoal,
                ),
              ],
              child: _HeroTotals(goals: goals),
            ),
            sheet: SectionSheet(
              color: AppTheme.gray50,
              topPadding: AppTheme.spacingLg,
              child: _body(repo, goals),
            ),
          );
        },
      ),
    );
  }

  Widget _body(GoalsRepository repo, List<SavingsGoal> goals) {
    if (repo.isLoading && repo.goals == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: AppTheme.brand)),
      );
    }
    if (repo.error != null && repo.goals == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: EmptyStateWidget(
          icon: Icons.cloud_off_rounded,
          message: errorMessage(
            repo.error,
            fallback: "We couldn't load your goals. Pull down to try again.",
          ),
          actionLabel: 'Retry',
          onAction: _refresh,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Your goals', style: AppTheme.headlineSmall)),
            FilledButton.icon(
              onPressed: _openNewGoal,
              // The app theme gives buttons an infinite minimum width (they are full-width by
              // default); in a Row that cannot be laid out and blanks the whole screen.
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New goal'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        if (goals.isEmpty)
          _emptyState()
        else
          for (final goal in goals)
            _GoalCard(
              goal: goal,
              onAdd: () => _openMove(goal, deposit: true),
              onWithdraw: () => _openMove(goal, deposit: false),
              onFreeze: () => _openFreeze(goal),
              onUnfreeze: () => _unfreeze(goal),
              onAutoSave: () => _openAutoSave(goal),
              onDelete: () => _confirmDelete(goal),
            ),
        const SizedBox(height: AppTheme.spacingLg),
        _ActivitySection(repo: repo, onRetry: _refresh),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXl),
      child: Column(
        children: [
          EmptyStateWidget(
            icon: Icons.flag_outlined,
            message:
                'No goals yet. Create one - a rent fund, a new phone, a holiday - and start saving from your wallet.',
          ),
          const SizedBox(height: AppTheme.spacingMd),
          PrimaryButton(label: 'Create my first goal', onPressed: _openNewGoal),
        ],
      ),
    );
  }
}

String _when(DateTime t) => DateFormat('d MMM, HH:mm').format(t);

String _money(double v, String code) =>
    formatMoney(v.toStringAsFixed(2), symbol: '$code ');

// ---------------------------------------------------------------- header

/// Totals on the pink header: what is saved across all goals, per currency.
class _HeroTotals extends StatelessWidget {
  final List<SavingsGoal> goals;

  const _HeroTotals({required this.goals});

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final g in goals) {
      totals.update(g.currencyCode, (v) => v + g.balance, ifAbsent: () => g.balance);
    }
    final reached = goals.where((g) => g.isReached).length;
    final frozen = goals.where((g) => g.isFrozen).length;
    final entries = totals.entries.toList();
    final soft = AppTheme.whiteBodySmall.copyWith(color: Colors.white.withValues(alpha: 0.85));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.glassSurfaceStrong,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total saved', style: soft),
          const SizedBox(height: 2),
          if (entries.isEmpty)
            Text('Nothing saved yet', style: AppTheme.headlineMedium.copyWith(color: Colors.white))
          else
            for (final e in entries)
              Text(
                _money(e.value, e.key),
                style: AppTheme.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
          const SizedBox(height: 6),
          Text(
            '${goals.length} ${goals.length == 1 ? 'goal' : 'goals'}'
            '  ·  $reached reached'
            '${frozen > 0 ? '  ·  $frozen frozen' : ''}',
            style: soft,
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ card

enum _GoalAction { freeze, unfreeze, autoSave, delete }

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback onAdd;
  final VoidCallback onWithdraw;
  final VoidCallback onFreeze;
  final VoidCallback onUnfreeze;
  final VoidCallback onAutoSave;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onAdd,
    required this.onWithdraw,
    required this.onFreeze,
    required this.onUnfreeze,
    required this.onAutoSave,
    required this.onDelete,
  });

  String _m(double v) => _money(v, goal.currencyCode);

  void _onMenu(_GoalAction action) {
    switch (action) {
      case _GoalAction.freeze:
        onFreeze();
      case _GoalAction.unfreeze:
        onUnfreeze();
      case _GoalAction.autoSave:
        onAutoSave();
      case _GoalAction.delete:
        onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = goal.isReached;
    final frozen = goal.isFrozen;
    final tone = frozen
        ? AppTheme.infoBlue
        : done
        ? AppTheme.successGreen
        : AppTheme.brand;
    final target = goal.targetAmount ?? 0;
    final left = goal.hasTarget ? (target - goal.balance).clamp(0.0, target) : 0.0;
    final date = goal.targetDate;
    final statusLabel = frozen ? 'Frozen' : (done ? 'Reached' : 'Saving');

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tone.withAlpha(AppTheme.isDark ? 70 : 28),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    frozen
                        ? Icons.ac_unit_rounded
                        : done
                        ? Icons.emoji_events_rounded
                        : Icons.savings_outlined,
                    size: 22,
                    color: AppTheme.textBlack,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.savingsName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.labelLarge,
                      ),
                      Text(
                        goal.hasTarget ? 'Target ${_m(target)}' : 'No target set',
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tone.withAlpha(32),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTheme.labelSmall.copyWith(color: tone, fontWeight: FontWeight.w700),
                  ),
                ),
                PopupMenuButton<_GoalAction>(
                  tooltip: 'Goal options',
                  icon: Icon(Icons.more_vert_rounded, color: AppTheme.gray500),
                  onSelected: _onMenu,
                  itemBuilder: (_) => [
                    if (frozen)
                      const PopupMenuItem(
                        value: _GoalAction.unfreeze,
                        child: _MenuRow(Icons.play_arrow_rounded, 'Unfreeze'),
                      )
                    else if (!done)
                      const PopupMenuItem(
                        value: _GoalAction.freeze,
                        child: _MenuRow(Icons.ac_unit_rounded, 'Freeze goal'),
                      ),
                    if (!done || goal.autoSaveEnabled)
                      PopupMenuItem(
                        value: _GoalAction.autoSave,
                        child: _MenuRow(
                          Icons.autorenew_rounded,
                          goal.autoSaveEnabled ? 'Change auto-save' : 'Auto-save',
                        ),
                      ),
                    PopupMenuItem(
                      value: _GoalAction.delete,
                      child: _MenuRow(Icons.delete_outline_rounded, 'Delete goal', color: AppTheme.errorRed),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(_m(goal.balance), style: AppTheme.headlineMedium),
            const SizedBox(height: AppTheme.spacingSm),
            if (goal.hasTarget) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 10,
                  color: tone,
                  backgroundColor: AppTheme.gray100,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(goal.progress * 100).floor()}% of goal',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                  ),
                  Text(
                    done ? 'Goal reached' : '${_m(left)} to go',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                  ),
                ],
              ),
            ],
            if (date != null) ...[
              const SizedBox(height: 4),
              Text(
                'Target date ${DateFormat('d MMM yyyy').format(date)}',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
              ),
            ],
            if (frozen)
              _InfoLine(
                icon: Icons.ac_unit_rounded,
                color: AppTheme.infoBlue,
                text: 'Frozen until ${_when(goal.frozenUntil!)} - saving is paused',
                actionLabel: 'Unfreeze',
                onAction: onUnfreeze,
              ),
            if (goal.autoSaveEnabled && goal.autoSaveAmount != null)
              _InfoLine(
                icon: Icons.autorenew_rounded,
                color: AppTheme.brand,
                text:
                    'Auto-save ${_m(goal.autoSaveAmount!)} ${goal.autoSaveFrequency?.adverb ?? ''}'
                    '${goal.autoSaveNextRun == null ? '' : ' · next ${_when(goal.autoSaveNextRun!)}'}'
                    '${frozen ? ' (paused while frozen)' : ''}',
              ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: goal.balance > 0 ? onWithdraw : null,
                    child: const Text('Withdraw'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: FilledButton(
                    onPressed: frozen ? null : onAdd,
                    child: Text(frozen ? 'Frozen' : 'Add money'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MenuRow(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? AppTheme.textBlack),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyMedium.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InfoLine({
    required this.icon,
    required this.color,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(AppTheme.isDark ? 50 : 24),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: AppTheme.bodySmall.copyWith(color: AppTheme.textBlack))),
            if (actionLabel != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- activity

/// "Recent activity" at the bottom: the latest deposits, withdrawals and automatic saves, from the database.
class _ActivitySection extends StatelessWidget {
  final GoalsRepository repo;
  final VoidCallback onRetry;

  const _ActivitySection({required this.repo, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final activity = repo.activity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent activity', style: AppTheme.headlineSmall),
        const SizedBox(height: AppTheme.spacingMd),
        if (activity == null && repo.activityError != null)
          EmptyStateWidget(
            icon: Icons.history_toggle_off_rounded,
            message: "We couldn't load your recent activity.",
            actionLabel: 'Retry',
            onAction: onRetry,
          )
        else if (activity == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (activity.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
            child: Text(
              'Nothing yet. Money you save into or take out of a goal shows up here.',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < activity.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: AppTheme.gray100),
                  _ActivityRow(item: activity[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final GoalActivity item;

  const _ActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final failed = item.failed;
    final color = failed
        ? AppTheme.errorRed
        : item.isDeposit
        ? AppTheme.successGreen
        : AppTheme.warningOrange;
    final icon = failed
        ? Icons.error_outline_rounded
        : item.auto
        ? Icons.autorenew_rounded
        : item.isDeposit
        ? Icons.south_west_rounded
        : Icons.north_east_rounded;
    final title = failed
        ? (item.isDeposit ? "Couldn't save to ${item.savingsName}" : "Couldn't withdraw from ${item.savingsName}")
        : item.isDeposit
        ? '${item.auto ? 'Auto-saved' : 'Saved'} to ${item.savingsName}'
        : 'Withdrew from ${item.savingsName}';
    final when = item.createdAt == null ? '' : DateFormat('d MMM yyyy, HH:mm').format(item.createdAt!);
    final subtitle = failed && (item.failureReason ?? '').isNotEmpty
        ? '$when · ${item.failureReason}'
        : when;

    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withAlpha(AppTheme.isDark ? 70 : 28),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.bodyMedium),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
      ),
      trailing: Text(
        failed
            ? _money(item.amount, item.currencyCode)
            : '${item.isDeposit ? '+' : '-'}${_money(item.amount, item.currencyCode)}',
        style: AppTheme.labelLarge.copyWith(
          color: failed ? AppTheme.gray500 : color,
          decoration: failed ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}

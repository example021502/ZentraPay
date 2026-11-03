import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/models/wallet.dart';
import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/theme/section_header.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/features/zbanking/repository/cache_zbanking_data.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrow_data.dart' as zgrow;

/// Save Goal: create savings goals, move money into them from a wallet account and watch the progress.
/// Everything is stored on the backend (`/api/zbanking/savings`): a goal, every deposit / withdrawal, and
/// the matching transaction in the user's history.
class MilestonesScreen extends StatefulWidget {
  const MilestonesScreen({super.key});

  @override
  State<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends State<MilestonesScreen> {
  @override
  void initState() {
    super.initState();
    SavingsRepository.instance.ensureLoaded().catchError((_) => null);
    WalletsRepository.instance.ensureLoaded().catchError((_) => null);
  }

  Future<void> _refresh() async {
    try {
      await Future.wait([
        SavingsRepository.instance.ensureLoaded(forceRefresh: true),
        WalletsRepository.instance.refresh(),
      ]);
    } catch (_) {
      // The error state is drawn from the repositories.
    }
  }

  /// Money moved in or out of a goal changes the wallet, the history and ZGrow's overall savings.
  void _afterMove() {
    WalletsRepository.instance.refresh().catchError((_) => null);
    TransactionsRepository.instance
        .ensureLoaded(forceRefresh: true)
        .catchError((_) => null);
    zgrow.SavingsRepository.instance.ensureLoaded(forceRefresh: true).catchError((_) => null);
  }

  void _openNewGoal() {
    showAppOverlaySheet<void>(
      context: context,
      minHeightFraction: 0.6,
      maxHeightFraction: 0.92,
      maxWidth: 560,
      builder: (_) => _NewGoalSheet(onChanged: _afterMove),
    );
  }

  void _openMove(SavingsAccount goal, {required bool deposit}) {
    showAppOverlaySheet<void>(
      context: context,
      minHeightFraction: 0.5,
      maxWidth: 560,
      builder: (_) =>
          _MoveMoneySheet(goal: goal, deposit: deposit, onChanged: _afterMove),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SectionAppBar(),
      backgroundColor: AppTheme.headerPink,
      body: ListenableBuilder(
        listenable: Listenable.merge([
          SavingsRepository.instance,
          WalletsRepository.instance,
        ]),
        builder: (context, _) {
          final repo = SavingsRepository.instance;
          final goals = repo.data ?? const <SavingsAccount>[];
          return SectionScrollView(
            onRefresh: _refresh,
            header: SectionHeader(
              title: 'Save Goal',
              subtitle: 'Set a goal, save towards it, watch it grow',
              icon: Icons.flag_rounded,
              showBack: true,
              sheetColor: AppTheme.gray50,
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

  Widget _body(SavingsRepository repo, List<SavingsAccount> goals) {
    if (repo.isLoading && repo.data == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: AppTheme.brand)),
      );
    }
    if (repo.error != null && repo.data == null) {
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
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New goal'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        if (goals.isEmpty)
          _emptyState()
        else
          for (final goal in goals) _GoalCard(
            goal: goal,
            onAdd: () => _openMove(goal, deposit: true),
            onWithdraw: () => _openMove(goal, deposit: false),
          ),
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

// ---------------------------------------------------------------- header

/// Totals on the pink header: what is saved across all goals, per currency.
class _HeroTotals extends StatelessWidget {
  final List<SavingsAccount> goals;

  const _HeroTotals({required this.goals});

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final g in goals) {
      totals.update(
        g.currencyCode,
        (v) => v + g.balance,
        ifAbsent: () => g.balance,
      );
    }
    final reached = goals.where((g) => _isDone(g)).length;
    final entries = totals.entries.toList();

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
          Text(
            'Total saved',
            style: AppTheme.whiteBodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 2),
          if (entries.isEmpty)
            Text(
              'Nothing saved yet',
              style: AppTheme.headlineMedium.copyWith(color: Colors.white),
            )
          else
            for (final e in entries)
              Text(
                formatMoney(e.value.toStringAsFixed(2), symbol: '${e.key} '),
                style: AppTheme.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
          const SizedBox(height: 6),
          Text(
            '${goals.length} ${goals.length == 1 ? 'goal' : 'goals'}'
            '  ·  $reached reached',
            style: AppTheme.whiteBodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isDone(SavingsAccount g) =>
    g.status.toUpperCase() == 'COMPLETED' ||
    ((g.targetAmount ?? 0) > 0 && g.balance >= (g.targetAmount ?? 0));

// ------------------------------------------------------------------ card

class _GoalCard extends StatelessWidget {
  final SavingsAccount goal;
  final VoidCallback onAdd;
  final VoidCallback onWithdraw;

  const _GoalCard({
    required this.goal,
    required this.onAdd,
    required this.onWithdraw,
  });

  String _money(double v) =>
      formatMoney(v.toStringAsFixed(2), symbol: '${goal.currencyCode} ');

  @override
  Widget build(BuildContext context) {
    final target = goal.targetAmount ?? 0;
    final hasTarget = target > 0;
    final progress = hasTarget ? (goal.balance / target).clamp(0.0, 1.0) : 0.0;
    final done = _isDone(goal);
    final tone = done ? AppTheme.successGreen : AppTheme.brand;
    final left = hasTarget ? (target - goal.balance).clamp(0.0, target) : 0.0;
    final date = goal.targetDate;

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
                    done ? Icons.emoji_events_rounded : Icons.savings_outlined,
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
                        hasTarget
                            ? 'Target ${_money(target)}'
                            : 'No target set',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tone.withAlpha(32),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    done ? 'Reached' : 'Saving',
                    style: AppTheme.labelSmall.copyWith(
                      color: tone,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(_money(goal.balance), style: AppTheme.headlineMedium),
            const SizedBox(height: AppTheme.spacingSm),
            if (hasTarget) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                child: LinearProgressIndicator(
                  value: progress,
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
                    '${(progress * 100).floor()}% of goal',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                  ),
                  Text(
                    done ? 'Goal reached' : '${_money(left)} to go',
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
                    onPressed: onAdd,
                    child: const Text('Add money'),
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

// ------------------------------------------------------------- new goal

class _NewGoalSheet extends StatefulWidget {
  final VoidCallback onChanged;

  const _NewGoalSheet({required this.onChanged});

  @override
  State<_NewGoalSheet> createState() => _NewGoalSheetState();
}

class _NewGoalSheetState extends State<_NewGoalSheet> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  final _first = TextEditingController();
  String? _currency;
  DateTime? _date;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final accounts = _accounts();
    _currency = WalletsRepository.instance.defaultWallet?.currencyCode;
    if (accounts.isNotEmpty && !accounts.any((a) => a.currencyCode == _currency)) {
      _currency = accounts.first.currencyCode;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _first.dispose();
    super.dispose();
  }

  /// One entry per currency the user holds (a goal is funded from the wallet account of its currency).
  List<FiatAccount> _accounts() {
    final seen = <String>{};
    final list = WalletsRepository.instance.data?.fiatAccounts ?? const [];
    return [
      for (final a in list)
        if (seen.add(a.currencyCode)) a,
    ];
  }

  double _balance(String? code) {
    for (final a in WalletsRepository.instance.data?.fiatAccounts ?? const []) {
      if (a.currencyCode == code) return a.balance;
    }
    return 0;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 30)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 20)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    final target = double.tryParse(_target.text.trim());
    final first = double.tryParse(_first.text.trim()) ?? 0;
    if (name.isEmpty) {
      setState(() => _error = 'Give your goal a name.');
      return;
    }
    if (_currency == null) {
      setState(() => _error = 'You need a wallet account to save from.');
      return;
    }
    if (_target.text.trim().isNotEmpty && (target == null || target <= 0)) {
      setState(() => _error = 'Enter a valid target amount, or leave it empty.');
      return;
    }
    if (first < 0) {
      setState(() => _error = 'The first deposit cannot be negative.');
      return;
    }
    if (first > _balance(_currency)) {
      setState(
        () => _error =
            'Your $_currency wallet only has ${formatMoney(_balance(_currency).toStringAsFixed(2))}. Add less, or top up first.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await SavingsRepository.instance.create(
        savingsName: name,
        currencyCode: _currency!,
        initialDeposit: first.toStringAsFixed(2),
        targetAmount: target?.toStringAsFixed(2),
        targetDate: _date == null
            ? null
            : DateFormat('yyyy-MM-dd').format(_date!),
      );
      widget.onChanged();
      if (!mounted) return;
      Navigator.of(context).pop();
      ZentraNotifier.success(
        'Goal created',
        first > 0
            ? '$name is set up and $_currency ${first.toStringAsFixed(2)} was saved into it.'
            : '$name is ready - add money whenever you like.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = errorMessage(
          e,
          fallback: "We couldn't create your goal. Nothing was deducted.",
        );
      });
      // The goal itself may exist even when its first deposit was refused
      SavingsRepository.instance
          .ensureLoaded(forceRefresh: true)
          .catchError((_) => null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounts = _accounts();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New savings goal', style: AppTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Saved money moves out of your wallet into the goal, and you can take it back any time.',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          AppTextField(
            controller: _name,
            labelText: 'Goal name',
            hintText: 'e.g. Rent fund',
          ),
          const SizedBox(height: AppTheme.spacingMd),
          if (accounts.isEmpty)
            Text(
              'You have no wallet account yet. Create one from the home screen first.',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.errorRed),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: const InputDecoration(labelText: 'Save from'),
              items: [
                for (final a in accounts)
                  DropdownMenuItem(
                    value: a.currencyCode,
                    child: Text(
                      '${a.currencyCode} wallet  ·  ${formatMoney(a.balance.toStringAsFixed(2))}',
                    ),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (v) => setState(() {
                      _currency = v;
                      _error = null;
                    }),
            ),
          const SizedBox(height: AppTheme.spacingMd),
          TextField(
            controller: _target,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Target amount (optional)',
              prefixText: _currency == null ? null : '$_currency ',
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            onTap: _saving ? null : _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Target date (optional)',
                suffixIcon: Icon(Icons.event_outlined),
              ),
              child: Text(
                _date == null
                    ? 'No target date'
                    : DateFormat('d MMM yyyy').format(_date!),
                style: AppTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          TextField(
            controller: _first,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'First deposit (optional)',
              prefixText: _currency == null ? null : '$_currency ',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              _error!,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.errorRed),
            ),
          ],
          const SizedBox(height: AppTheme.spacingLg),
          PrimaryButton(
            label: 'Create goal',
            loading: _saving,
            onPressed: accounts.isEmpty ? null : _create,
          ),
          const SizedBox(height: AppTheme.spacingLg),
        ],
      ),
    );
  }
}

// -------------------------------------------------- add / withdraw money

class _MoveMoneySheet extends StatefulWidget {
  final SavingsAccount goal;
  final bool deposit;
  final VoidCallback onChanged;

  const _MoveMoneySheet({
    required this.goal,
    required this.deposit,
    required this.onChanged,
  });

  @override
  State<_MoveMoneySheet> createState() => _MoveMoneySheetState();
}

class _MoveMoneySheetState extends State<_MoveMoneySheet> {
  final _amount = TextEditingController();
  bool _busy = false;
  String? _error;

  String get _code => widget.goal.currencyCode;

  double get _walletBalance {
    for (final a in WalletsRepository.instance.data?.fiatAccounts ?? const []) {
      if (a.currencyCode == _code) return a.balance;
    }
    return 0;
  }

  /// The most this move can be: the wallet balance when adding, the goal's savings when withdrawing.
  double get _limit => widget.deposit ? _walletBalance : widget.goal.balance;

  String _money(double v) =>
      formatMoney(v.toStringAsFixed(2), symbol: '$_code ');

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = double.tryParse(_amount.text.trim());
    if (value == null || value <= 0) {
      setState(() => _error = 'Enter an amount greater than zero.');
      return;
    }
    if (value > _limit + 0.001) {
      setState(
        () => _error = widget.deposit
            ? 'Your $_code wallet only has ${_money(_walletBalance)}. Top up first, or add less.'
            : 'This goal only holds ${_money(widget.goal.balance)}.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = widget.deposit
          ? await SavingsRepository.instance.deposit(
              widget.goal.savingsId,
              value.toStringAsFixed(2),
            )
          : await SavingsRepository.instance.withdraw(
              widget.goal.savingsId,
              value.toStringAsFixed(2),
            );
      widget.onChanged();
      if (!mounted) return;
      Navigator.of(context).pop();
      ZentraNotifier.success(
        widget.deposit ? 'Money saved' : 'Money withdrawn',
        widget.deposit
            ? '${_money(value)} added to ${updated.savingsName}.'
            : '${_money(value)} moved back to your $_code wallet.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = errorMessage(
          e,
          fallback: "We couldn't complete that. Nothing was moved.",
        );
      });
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deposit = widget.deposit;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            deposit ? 'Add money' : 'Withdraw',
            style: AppTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            deposit
                ? 'From your $_code wallet (${_money(_walletBalance)}) into "${widget.goal.savingsName}".'
                : 'From "${widget.goal.savingsName}" (${_money(widget.goal.balance)}) back to your $_code wallet.',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          TextField(
            controller: _amount,
            enabled: !_busy,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '$_code ',
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Wrap(
            spacing: 8,
            children: [
              for (final fraction in const [0.25, 0.5, 1.0])
                ActionChip(
                  label: Text(fraction == 1.0 ? 'All' : '${(fraction * 100).round()}%'),
                  onPressed: _busy || _limit <= 0
                      ? null
                      : () => setState(() {
                          // Floor to cents so "All" never exceeds the balance
                          final cents = (_limit * fraction * 100).floor();
                          _amount.text = (cents / 100).toStringAsFixed(2);
                          _error = null;
                        }),
                ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              _error!,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.errorRed),
            ),
          ],
          const SizedBox(height: AppTheme.spacingLg),
          PrimaryButton(
            label: deposit ? 'Save money' : 'Withdraw',
            loading: _busy,
            onPressed: _submit,
          ),
          const SizedBox(height: AppTheme.spacingLg),
        ],
      ),
    );
  }
}

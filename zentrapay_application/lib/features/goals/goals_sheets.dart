import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:zentrapay_application/core/models/goals.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/models/wallet.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/goals/repository/cache_goals_data.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';

/// Bottom sheets of the Save Goal section: new goal, add / withdraw money, freeze, auto-save.
/// Each one talks only to [GoalsRepository]; the repository refreshes the wallet, history and
/// ZGrow totals after money moves.

final _moneyInput = [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))];

double _walletBalance(String? currencyCode) {
  for (final a in WalletsRepository.instance.data?.fiatAccounts ?? const <FiatAccount>[]) {
    if (a.currencyCode == currencyCode) return a.balance;
  }
  return 0;
}

String _money(double v, String code) =>
    formatMoney(v.toStringAsFixed(2), symbol: '$code ');

// ---------------------------------------------------------------- new goal

class NewGoalSheet extends StatefulWidget {
  const NewGoalSheet({super.key});

  @override
  State<NewGoalSheet> createState() => _NewGoalSheetState();
}

class _NewGoalSheetState extends State<NewGoalSheet> {
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
    final list = WalletsRepository.instance.data?.fiatAccounts ?? const <FiatAccount>[];
    return [
      for (final a in list)
        if (seen.add(a.currencyCode)) a,
    ];
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
    if (first > _walletBalance(_currency)) {
      setState(
        () => _error =
            'Your $_currency wallet only has ${formatMoney(_walletBalance(_currency).toStringAsFixed(2))}. Add less, or top up first.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await GoalsRepository.instance.create(
        savingsName: name,
        currencyCode: _currency!,
        initialDeposit: first.toStringAsFixed(2),
        targetAmount: target?.toStringAsFixed(2),
        targetDate: _date == null ? null : DateFormat('yyyy-MM-dd').format(_date!),
      );
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
            inputFormatters: _moneyInput,
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
                _date == null ? 'No target date' : DateFormat('d MMM yyyy').format(_date!),
                style: AppTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          TextField(
            controller: _first,
            enabled: !_saving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _moneyInput,
            decoration: InputDecoration(
              labelText: 'First deposit (optional)',
              prefixText: _currency == null ? null : '$_currency ',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(_error!, style: AppTheme.bodySmall.copyWith(color: AppTheme.errorRed)),
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

class MoveMoneySheet extends StatefulWidget {
  final SavingsGoal goal;
  final bool deposit;

  const MoveMoneySheet({super.key, required this.goal, required this.deposit});

  @override
  State<MoveMoneySheet> createState() => _MoveMoneySheetState();
}

class _MoveMoneySheetState extends State<MoveMoneySheet> {
  final _amount = TextEditingController();
  bool _busy = false;
  String? _error;

  String get _code => widget.goal.currencyCode;

  /// The most this move can be: the wallet balance when adding, the goal's savings when withdrawing.
  double get _limit => widget.deposit ? _walletBalance(_code) : widget.goal.balance;

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
            ? 'Your $_code wallet only has ${_money(_walletBalance(_code), _code)}. Top up first, or add less.'
            : 'This goal only holds ${_money(widget.goal.balance, _code)}.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = GoalsRepository.instance;
      final updated = widget.deposit
          ? await repo.deposit(widget.goal.savingsId, value.toStringAsFixed(2))
          : await repo.withdraw(widget.goal.savingsId, value.toStringAsFixed(2));
      if (!mounted) return;
      Navigator.of(context).pop();
      ZentraNotifier.success(
        widget.deposit ? 'Money saved' : 'Money withdrawn',
        widget.deposit
            ? '${_money(value, _code)} added to ${updated.savingsName}.'
            : '${_money(value, _code)} moved back to your $_code wallet.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = errorMessage(e, fallback: "We couldn't complete that. Nothing was moved.");
      });
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
          Text(deposit ? 'Add money' : 'Withdraw', style: AppTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            deposit
                ? 'From your $_code wallet (${_money(_walletBalance(_code), _code)}) into "${widget.goal.savingsName}".'
                : 'From "${widget.goal.savingsName}" (${_money(widget.goal.balance, _code)}) back to your $_code wallet.',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          TextField(
            controller: _amount,
            enabled: !_busy,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _moneyInput,
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(labelText: 'Amount', prefixText: '$_code '),
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
            Text(_error!, style: AppTheme.bodySmall.copyWith(color: AppTheme.errorRed)),
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

// ------------------------------------------------------------------ freeze

/// Choose how long to stop saving into a goal: 1 to 7 days, never longer.
class FreezeSheet extends StatefulWidget {
  final SavingsGoal goal;

  const FreezeSheet({super.key, required this.goal});

  @override
  State<FreezeSheet> createState() => _FreezeSheetState();
}

class _FreezeSheetState extends State<FreezeSheet> {
  int _days = 3;
  bool _busy = false;
  String? _error;

  Future<void> _freeze() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await GoalsRepository.instance.freeze(widget.goal.savingsId, _days);
      if (!mounted) return;
      Navigator.of(context).pop();
      final until = updated.frozenUntil;
      ZentraNotifier.success(
        'Goal frozen',
        until == null
            ? '${updated.savingsName} is frozen for $_days ${_days == 1 ? 'day' : 'days'}.'
            : '${updated.savingsName} is frozen until ${DateFormat('d MMM, HH:mm').format(until)}.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = errorMessage(e, fallback: "We couldn't freeze this goal. Please try again.");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ends = DateTime.now().add(Duration(days: _days));
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Freeze goal', style: AppTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'While "${widget.goal.savingsName}" is frozen no money can be saved into it - '
            'by you or by auto-save. You can still withdraw, and you can unfreeze at any time.',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text('Freeze for', style: AppTheme.labelLarge),
          const SizedBox(height: AppTheme.spacingSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var d = 1; d <= SavingsGoal.maxFreezeDays; d++)
                ChoiceChip(
                  label: Text(d == SavingsGoal.maxFreezeDays ? '1 week' : '$d ${d == 1 ? 'day' : 'days'}'),
                  selected: _days == d,
                  onSelected: _busy ? null : (_) => setState(() => _days = d),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Saving resumes on ${DateFormat('d MMM yyyy, HH:mm').format(ends)}. The longest a goal can be frozen is one week.',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(_error!, style: AppTheme.bodySmall.copyWith(color: AppTheme.errorRed)),
          ],
          const SizedBox(height: AppTheme.spacingLg),
          PrimaryButton(label: 'Freeze goal', loading: _busy, onPressed: _freeze),
          const SizedBox(height: AppTheme.spacingLg),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- auto-save

/// Turn the automatic save on / change it / turn it off: an amount and how often.
class AutoSaveSheet extends StatefulWidget {
  final SavingsGoal goal;

  const AutoSaveSheet({super.key, required this.goal});

  @override
  State<AutoSaveSheet> createState() => _AutoSaveSheetState();
}

class _AutoSaveSheetState extends State<AutoSaveSheet> {
  late final TextEditingController _amount;
  late AutoSaveFrequency _frequency;
  bool _busy = false;
  String? _error;

  String get _code => widget.goal.currencyCode;

  @override
  void initState() {
    super.initState();
    final previous = widget.goal.autoSaveAmount;
    _amount = TextEditingController(
      text: previous == null || previous <= 0 ? '' : previous.toStringAsFixed(2),
    );
    _frequency = widget.goal.autoSaveFrequency ?? AutoSaveFrequency.weekly;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// When the first automatic save would happen: one full period from now (same rule as the backend).
  DateTime get _firstRun {
    final now = DateTime.now();
    return switch (_frequency) {
      AutoSaveFrequency.daily => now.add(const Duration(days: 1)),
      AutoSaveFrequency.weekly => now.add(const Duration(days: 7)),
      AutoSaveFrequency.monthly => DateTime(now.year, now.month + 1, now.day, now.hour, now.minute),
    };
  }

  Future<void> _turnOn() async {
    final value = double.tryParse(_amount.text.trim());
    if (value == null || value <= 0) {
      setState(() => _error = 'Enter how much to save each time.');
      return;
    }
    await _run(() async {
      final updated = await GoalsRepository.instance.setAutoSave(
        widget.goal.savingsId,
        amount: value.toStringAsFixed(2),
        frequency: _frequency,
      );
      ZentraNotifier.success(
        'Auto-save is on',
        '${_money(value, _code)} will move into ${updated.savingsName} ${_frequency.adverb}.',
      );
    });
  }

  Future<void> _turnOff() => _run(() async {
    final updated = await GoalsRepository.instance.disableAutoSave(widget.goal.savingsId);
    ZentraNotifier.success('Auto-save is off', 'Nothing will be saved into ${updated.savingsName} automatically.');
  });

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = errorMessage(e, fallback: "We couldn't update auto-save. Please try again.");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.goal.autoSaveEnabled;
    final amount = double.tryParse(_amount.text.trim());
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Auto-save', style: AppTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'Save into "${widget.goal.savingsName}" automatically from your $_code wallet '
            '(${_money(_walletBalance(_code), _code)} now). If the wallet is short when it is due, '
            'that save is skipped and shown as failed in your activity.',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          TextField(
            controller: _amount,
            enabled: !_busy,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _moneyInput,
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(labelText: 'Amount each time', prefixText: '$_code '),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text('How often', style: AppTheme.labelLarge),
          const SizedBox(height: AppTheme.spacingSm),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AutoSaveFrequency>(
              showSelectedIcon: false,
              segments: [
                for (final f in AutoSaveFrequency.values)
                  ButtonSegment(value: f, label: Text(f.name[0].toUpperCase() + f.name.substring(1))),
              ],
              selected: {_frequency},
              onSelectionChanged: _busy ? null : (s) => setState(() => _frequency = s.first),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            amount == null || amount <= 0
                ? 'First save: ${DateFormat('d MMM yyyy, HH:mm').format(_firstRun)}.'
                : '${_money(amount, _code)} ${_frequency.adverb}, starting ${DateFormat('d MMM yyyy, HH:mm').format(_firstRun)}.',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(_error!, style: AppTheme.bodySmall.copyWith(color: AppTheme.errorRed)),
          ],
          const SizedBox(height: AppTheme.spacingLg),
          PrimaryButton(
            label: on ? 'Save changes' : 'Turn on auto-save',
            loading: _busy,
            onPressed: _turnOn,
          ),
          if (on) ...[
            const SizedBox(height: AppTheme.spacingSm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _busy ? null : _turnOff,
                child: const Text('Turn off auto-save'),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingLg),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/Common/transaction_result_overlay.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/zgrow/emergency/emergency_vault.dart';
import 'package:zentrapay_application/features/zgrow/emergency/vault_pin_sheet.dart';

/// The word the user has to type before an emergency withdrawal can go on.
const String _confirmPhrase = 'EMERGENCY';

/// Written explanation must be at least this long - one line is not a reason.
const int _minReasonLength = 40;
const int _minUsageLength = 5;

/// Seconds the final button stays locked so the decision is not made in a hurry.
const int _reviewSeconds = 10;

/// Opens the emergency withdrawal flow. Resolves to true when money was
/// actually released from the vault.
///
/// Money only leaves the vault after ALL of these:
///  1. the kind of emergency is chosen,
///  2. a written explanation (40+ characters) and what the money pays for,
///  3. an amount that the vault really holds,
///  4. three written acknowledgements and the typed word EMERGENCY,
///  5. the vault PIN (the vault locks after 3 wrong tries),
///  6. a review screen with a 10 second wait before "Confirm".
/// Only one withdrawal is allowed every 24 hours.
Future<bool> showEmergencyWithdrawFlow(BuildContext context) async {
  final done = await showAppOverlaySheet<bool>(
    context: context,
    minHeightFraction: 0.8,
    maxHeightFraction: 0.96,
    maxWidth: 600,
    builder: (_) => const _WithdrawFlow(),
  );
  return done == true;
}

class _WithdrawFlow extends StatefulWidget {
  const _WithdrawFlow();

  @override
  State<_WithdrawFlow> createState() => _WithdrawFlowState();
}

class _WithdrawFlowState extends State<_WithdrawFlow> {
  static const int _steps = 6;

  final EmergencyVault _vault = EmergencyVault.instance;
  final TextEditingController _reason = TextEditingController();
  final TextEditingController _usage = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _phrase = TextEditingController();

  int _step = 0;
  String? _category;
  late String _currency;
  final List<bool> _acks = [false, false, false];
  bool _pinOk = false;
  String? _error;

  int _secondsLeft = _reviewSeconds;
  Timer? _timer;
  bool _submitting = false;

  static const List<String> _ackTexts = [
    'This is a genuine, unplanned emergency - not a bill, shopping or '
        'spending I could have planned for.',
    'I have no other money I can use for this right now.',
    'I understand this reduces the cushion I built for future emergencies, '
        'and that my reason is saved with this withdrawal.',
  ];

  @override
  void initState() {
    super.initState();
    final balances = _vault.balancesMinor;
    // Start on the currency holding the most.
    _currency = balances.isEmpty
        ? 'GHS'
        : (balances.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reason.dispose();
    _usage.dispose();
    _amount.dispose();
    _phrase.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ validation

  int? get _amountMinor {
    final value = double.tryParse(_amount.text.trim());
    if (value == null || value <= 0) return null;
    return (value * 100).round();
  }

  /// A message when the current step may not go on, or null when it may.
  String? _problem() {
    switch (_step) {
      case 0:
        return _category == null
            ? 'Choose what kind of emergency this is.'
            : null;
      case 1:
        if (_reason.text.trim().length < _minReasonLength) {
          return 'Explain what happened in at least $_minReasonLength characters.';
        }
        if (_usage.text.trim().length < _minUsageLength) {
          return 'Say what the money will pay for.';
        }
        return null;
      case 2:
        final minor = _amountMinor;
        if (minor == null) return 'Enter the amount you need.';
        if (minor > _vault.balanceMinor(_currency)) {
          return 'The vault only holds '
              '${EmergencyVault.formatMinor(_vault.balanceMinor(_currency), currency: _currency)}.';
        }
        return null;
      case 3:
        if (_acks.contains(false)) return 'Tick all three confirmations.';
        if (_phrase.text.trim().toUpperCase() != _confirmPhrase) {
          return 'Type $_confirmPhrase to continue.';
        }
        return null;
      case 4:
        return _pinOk ? null : 'Enter your vault PIN to continue.';
    }
    return null;
  }

  void _next() {
    final problem = _problem();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _step++;
    });
    if (_step == _steps - 1) _startCountdown();
  }

  void _back() {
    _timer?.cancel();
    setState(() {
      _error = null;
      // The PIN must be proven again whenever the user goes back and changes
      // anything before it.
      if (_step <= 5) _pinOk = false;
      _step = _step - 1;
    });
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _reviewSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(
        () => _secondsLeft = (_secondsLeft - 1).clamp(0, _reviewSeconds),
      );
      if (_secondsLeft == 0) t.cancel();
    });
  }

  Future<void> _confirm() async {
    if (_submitting || _secondsLeft > 0) return;
    final minor = _amountMinor;
    if (minor == null || !_pinOk) return;
    setState(() => _submitting = true);
    try {
      await _vault.recordWithdrawal(
        minor: minor,
        currency: _currency,
        category: _category!,
        reason: _reason.text.trim(),
        usage: _usage.text.trim(),
      );
      if (!mounted) return;
      final amountText = EmergencyVault.formatMinor(minor, currency: _currency);
      final nav = Navigator.of(context);
      final rootContext = nav.context;
      nav.pop(true);
      await showTransactionResultOverlay(
        // ignore: use_build_context_synchronously
        context: rootContext,
        status: TransactionResultStatus.success,
        title: 'Withdrawal recorded',
        message: '$amountText has been released from your Emergency Vault.',
        details: [
          TransactionResultDetail('Amount', amountText),
          TransactionResultDetail(
            'Reason',
            kEmergencyCategories[_category] ?? 'Emergency',
          ),
          TransactionResultDetail(
            'Vault left',
            EmergencyVault.formatMinor(
              _vault.balanceMinor(_currency),
              currency: _currency,
            ),
          ),
        ],
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ZentraNotifier.error('Withdrawal not allowed', errorMessage(e));
    }
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Emergency withdrawal',
                  style: AppTheme.headlineMedium,
                ),
              ),
              Text(
                'Step ${_step + 1} of $_steps',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            child: LinearProgressIndicator(
              value: (_step + 1) / _steps,
              minHeight: 6,
              color: AppTheme.brand,
              backgroundColor: AppTheme.gray100,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Expanded(child: SingleChildScrollView(child: _stepBody())),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingSm),
              child: Text(
                _error!,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.errorRed),
              ),
            ),
          const SizedBox(height: AppTheme.spacingSm),
          _footer(),
          const SizedBox(height: AppTheme.spacingLg),
        ],
      ),
    );
  }

  Widget _footer() {
    // The PIN step advances by itself once the PIN is right.
    if (_step == 4) {
      return _step > 0
          ? SecondaryButton(label: 'Back', onPressed: _back)
          : const SizedBox.shrink();
    }
    if (_step == _steps - 1) {
      return Column(
        children: [
          PrimaryButton(
            label: _secondsLeft > 0
                ? 'Confirm withdrawal (${_secondsLeft}s)'
                : 'Confirm withdrawal',
            loading: _submitting,
            onPressed: _secondsLeft > 0 ? null : _confirm,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          SecondaryButton(label: 'Back', onPressed: _back),
        ],
      );
    }
    return Column(
      children: [
        PrimaryButton(label: 'Continue', onPressed: _next),
        if (_step > 0) ...[
          const SizedBox(height: AppTheme.spacingSm),
          SecondaryButton(label: 'Back', onPressed: _back),
        ],
      ],
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return _categoryStep();
      case 1:
        return _reasonStep();
      case 2:
        return _amountStep();
      case 3:
        return _acknowledgeStep();
      case 4:
        return _pinStep();
      default:
        return _reviewStep();
    }
  }

  Widget _heading(String title, String body) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTheme.headlineSmall),
      const SizedBox(height: 4),
      Text(body, style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500)),
      const SizedBox(height: AppTheme.spacingMd),
    ],
  );

  // 0 ----------------------------------------------------------------------
  Widget _categoryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'What is the emergency?',
          'This fund is only for sudden events you could not plan for. '
              'Rent, shopping and regular bills are not emergencies.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kEmergencyCategories.entries.map((e) {
            final selected = _category == e.key;
            return ChoiceChip(
              label: Text(e.value),
              selected: selected,
              showCheckmark: false,
              selectedColor: AppTheme.brand.withValues(alpha: 0.15),
              backgroundColor: AppTheme.gray100,
              side: BorderSide(
                color: selected ? AppTheme.brand : Colors.transparent,
              ),
              labelStyle: AppTheme.labelLarge.copyWith(
                color: selected ? AppTheme.brand : AppTheme.textBlack,
              ),
              onSelected: (_) => setState(() {
                _category = e.key;
                _error = null;
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 1 ----------------------------------------------------------------------
  Widget _reasonStep() {
    final length = _reason.text.trim().length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Tell us what happened',
          'Your answer is saved with this withdrawal. Be specific.',
        ),
        TextField(
          controller: _reason,
          maxLines: 5,
          maxLength: 500,
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(
            labelText: 'What happened?',
            alignLabelWithHint: true,
            helperText: '$length / $_minReasonLength characters minimum',
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        TextField(
          controller: _usage,
          maxLength: 120,
          onChanged: (_) => setState(() => _error = null),
          decoration: const InputDecoration(
            labelText: 'What will the money pay for?',
            hintText: 'e.g. Hospital bill, repairs, bus fare home',
          ),
        ),
      ],
    );
  }

  // 2 ----------------------------------------------------------------------
  Widget _amountStep() {
    final balances = _vault.balancesMinor;
    final held = _vault.balanceMinor(_currency);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'How much do you need?',
          'Take only what the emergency needs - the rest stays protected.',
        ),
        if (balances.length > 1) ...[
          Wrap(
            spacing: 8,
            children: balances.keys.map((c) {
              final selected = c == _currency;
              return ChoiceChip(
                label: Text(c),
                selected: selected,
                showCheckmark: false,
                selectedColor: AppTheme.brand.withValues(alpha: 0.15),
                backgroundColor: AppTheme.gray100,
                side: BorderSide(
                  color: selected ? AppTheme.brand : Colors.transparent,
                ),
                onSelected: (_) => setState(() {
                  _currency = c;
                  _amount.clear();
                  _error = null;
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: AppTheme.spacingMd),
        ],
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(
            labelText: 'Amount ($_currency)',
            helperText:
                'Available: ${EmergencyVault.formatMinor(held, currency: _currency)}',
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Row(
          children: [
            for (final share in const [25, 50, 100])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(share == 100 ? 'All' : '$share%'),
                  onPressed: () => setState(() {
                    _amount.text = (held * share / 100 / 100).toStringAsFixed(
                      2,
                    );
                    _error = null;
                  }),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // 3 ----------------------------------------------------------------------
  Widget _acknowledgeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Please confirm',
          'Read each line and tick it. Take a moment before you go on.',
        ),
        for (var i = 0; i < _ackTexts.length; i++)
          CheckboxListTile(
            value: _acks[i],
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppTheme.brand,
            title: Text(_ackTexts[i], style: AppTheme.bodyMedium),
            onChanged: (v) => setState(() {
              _acks[i] = v ?? false;
              _error = null;
            }),
          ),
        const SizedBox(height: AppTheme.spacingSm),
        TextField(
          controller: _phrase,
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => setState(() => _error = null),
          decoration: const InputDecoration(
            labelText: 'Type EMERGENCY to continue',
          ),
        ),
      ],
    );
  }

  // 4 ----------------------------------------------------------------------
  Widget _pinStep() {
    if (_vault.isLocked) {
      final until = DateFormat('HH:mm').format(_vault.lockedUntil!);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXl),
        child: Column(
          children: [
            Icon(Icons.lock_clock_outlined, size: 48, color: AppTheme.errorRed),
            const SizedBox(height: AppTheme.spacingMd),
            Text('Vault locked', style: AppTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Too many wrong PINs. Try again after $until.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
            ),
          ],
        ),
      );
    }
    return VaultPinPad(
      title: 'Enter your vault PIN',
      subtitle:
          'This is the PIN you chose when you switched the vault on. '
          '${_vault.attemptsLeft} tries left before it locks.',
      onComplete: (pin) async {
        final result = await _vault.verifyPin(pin);
        if (!mounted) return null;
        switch (result) {
          case VaultPinResult.ok:
            setState(() {
              _pinOk = true;
              _error = null;
              _step++;
            });
            _startCountdown();
            return null;
          case VaultPinResult.locked:
            setState(() {}); // shows the locked panel
            return null;
          case VaultPinResult.wrong:
            return 'Wrong PIN. ${_vault.attemptsLeft} tries left.';
        }
      },
    );
  }

  // 5 ----------------------------------------------------------------------
  Widget _reviewStep() {
    final minor = _amountMinor ?? 0;
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
            ),
          ),
          Expanded(child: Text(value, style: AppTheme.labelLarge)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          'Review and confirm',
          'Last chance to change your mind. The button unlocks in a few seconds.',
        ),
        AppCard(
          child: Column(
            children: [
              row(
                'Amount',
                EmergencyVault.formatMinor(minor, currency: _currency),
              ),
              row('Emergency', kEmergencyCategories[_category] ?? ''),
              row('Pays for', _usage.text.trim()),
              row('What happened', _reason.text.trim()),
              row(
                'Vault after',
                EmergencyVault.formatMinor(
                  _vault.balanceMinor(_currency) - minor,
                  currency: _currency,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

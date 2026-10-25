import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/theme/section_header.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/zgrow/emergency/emergency_vault.dart';
import 'package:zentrapay_application/features/zgrow/emergency/emergency_withdraw_flow.dart';
import 'package:zentrapay_application/features/zgrow/emergency/vault_pin_sheet.dart';
import 'package:zentrapay_application/main.dart';

/// Emergency Vault: an on/off switch for round-up savings plus the (heavily
/// guarded) way to take the money out again.
class EmergencyVaultScreen extends StatefulWidget {
  const EmergencyVaultScreen({super.key});

  @override
  State<EmergencyVaultScreen> createState() => _EmergencyVaultScreenState();
}

class _EmergencyVaultScreenState extends State<EmergencyVaultScreen> {
  final EmergencyVault _vault = EmergencyVault.instance;
  bool _balanceHidden = false;

  @override
  void initState() {
    super.initState();
    _vault.load();
  }

  Future<void> _toggle(bool wantOn) async {
    if (wantOn) {
      if (_vault.hasPin) {
        await _vault.setActive(true);
        return;
      }
      final pin = await showCreateVaultPinSheet(context);
      if (pin == null || !mounted) return;
      await _vault.createPin(pin);
      if (!mounted) return;
      ZentraNotifier.success(
        'Emergency Vault is on',
        'Payments with cents will now round up and the difference is saved.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Switch the vault off?'),
        content: const Text(
          'Payments will stop rounding up. What you have already saved stays '
          'in the vault and is still protected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it on'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Switch off'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _vault.setActive(false);
  }

  Future<void> _withdraw() async {
    await showEmergencyWithdrawFlow(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: ListenableBuilder(
        listenable: _vault,
        builder: (context, _) {
          return Column(
            children: [
              SectionHeader(
                title: 'Emergency Vault',
                subtitle: 'Round-ups set aside for real emergencies',
                icon: Icons.health_and_safety_rounded,
                showBack: true,
                sheetColor: AppTheme.gray50,
                child: _balanceCard(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingMd,
                    AppTheme.spacingSm,
                    AppTheme.spacingMd,
                    AppTheme.spacingXl,
                  ),
                  children: [
                    _switchCard(),
                    const SizedBox(height: AppTheme.spacingMd),
                    _howItWorks(),
                    const SizedBox(height: AppTheme.spacingMd),
                    _withdrawCard(),
                    const SizedBox(height: AppTheme.spacingLg),
                    _historySection(
                      'Round-ups',
                      _vault.roundUps.take(10).toList(),
                      'Nothing saved yet. Switch the vault on and make a payment with cents.',
                    ),
                    if (_vault.withdrawals.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spacingLg),
                      _historySection(
                        'Withdrawals',
                        _vault.withdrawals.take(10).toList(),
                        '',
                      ),
                    ],
                    const SizedBox(height: AppTheme.spacingLg),
                    Text(
                      'Your vault balance and PIN are kept on this phone for '
                      'now. Round-ups are recorded here and are not yet held '
                      'in a separate bank account.',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.gray500,
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------- header

  Widget _balanceCard() {
    final balances = _vault.balancesMinor.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final main = balances.isEmpty ? null : balances.first;
    final String amount = main == null
        ? 'GHS 0.00'
        : EmergencyVault.formatMinor(main.value, currency: main.key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Vault balance',
              style: AppTheme.headlineSmall.copyWith(color: AppColors.primary),
            ),
            _statusPill(),
          ],
        ),
        AppTheme.divider(context, AppColors.primary),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _balanceHidden ? '••••••' : amount,
              style: AppTheme.headlineLarge.copyWith(color: AppColors.primary),
            ),
            IconButton(
              onPressed: () => setState(() => _balanceHidden = !_balanceHidden),
              icon: Icon(
                _balanceHidden ? Icons.visibility : Icons.visibility_off,
                size: 22,
                color: AppTheme.textBlack,
              ),
            ),
          ],
        ),
        if (balances.length > 1 && !_balanceHidden)
          Text(
            'Also: ${balances.skip(1).map((e) => EmergencyVault.formatMinor(e.value, currency: e.key)).join('  ·  ')}',
            style: AppTheme.bodySmall.copyWith(color: AppColors.primary),
          )
        else
          Text(
            '${_vault.roundUps.length} round-up${_vault.roundUps.length == 1 ? '' : 's'} saved',
            style: AppTheme.bodySmall.copyWith(color: AppColors.primary),
          ),
      ],
    );
  }

  Widget _statusPill() {
    final on = _vault.isActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(on ? 60 : 30),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            on ? Icons.check_circle : Icons.pause_circle_outline,
            size: 14,
            color: AppTheme.textBlack,
          ),
          const SizedBox(width: 4),
          Text(
            on ? 'Active' : 'Inactive',
            style: AppTheme.labelSmall.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- cards

  Widget _iconChip(IconData icon) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppTheme.brand.withAlpha(AppTheme.isDark ? 60 : 24),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: 20, color: AppTheme.textBlack),
  );

  Widget _switchCard() {
    return AppCard(
      child: Row(
        children: [
          _iconChip(Icons.savings_outlined),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Round-up savings', style: AppTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  _vault.isActive
                      ? 'Active - saving on every payment with cents'
                      : 'Inactive - nothing is being saved',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                ),
              ],
            ),
          ),
          Switch(
            value: _vault.isActive,
            onChanged: _toggle,
            thumbColor: WidgetStateProperty.all(AppTheme.primaryWhite),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            inactiveTrackColor: AppTheme.gray300,
            activeTrackColor: AppTheme.brand,
          ),
        ],
      ),
    );
  }

  Widget _howItWorks() {
    Widget step(IconData icon, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.textBlack),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(child: Text(text, style: AppTheme.bodyMedium)),
        ],
      ),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How it works', style: AppTheme.labelLarge),
          const SizedBox(height: AppTheme.spacingSm),
          step(
            Icons.arrow_upward_rounded,
            'You pay GHS 40.34. The vault rounds it up to GHS 40.50.',
          ),
          step(Icons.savings_outlined, 'The GHS 0.16 difference is saved.'),
          step(
            Icons.health_and_safety_outlined,
            'It can only be used for a real emergency, and taking it out '
            'needs a reason, confirmations and your vault PIN.',
          ),
        ],
      ),
    );
  }

  Widget _withdrawCard() {
    final locked = _vault.lockedUntil;
    final next = _vault.nextWithdrawalAt;
    String? blocked;
    if (!_vault.hasPin) {
      blocked = 'Switch the vault on first to set your vault PIN.';
    } else if (!_vault.hasBalance) {
      blocked = 'There is nothing in the vault to withdraw yet.';
    } else if (locked != null) {
      blocked =
          'Locked after wrong PINs until ${DateFormat('HH:mm').format(locked)}.';
    } else if (next != null) {
      blocked =
          'One withdrawal per day. Next one: ${DateFormat('d MMM, HH:mm').format(next)}.';
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconChip(Icons.lock_open_outlined),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Text(
                  'Withdraw for an emergency',
                  style: AppTheme.labelLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'You will be asked what happened, to explain it in writing, to '
            'confirm it is a real emergency and to enter your vault PIN.',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
          ),
          if (blocked != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              blocked,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.warningOrange),
            ),
          ],
          const SizedBox(height: AppTheme.spacingMd),
          PrimaryButton(
            label: 'Start withdrawal',
            onPressed: blocked == null ? _withdraw : null,
          ),
        ],
      ),
    );
  }

  Widget _historySection(
    String title,
    List<VaultEntry> items,
    String emptyText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.labelLarge),
        const SizedBox(height: AppTheme.spacingSm),
        if (items.isEmpty)
          Text(
            emptyText,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: AppTheme.dividerColor),
                  _entryRow(items[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _entryRow(VaultEntry e) {
    final withdrawal = e.isWithdrawal;
    final subtitle = withdrawal
        ? '${kEmergencyCategories[e.category] ?? 'Emergency'} · ${DateFormat('d MMM, HH:mm').format(e.at)}'
        : DateFormat('d MMM yyyy, HH:mm').format(e.at);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _iconChip(
            withdrawal
                ? Icons.arrow_downward_rounded
                : Icons.add_circle_outline_rounded,
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  withdrawal ? 'Emergency withdrawal' : 'Round-up saved',
                  style: AppTheme.labelLarge,
                ),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                ),
              ],
            ),
          ),
          Text(
            '${withdrawal ? '-' : '+'}${EmergencyVault.formatMinor(e.minor, currency: e.currency)}',
            style: AppTheme.labelLarge.copyWith(
              color: withdrawal ? AppTheme.primaryPink : AppTheme.successGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

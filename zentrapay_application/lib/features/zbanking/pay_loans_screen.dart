import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/theme/section_header.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/features/zbanking/repository/cache_zbanking_data.dart';
import 'package:zentrapay_application/features/zbanking/widgets/loan_application_sheet.dart';
import 'package:zentrapay_application/main.dart';

/// Pay Loans: what is owed, when it is due, and a way to repay it. Loans the
/// lender has not decided on yet and loans already settled are listed apart
/// from the ones that can be paid.
class PayLoansScreen extends StatefulWidget {
  const PayLoansScreen({super.key});

  @override
  State<PayLoansScreen> createState() => _PayLoansScreenState();
}

class _PayLoansScreenState extends State<PayLoansScreen> {
  static const _payable = {'ACTIVE', 'APPROVED'};
  static const _closed = {'REPAID', 'REJECTED', 'DEFAULTED', 'CANCELLED'};

  @override
  void initState() {
    super.initState();
    LoansRepository.instance.ensureLoaded().catchError((_) => null);
  }

  Future<void> _refresh() async {
    try {
      await LoansRepository.instance.ensureLoaded(forceRefresh: true);
    } catch (_) {
      // The error state is drawn from the repository.
    }
  }

  List<Loan> _where(List<Loan> loans, bool Function(String s) test) =>
      loans.where((l) => test(l.status.toUpperCase())).toList();

  double _owed(List<Loan> loans) =>
      loans.fold(0.0, (sum, l) => sum + l.outstandingBalance.toAmount());

  DateTime? _due(Loan loan) =>
      loan.dueDate == null ? null : DateTime.tryParse(loan.dueDate!);

  DateTime? _nextDue(List<Loan> payable) {
    final dates = payable.map(_due).whereType<DateTime>().toList()..sort();
    return dates.isEmpty ? null : dates.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: ListenableBuilder(
        listenable: LoansRepository.instance,
        builder: (context, _) {
          final repo = LoansRepository.instance;
          final loans = repo.data ?? const <Loan>[];
          final payable = _where(loans, _payable.contains);
          final pending = _where(loans, (s) => s == 'PENDING');
          final history = _where(loans, _closed.contains);
          final currency = payable.isNotEmpty
              ? payable.first.currencyCode
              : 'GHS';

          return Column(
            children: [
              SectionHeader(
                title: 'Pay Loans',
                subtitle: 'Repay on time and keep your loan grade strong',
                icon: Icons.payments_rounded,
                showBack: true,
                sheetColor: AppTheme.gray50,
                child: _summary(payable, currency),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.brand,
                  backgroundColor: AppTheme.surface,
                  onRefresh: _refresh,
                  child: _body(repo, loans, payable, pending, history),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------- header

  Widget _summary(List<Loan> payable, String currency) {
    final next = _nextDue(payable);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total you owe',
              style: AppTheme.headlineSmall.copyWith(color: AppColors.primary),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(200),
              ),
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppTheme.textBlack,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        AppTheme.divider(context, AppColors.primary),
        Text(
          formatMoney(_owed(payable).toStringAsFixed(2), symbol: '$currency '),
          style: AppTheme.headlineLarge.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 4),
        Text(
          payable.isEmpty
              ? 'No loan to repay right now.'
              : '${payable.length} active loan${payable.length == 1 ? '' : 's'}'
                    '${next == null ? '' : '  ·  next due ${DateFormat('d MMM yyyy').format(next)}'}',
          style: AppTheme.bodySmall.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------ body

  Widget _body(
    LoansRepository repo,
    List<Loan> loans,
    List<Loan> payable,
    List<Loan> pending,
    List<Loan> history,
  ) {
    if (repo.isLoading && repo.data == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(child: CircularProgressIndicator(color: AppTheme.brand)),
        ],
      );
    }
    if (repo.error != null && repo.data == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 60),
          EmptyStateWidget(
            icon: Icons.cloud_off_rounded,
            message: errorMessage(
              repo.error,
              fallback: "We couldn't load your loans. Pull down to try again.",
            ),
            actionLabel: 'Retry',
            onAction: _refresh,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
        AppTheme.spacingXl,
      ),
      children: [
        if (loans.isEmpty)
          _emptyState()
        else ...[
          if (payable.isNotEmpty) ...[
            Text('To repay', style: AppTheme.labelLarge),
            const SizedBox(height: AppTheme.spacingSm),
            for (final loan in payable) _loanCard(loan, payable: true),
          ],
          if (pending.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Text('Waiting for a decision', style: AppTheme.labelLarge),
            const SizedBox(height: AppTheme.spacingSm),
            for (final loan in pending) _loanCard(loan),
          ],
          if (history.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Text('Past loans', style: AppTheme.labelLarge),
            const SizedBox(height: AppTheme.spacingSm),
            for (final loan in history) _loanCard(loan),
          ],
        ],
        const SizedBox(height: AppTheme.spacingLg),
        _applyCard(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXl),
      child: EmptyStateWidget(
        icon: Icons.verified_outlined,
        message: "You don't have any loans. Nothing to pay.",
      ),
    );
  }

  Widget _applyCard() {
    return AppCard(
      child: Row(
        children: [
          _chip(Icons.request_quote_outlined),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Need a loan?', style: AppTheme.labelLarge),
                Text(
                  'See what you qualify for and apply.',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => showLoanApplicationSheet(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppTheme.brand.withAlpha(AppTheme.isDark ? 60 : 24),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: 20, color: AppTheme.textBlack),
  );

  // ----------------------------------------------------------------- cards

  Color _statusColor(String status) {
    switch (status) {
      case 'REPAID':
        return AppTheme.successGreen;
      case 'PENDING':
        return AppTheme.warningOrange;
      case 'REJECTED':
      case 'DEFAULTED':
      case 'CANCELLED':
        return AppTheme.errorRed;
      default:
        return AppTheme.brand;
    }
  }

  /// Same arithmetic as the lender: principal plus simple interest over the term.
  double _totalRepayable(Loan loan) {
    final principal = loan.principalAmount.toAmount();
    final rate = loan.interestRate.toAmount();
    return principal + principal * rate * loan.termMonths / 12;
  }

  Widget _loanCard(Loan loan, {bool payable = false}) {
    final status = loan.status.toUpperCase();
    final tone = _statusColor(status);
    final owed = loan.outstandingBalance.toAmount();
    final total = _totalRepayable(loan);
    final paid = total <= 0 ? 0.0 : ((total - owed) / total).clamp(0.0, 1.0);
    final due = _due(loan);
    final overdue =
        payable && due != null && owed > 0 && due.isBefore(DateTime.now());
    String money(String v) => formatMoney(v, symbol: '${loan.currencyCode} ');

    Widget row(String label, String value, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
          ),
          Text(value, style: AppTheme.labelLarge.copyWith(color: color)),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _chip(Icons.payments_outlined),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _purposeLabel(loan.purpose),
                        style: AppTheme.labelLarge,
                      ),
                      Text(
                        '${loan.termMonths} months · ${(loan.interestRate.toAmount() * 100).toStringAsFixed(1)}% a year',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusPill(
                  overdue ? 'OVERDUE' : status,
                  overdue ? AppTheme.errorRed : tone,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            if (payable) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                child: LinearProgressIndicator(
                  value: paid,
                  minHeight: 8,
                  color: AppTheme.brand,
                  backgroundColor: AppTheme.gray100,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${(paid * 100).round()}% repaid',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
              ),
              const SizedBox(height: AppTheme.spacingSm),
            ],
            row('Borrowed', money(loan.principalAmount)),
            if (payable || status == 'PENDING')
              row('Monthly instalment', money(loan.monthlyInstallment)),
            if (payable) row('Still owed', money(loan.outstandingBalance)),
            if (due != null && payable)
              row(
                'Due',
                DateFormat('d MMM yyyy').format(due),
                color: overdue ? AppTheme.errorRed : null,
              ),
            if ((loan.decisionNote ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                loan.decisionNote!.trim(),
                style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
              ),
            ],
            if (payable && owed > 0) ...[
              const SizedBox(height: AppTheme.spacingMd),
              PrimaryButton(label: 'Repay', onPressed: () => _openRepay(loan)),
            ],
          ],
        ),
      ),
    );
  }

  String _purposeLabel(String? purpose) {
    final text = (purpose ?? '').trim();
    if (text.isEmpty) return 'Loan';
    final lower = text.replaceAll('_', ' ').toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)} loan';
  }

  Widget _statusPill(String text, Color tone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withAlpha(32),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        text[0] + text.substring(1).toLowerCase(),
        style: AppTheme.labelSmall.copyWith(
          color: tone,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- repay

  void _openRepay(Loan loan) {
    showAppOverlaySheet<void>(
      context: context,
      minHeightFraction: 0.55,
      maxWidth: 560,
      builder: (_) => _RepaySheet(loan: loan),
    );
  }
}

class _RepaySheet extends StatefulWidget {
  final Loan loan;

  const _RepaySheet({required this.loan});

  @override
  State<_RepaySheet> createState() => _RepaySheetState();
}

class _RepaySheetState extends State<_RepaySheet> {
  late final TextEditingController _amount;
  bool _paying = false;
  String? _error;

  double get _owed => widget.loan.outstandingBalance.toAmount();
  double get _instalment {
    final due = widget.loan.monthlyInstallment.toAmount();
    return due <= 0 ? _owed : due.clamp(0.0, _owed);
  }

  String _money(double v) =>
      formatMoney(v.toStringAsFixed(2), symbol: '${widget.loan.currencyCode} ');

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: _instalment.toStringAsFixed(2));
    WalletsRepository.instance.ensureLoaded().catchError((_) => null);
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final value = double.tryParse(_amount.text.trim());
    if (value == null || value <= 0) {
      setState(() => _error = 'Enter the amount you want to pay.');
      return;
    }
    if (value > _owed + 0.001) {
      setState(
        () => _error = 'That is more than the ${_money(_owed)} you owe.',
      );
      return;
    }
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      final updated = await LoansRepository.instance.repay(
        widget.loan.loanId,
        value.toStringAsFixed(2),
      );
      WalletsRepository.instance.refresh().catchError((_) => null);
      if (!mounted) return;
      Navigator.of(context).pop();
      final cleared = updated.outstandingBalance.toAmount() <= 0.001;
      ZentraNotifier.success(
        cleared ? 'Loan fully repaid' : 'Repayment received',
        cleared
            ? 'Thank you - this loan is now cleared.'
            : '${_money(value)} paid. ${_money(updated.outstandingBalance.toAmount())} left to pay.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _error = errorMessage(
          e,
          fallback: "We couldn't take that payment. Nothing was deducted.",
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Repay loan', style: AppTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'You owe ${_money(_owed)}. The money is taken from your wallet.',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          TextField(
            controller: _amount,
            enabled: !_paying,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: 'Amount (${widget.loan.currencyCode})',
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: Text('Instalment ${_money(_instalment)}'),
                onPressed: _paying
                    ? null
                    : () => setState(
                        () => _amount.text = _instalment.toStringAsFixed(2),
                      ),
              ),
              ActionChip(
                label: const Text('Pay it all'),
                onPressed: _paying
                    ? null
                    : () => setState(
                        () => _amount.text = _owed.toStringAsFixed(2),
                      ),
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
          PrimaryButton(label: 'Pay now', loading: _paying, onPressed: _pay),
          const SizedBox(height: AppTheme.spacingLg),
        ],
      ),
    );
  }
}

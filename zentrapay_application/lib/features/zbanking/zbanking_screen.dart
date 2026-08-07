import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/core/repositories/zbanking_repository.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/main.dart';

class ZBankingScreen extends StatefulWidget {
  const ZBankingScreen({super.key});

  @override
  State<ZBankingScreen> createState() => _ZBankingScreenState();
}

class _ZBankingScreenState extends State<ZBankingScreen> {
  bool _balanceHidden = false;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget: ListenableBuilder below rebuilds when each resolves.
    SavingsRepository.instance.ensureLoaded();
    LoansRepository.instance.ensureLoaded();
    BudgetRepository.instance.ensureLoaded();
    BankingInsightsRepository.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.gray50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            _buildHeader(context),
            _buildQuickActions(context),
            _buildSavingsSection(context),
            _buildLoansSection(context),
            _buildBudgetSection(context),
            _buildAiInsights(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width > 470;
    final headerWidth = isTablet ? 400.0 : double.infinity;
    return Container(
      decoration: AppTheme.coloredCardDecoration(AppColors.secondary),
      width: headerWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "ZBank Lite",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Icon(
                          Icons.call_received_outlined,
                          size: 22.0,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingLg),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Icon(
                          Icons.call_made_outlined,
                          size: 22.0,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            AppTheme.divider(context, AppTheme.primaryWhite),
            Text(
              "Digital savings & micro-loans",
              style: TextStyle(color: AppTheme.primaryWhite, fontSize: 14),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ConstrainedBox(
              constraints: AppTheme.constraintsXs(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ListenableBuilder(
                    listenable: SavingsRepository.instance,
                    builder: (context, _) {
                      final repo = SavingsRepository.instance;
                      final accounts = repo.data;
                      if (_balanceHidden) {
                        return const Text(
                          "•••••",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                      if (accounts == null && repo.isLoading) {
                        return const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        );
                      }
                      if (accounts == null && repo.error != null) {
                        return Text(
                          "-- GHS",
                          style: TextStyle(
                            color: AppColors.primary.withAlpha(180),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                      final total = (accounts ?? []).fold<double>(
                        0,
                        (sum, a) => sum + a.balance.toAmount(),
                      );
                      return Text(
                        formatMoney(total.toStringAsFixed(2), symbol: 'GHS '),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _balanceHidden = !_balanceHidden),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Icon(
                          _balanceHidden
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 22,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ConstrainedBox(
              constraints: AppTheme.constraintsXs(context),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(200),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 10.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "primary",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w200,
                        ),
                      ),
                      AppTheme.dot(AppColors.primary),
                      Text(
                        "active",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w200,
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
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          QuickActionButton(
            icon: Icons.savings,
            label: "Save",
            onTap: () => _showCreateSavingsDialog(context),
            color: AppColors.secondary,
          ),
          QuickActionButton(
            icon: Icons.account_balance_wallet,
            label: "Borrow",
            onTap: () => _showLoanApplyDialog(context),
            color: AppColors.secondary,
          ),
          QuickActionButton(
            icon: Icons.track_changes,
            label: "Budget",
            onTap: () => _showBudgetLimitDialog(context),
            color: AppColors.secondary,
          ),
          QuickActionButton(
            icon: Icons.lock,
            label: "Vault",
            onTap: () => showComingSoon(context, "Emergency Vault"),
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAVINGS
  // ============================================================

  Widget _buildSavingsSection(BuildContext context) {
    return ListenableBuilder(
      listenable: SavingsRepository.instance,
      builder: (context, _) {
        final repo = SavingsRepository.instance;
        final accounts = repo.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Digital Savings",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showCreateSavingsDialog(context),
                  icon: const Icon(Icons.add, size: 18, color: AppTheme.zbankColor),
                  label: const Text(
                    "New",
                    style: TextStyle(color: AppTheme.zbankColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            if (accounts == null && repo.isLoading)
              const AppCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (accounts == null && repo.error != null)
              _errorCard(
                message: "Couldn't load your savings accounts.",
                onRetry: () => repo.ensureLoaded(forceRefresh: true),
              )
            else if (accounts == null || accounts.isEmpty)
              AppCard(
                child: EmptyStateWidget(
                  icon: Icons.savings_outlined,
                  message: "No savings accounts yet. Start saving toward a goal.",
                  actionLabel: "Start Saving",
                  onAction: () => _showCreateSavingsDialog(context),
                ),
              )
            else
              Column(
                children: [
                  for (final account in accounts) _savingsCard(account),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _savingsCard(SavingsAccount account) {
    final target = account.targetAmount;
    final targetValue = target?.toAmount() ?? 0;
    final progress = (target != null && targetValue > 0)
        ? (account.balance.toAmount() / targetValue).clamp(0.0, 1.0)
        : null;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    account.savingsName,
                    style: AppTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _statusBadge(account.status),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              formatMoney(account.balance, symbol: '${account.currencyCode} '),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.zbankColor,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: AppTheme.spacingSm),
              ClipRRect(
                borderRadius: BorderRadius.circular(200),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppTheme.gray100,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.zbankColor),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'Target: ${formatMoney(target!, symbol: '${account.currencyCode} ')}'
                '${account.targetDate != null ? ' by ${account.targetDate}' : ''}',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
              ),
            ],
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showAmountDialog(
                      context,
                      title: 'Deposit to ${account.savingsName}',
                      actionLabel: 'Deposit',
                      onSubmit: (amount) =>
                          _deposit(account, amount),
                    ),
                    child: const Text('Deposit'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showAmountDialog(
                      context,
                      title: 'Withdraw from ${account.savingsName}',
                      actionLabel: 'Withdraw',
                      onSubmit: (amount) =>
                          _withdraw(account, amount),
                    ),
                    child: const Text('Withdraw'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deposit(SavingsAccount account, String amount) async {
    await SavingsRepository.instance.deposit(account.savingsId, amount);
    ZentraNotifier.success(
      'Deposit Successful',
      'Added GHS $amount to ${account.savingsName}.',
    );
  }

  Future<void> _withdraw(SavingsAccount account, String amount) async {
    await SavingsRepository.instance.withdraw(account.savingsId, amount);
    ZentraNotifier.success(
      'Withdrawal Successful',
      'Withdrew GHS $amount from ${account.savingsName}.',
    );
  }

  // ============================================================
  // LOANS
  // ============================================================

  Widget _buildLoansSection(BuildContext context) {
    return ListenableBuilder(
      listenable: LoansRepository.instance,
      builder: (context, _) {
        final repo = LoansRepository.instance;
        final loans = repo.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Micro-Loans",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showLoanApplyDialog(context),
                  icon: const Icon(Icons.add, size: 18, color: AppTheme.zbankColor),
                  label: const Text(
                    "Apply",
                    style: TextStyle(color: AppTheme.zbankColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            if (loans == null && repo.isLoading)
              const AppCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (loans == null && repo.error != null)
              _errorCard(
                message: "Couldn't load your loans.",
                onRetry: () => repo.ensureLoaded(forceRefresh: true),
              )
            else if (loans == null || loans.isEmpty)
              AppCard(
                child: EmptyStateWidget(
                  icon: Icons.handshake_outlined,
                  message: "No active loans. Apply for a micro-loan anytime.",
                  actionLabel: "Apply Now",
                  onAction: () => _showLoanApplyDialog(context),
                ),
              )
            else
              Column(
                children: [for (final loan in loans) _loanCard(loan)],
              ),
          ],
        );
      },
    );
  }

  Widget _loanCard(Loan loan) {
    final status = loan.status.toUpperCase();
    final canRepay =
        loan.outstandingBalance.toAmount() > 0 &&
        status != 'PAID' &&
        status != 'REJECTED' &&
        status != 'PENDING';
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Loan • ${loan.termMonths} mo', style: AppTheme.titleLarge),
                _statusBadge(loan.status),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Outstanding: ${formatMoney(loan.outstandingBalance)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.zbankColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Principal ${formatMoney(loan.principalAmount)} · '
              '${loan.interestRate}% APR'
              '${loan.dueDate != null ? ' · Due ${loan.dueDate}' : ''}',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
            ),
            if (canRepay) ...[
              const SizedBox(height: AppTheme.spacingSm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showAmountDialog(
                    context,
                    title: 'Repay Loan',
                    actionLabel: 'Repay',
                    onSubmit: (amount) => _repayLoan(loan, amount),
                  ),
                  child: const Text('Repay'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _repayLoan(Loan loan, String amount) async {
    await LoansRepository.instance.repay(loan.loanId, amount);
    ZentraNotifier.success(
      'Repayment Successful',
      'Repaid GHS $amount towards your loan.',
    );
  }

  // ============================================================
  // BUDGET
  // ============================================================

  Widget _buildBudgetSection(BuildContext context) {
    return ListenableBuilder(
      listenable: BudgetRepository.instance,
      builder: (context, _) {
        final repo = BudgetRepository.instance;
        final summary = repo.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Budget Tracker",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showBudgetLimitDialog(context),
                  icon: const Icon(Icons.edit, size: 16, color: AppTheme.zbankColor),
                  label: const Text(
                    "Edit Limit",
                    style: TextStyle(color: AppTheme.zbankColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            if (summary == null && repo.isLoading)
              const AppCard(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (summary == null && repo.error != null)
              _errorCard(
                message: "Couldn't load your budget.",
                onRetry: () => repo.ensureLoaded(forceRefresh: true),
              )
            else if (summary == null)
              AppCard(
                child: EmptyStateWidget(
                  icon: Icons.track_changes,
                  message: "Set a monthly budget to start tracking your spend.",
                  actionLabel: "Set Budget",
                  onAction: () => _showBudgetLimitDialog(context),
                ),
              )
            else
              _budgetCard(summary),
          ],
        );
      },
    );
  }

  Widget _budgetCard(BudgetSummary summary) {
    final limit = summary.monthlyLimit.toAmount();
    final spent = summary.spentThisMonth.toAmount();
    final progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final overBudget = limit > 0 && spent > limit;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${formatMoney(summary.spentThisMonth)}',
                style: AppTheme.titleLarge,
              ),
              Text(
                'Limit: ${formatMoney(summary.monthlyLimit)}',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(200),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.gray100,
              valueColor: AlwaysStoppedAnimation(
                overBudget ? AppTheme.errorRed : AppTheme.zbankColor,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            overBudget
                ? 'Over budget by ${formatMoney((spent - limit).toStringAsFixed(2))}'
                : 'Remaining: ${formatMoney(summary.remaining)}',
            style: AppTheme.bodySmall.copyWith(
              color: overBudget ? AppTheme.errorRed : AppTheme.gray500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AI INSIGHTS
  // ============================================================

  Widget _buildAiInsights(BuildContext context) {
    return ListenableBuilder(
      listenable: BankingInsightsRepository.instance,
      builder: (context, _) {
        final repo = BankingInsightsRepository.instance;
        final insights = repo.data;

        if (insights == null && repo.isLoading) {
          return _insightsShell(
            const AppCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          );
        }
        if (insights == null && repo.error != null) {
          return _insightsShell(
            _errorCard(
              message: "Couldn't load your insights.",
              onRetry: () => repo.ensureLoaded(forceRefresh: true),
            ),
          );
        }

        final message = insights == null
            ? "No insights available yet."
            : _insightMessage(insights);

        return _insightsShell(
          AIInsightCard(
            message: message,
            onTap: () => Navigator.pushNamed(context, '/ai_assistance'),
          ),
        );
      },
    );
  }

  Widget _insightsShell(Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "AI Insights",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        child,
      ],
    );
  }

  String _insightMessage(BankingInsights insights) {
    final spend = insights.monthlySpend.toAmount();
    final income = insights.monthlyIncome.toAmount();
    if (income > 0 && spend > income) {
      return "You've spent ${formatMoney(insights.monthlySpend)} this month, "
          "more than your ${formatMoney(insights.monthlyIncome)} income. "
          "Consider reviewing your top spend categories.";
    }
    if (income > 0) {
      final saved = income - spend;
      return "You're on track this month — spent ${formatMoney(insights.monthlySpend)} "
          "of ${formatMoney(insights.monthlyIncome)} income, leaving "
          "${formatMoney(saved.toStringAsFixed(2))} to save.";
    }
    if (insights.topCategories.isNotEmpty) {
      final top = insights.topCategories.first;
      return "Your biggest spend category this month is ${top.categoryCode} "
          "at ${formatMoney(top.amount)}.";
    }
    return "You've spent ${formatMoney(insights.monthlySpend)} this month.";
  }

  // ============================================================
  // SHARED HELPERS
  // ============================================================

  Widget _errorCard({required String message, required VoidCallback onRetry}) {
    return AppCard(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 32),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(200),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
      case 'APPROVED':
      case 'PAID':
        return AppTheme.successGreen;
      case 'PENDING':
        return AppTheme.warningOrange;
      case 'REJECTED':
      case 'DEFAULTED':
      case 'CLOSED':
        return AppTheme.errorRed;
      default:
        return AppTheme.gray500;
    }
  }

  // ============================================================
  // DIALOGS / BOTTOM SHEETS
  // ============================================================

  Future<void> _showAmountDialog(
    BuildContext context, {
    required String title,
    required String actionLabel,
    required Future<void> Function(String amount) onSubmit,
  }) async {
    final controller = TextEditingController();
    bool submitting = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(title),
              content: TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'Amount',
                  prefixText: 'GHS ',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final amount = controller.text.trim();
                          final parsed = double.tryParse(amount);
                          if (amount.isEmpty || parsed == null || parsed <= 0) {
                            ZentraNotifier.error(
                              'Invalid Amount',
                              'Enter a valid amount greater than zero.',
                            );
                            return;
                          }
                          setState(() => submitting = true);
                          try {
                            await onSubmit(amount);
                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                          } catch (e) {
                            setState(() => submitting = false);
                            ZentraNotifier.error('Action Failed', e.toString());
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(actionLabel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCreateSavingsDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final depositController = TextEditingController();
    final targetController = TextEditingController();
    bool submitting = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (sheetContext, setState) {
              return Container(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryWhite,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusXl),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start a New Savings Goal',
                      style: AppTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    AppTextField(
                      controller: nameController,
                      labelText: 'Savings name',
                      hintText: 'e.g. Rent Fund',
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    AppTextField(
                      controller: depositController,
                      labelText: 'Initial deposit (GHS)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    AppTextField(
                      controller: targetController,
                      labelText: 'Target amount (optional)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    PrimaryButton(
                      label: 'Create Savings',
                      loading: submitting,
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final deposit = depositController.text.trim();
                        final parsedDeposit = double.tryParse(deposit);
                        if (name.isEmpty) {
                          ZentraNotifier.error(
                            'Missing Name',
                            'Give your savings goal a name.',
                          );
                          return;
                        }
                        if (deposit.isEmpty ||
                            parsedDeposit == null ||
                            parsedDeposit < 0) {
                          ZentraNotifier.error(
                            'Invalid Deposit',
                            'Enter a valid initial deposit.',
                          );
                          return;
                        }
                        final target = targetController.text.trim();
                        setState(() => submitting = true);
                        try {
                          await SavingsRepository.instance.create(
                            savingsName: name,
                            currencyCode: 'GHS',
                            initialDeposit: deposit,
                            targetAmount: target.isEmpty ? null : target,
                          );
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          ZentraNotifier.success(
                            'Savings Created',
                            '$name is ready to grow.',
                          );
                        } catch (e) {
                          setState(() => submitting = false);
                          ZentraNotifier.error(
                            "Couldn't Create Savings",
                            e.toString(),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showLoanApplyDialog(BuildContext context) async {
    final amountController = TextEditingController();
    int termMonths = 3;
    bool submitting = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (sheetContext, setState) {
              return Container(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryWhite,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusXl),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Apply for a Micro-Loan',
                      style: AppTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    AppTextField(
                      controller: amountController,
                      labelText: 'Loan amount (GHS)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text('Term: $termMonths months', style: AppTheme.bodyMedium),
                    Slider(
                      value: termMonths.toDouble(),
                      min: 1,
                      max: 24,
                      divisions: 23,
                      activeColor: AppTheme.zbankColor,
                      label: '$termMonths months',
                      onChanged: (value) =>
                          setState(() => termMonths = value.round()),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    PrimaryButton(
                      label: 'Submit Application',
                      loading: submitting,
                      onPressed: () async {
                        final amount = amountController.text.trim();
                        final parsed = double.tryParse(amount);
                        if (amount.isEmpty || parsed == null || parsed <= 0) {
                          ZentraNotifier.error(
                            'Invalid Amount',
                            'Enter a valid loan amount.',
                          );
                          return;
                        }
                        setState(() => submitting = true);
                        try {
                          final loan = await LoansRepository.instance.apply(
                            amount: amount,
                            currencyCode: 'GHS',
                            termMonths: termMonths,
                          );
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          ZentraNotifier.success(
                            'Loan Application Submitted',
                            'Status: ${loan.status}',
                          );
                        } catch (e) {
                          setState(() => submitting = false);
                          ZentraNotifier.error('Application Failed', e.toString());
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showBudgetLimitDialog(BuildContext context) async {
    final currentLimit = BudgetRepository.instance.data?.monthlyLimit;
    final controller = TextEditingController(text: currentLimit);
    bool submitting = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Set Monthly Budget'),
              content: TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'Monthly limit',
                  prefixText: 'GHS ',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final limit = controller.text.trim();
                          final parsed = double.tryParse(limit);
                          if (limit.isEmpty || parsed == null || parsed < 0) {
                            ZentraNotifier.error(
                              'Invalid Limit',
                              'Enter a valid monthly limit.',
                            );
                            return;
                          }
                          setState(() => submitting = true);
                          try {
                            await BudgetRepository.instance.setMonthlyLimit(limit);
                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                            ZentraNotifier.success(
                              'Budget Updated',
                              'Your monthly limit is now GHS $limit.',
                            );
                          } catch (e) {
                            setState(() => submitting = false);
                            ZentraNotifier.error('Update Failed', e.toString());
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

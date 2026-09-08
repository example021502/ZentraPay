import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/features/zbanking/repository/cache_zbankingData.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/features/zbanking/widgets/LinkedBankAccounts.dart';
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
    BankAccountsRepository.instance.ensureLoaded();
    LoansRepository.instance.ensureLoaded();
    BudgetRepository.instance.ensureLoaded();
    BankingInsightsRepository.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width > 470;
    final double maxWidth = isTablet ? 400 : MediaQuery.of(context).size.width;
    final bankAccounts = BankAccountsRepository.instance.data ?? [];
    return SizedBox(
      width: maxWidth,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            _buildHeader(context, Map<String, dynamic>.of({})),
            const SizedBox(height: AppTheme.spacingMd),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.gray50,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppTheme.spacingMd,
                  children: [
                    // if (bankAccounts.isNotEmpty)
                    LinkedBankAccounts(accounts: bankAccounts),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildAccountOptionsSection(context),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildAiInsights(context),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    BuildContext context,
    Map<String, dynamic> primaryAccount,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: primaryAccount.isEmpty
          ? _emptyAccount()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ZBanking Overview",
                  style: AppTheme.bodyMedium.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Next-gen banking\nEffortless living",
                      style: AppTheme.whiteHeadline,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.expand_less_outlined,
                          size: 22,
                          color: AppColors.primary,
                        ),
                        Text(
                          "14.2",
                          style: AppTheme.headlineSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),
                ConstrainedBox(
                  constraints: AppTheme.constraintsXs(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ListenableBuilder(
                        listenable: BankAccountsRepository.instance,
                        builder: (context, _) {
                          final repo = BankAccountsRepository.instance;
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
                            (sum, a) => sum + a.balance,
                          );
                          return Text(
                            formatMoney(
                              total.toStringAsFixed(2),
                              symbol: 'GHS ',
                            ),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _balanceHidden = !_balanceHidden),
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
                const SizedBox(height: AppTheme.spacingMd),
              ],
            ),
    );
  }

  // PLACEHOLDER FOR PRIMARY BANK ACCOUNT
  // Placeholder for primary bank account
  Widget _emptyAccount() {
    // Define total card height (160) plus extra offset spacing needed for back-layer cards (28)
    const double cardHeight = 160.0;
    const double topOffset = 28.0;

    return Material(
      color: Colors.transparent, // Ensures no solid background interference
      child: SizedBox(
        height: cardHeight + topOffset, // Explicitly reserve container height
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Layer 3 (Deepest back layer)
            Positioned(
              top: 0,
              left: 16,
              right: 16,
              child: Opacity(
                opacity: 0.3,
                child: Container(
                  height: cardHeight,
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                ),
              ),
            ),
            // Layer 2 (Middle layer)
            Positioned(
              top: 14,
              left: 8,
              right: 8,
              child: Opacity(
                opacity: 0.65,
                child: Container(
                  height: cardHeight,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                ),
              ),
            ),
            // Main front layer (Empty State Content)
            Positioned(
              top: topOffset,
              left: 0,
              right: 0,
              child: Container(
                width: double.infinity,
                height: cardHeight,
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: BoxDecoration(
                  gradient: AppTheme.secondaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white70,
                        size: 28,
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        "No primary bank account set.",
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryWhite,
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
  // ACCOUNT OPTIONS (Digital Savings / Micro-Loans / Budget Tracker)
  // ============================================================
  // Simple navigation-style rows for now — dedicated per-feature screens
  // are still to be introduced. Tapping one opens the same quick dialog
  // the header's quick-action buttons use.

  Widget _buildAccountOptionsSection(BuildContext context) {
    List<Map<String, dynamic>> goals = [
      {
        "title": "testing",
        "description": "hellow there, testing goals",
        "progress": "80%",
      },
    ];
    return Column(
      children: [
        _accountOptionTile(
          context,
          icon: Icons.payments_outlined,
          label: "Micro-loan",
          about: "Get immediate working capital tailored to your needs.",
          onTap: () => _showLoanApplyDialog(context),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _accountOptionTile(
          context,
          icon: Icons.track_changes_outlined,
          label: "Your financial goals",
          about: "Invest your savings into your career goals.",
          onTap: () => _showCreateSavingsDialog(context, goals),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _accountOptionTile(
          context,
          icon: Icons.currency_exchange_outlined,
          label: "Smart Conversion",
          about: "Real-time currency conversion basing on live markets.",
          onTap: () => Navigator.pushNamed(context, "/converter"),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _accountOptionTile(
          context,
          icon: Icons.account_balance_outlined,
          label: "Open Banking",
          about: "Put your money to work instantly without the wait.",
          onTap: () => showComingSoon(context, "Open Banking"),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        _accountOptionTile(
          context,
          icon: Icons.hub_outlined,
          label: "Global Liquidity",
          about: "Unlock trapped capital. Power your global operations.",
          onTap: () => showComingSoon(context, "Global liquidity"),
        ),
      ],
    );
  }

  Widget _accountOptionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String about,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.secondaryNavy.withAlpha(10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Icon(icon, color: AppColors.secondary, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTheme.labelLarge),
                    Text(
                      about,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textBlack.withAlpha(150),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
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

        // Only surface the AI Insights section once real insight data has
        // actually been loaded. While it's still null (loading, not yet
        // fetched, or unavailable) render nothing — an empty/spinner card
        // adds noise when there's nothing to say yet.
        if (insights == null) {
          return const SizedBox(width: 0, height: 0);
        }

        return _insightsShell(
          AIInsightCard(
            message: _insightMessage(insights),
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
        const Text("AI Insights", style: AppTheme.bodyMedium),
        const SizedBox(height: AppTheme.spacingSm),
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

  // Scoped out — the AI Insights section now only renders once data is
  // present, so this retry card is no longer reached from it. Kept for
  // future error surfaces on this screen.
  // ignore: unused_element
  Widget _errorCard({required String message, required VoidCallback onRetry}) {
    return Column(
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
    );
  }

  // ============================================================
  // DIALOGS / BOTTOM SHEETS
  // ============================================================

  Future<void> _showCreateSavingsDialog(
    BuildContext context,
    List<Map<String, dynamic>> goals,
  ) async {
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
                    const Text('Goals', style: AppTheme.headlineSmall),
                    const SizedBox(height: AppTheme.spacingMd),
                    if (goals.isNotEmpty)
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 150),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(
                            children: [
                              ListView.builder(
                                itemCount: goals.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  // Builder function returning a widget for each index
                                  final goal =
                                      goals[index]; // Access the individual goal item
                                  final n = double.parse(
                                    goal['progress'].replaceAll('%', ''),
                                  );
                                  final bool isGreen = n > 50;
                                  return Material(
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 5.0,
                                        horizontal: 10.0,
                                      ),
                                      tileColor: AppTheme.secondaryNavy
                                          .withAlpha(
                                            20,
                                          ), // Background color in normal state
                                      selectedTileColor: AppTheme.lightGrey,
                                      selected: false,
                                      iconColor: AppTheme
                                          .textBlack, // Color for leading & trailing icons
                                      textColor: AppTheme.textBlack,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          15.0,
                                        ),
                                        side: BorderSide(
                                          color: AppTheme.lightGrey,
                                          width: 0.5,
                                        ),
                                      ),
                                      leading: Container(
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryNavy
                                              .withAlpha(20),
                                          borderRadius: BorderRadius.circular(
                                            200,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: const Icon(Icons.flag),
                                        ),
                                      ), // Icon on the left side
                                      title: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            goal["title"] ?? "Unknown",
                                            style: AppTheme.bodyMedium,
                                          ),
                                          Text(
                                            goal["progress"] ?? "0%",
                                            style: AppTheme.headlineSmall
                                                .copyWith(
                                                  color: isGreen
                                                      ? AppTheme.successGreen
                                                      : AppTheme.warningOrange,
                                                ),
                                          ),

                                          Container(
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryPink
                                                  .withAlpha(20),
                                              borderRadius:
                                                  BorderRadius.circular(200),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 2.0,
                                                    horizontal: 10.0,
                                                  ),
                                              child: Text(
                                                "active",
                                                style: AppTheme.bodySmall,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ), // Primary text element
                                      subtitle: Text(
                                        goal["description"] ?? "Unknown",
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.textBlack.withAlpha(
                                            100,
                                          ),
                                        ),
                                      ), // Secondary text element
                                      trailing: const Icon(
                                        Icons.chevron_right,
                                      ), // Icon on the right side
                                      onTap: () {
                                        // Interaction callback when tapped
                                        // Handle tap action
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      "You want to set a new goal?",
                      style: AppTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    AppTextField(
                      controller: nameController,
                      labelText: 'Name',
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
                      label: 'Create',
                      loading: submitting,
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final deposit = depositController.text.trim();
                        final parsedDeposit = double.tryParse(deposit);
                        if (name.isEmpty) {
                          ZentraNotifier.error(
                            'Missing Name',
                            'Give your Goal a name.',
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
                          await BankAccountsRepository.instance.create(
                            savingsName: name,
                            description: '',
                            bankId: '',
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
                    Text(
                      'Term: $termMonths months',
                      style: AppTheme.bodyMedium,
                    ),
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
                          ZentraNotifier.error(
                            'Application Failed',
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
              title: const Text('Set Monthly Goal'),
              content: TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  hintText: 'Monthly limit',
                  prefixText: 'GHS ',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.pop(dialogContext),
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
                            await BudgetRepository.instance.setMonthlyLimit(
                              limit,
                            );
                            if (dialogContext.mounted)
                              Navigator.pop(dialogContext);
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
                      : const Text('Set Goal'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

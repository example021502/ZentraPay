import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/features/zbanking/repository/cache_zbankingData.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/core/utils/tab_switch_notifier.dart';
import 'package:zentrapay_application/features/zbanking/widgets/link_bank_sheet.dart';
import 'package:zentrapay_application/features/zbanking/widgets/other_bank_accounts_strip.dart';
import 'package:zentrapay_application/main.dart';

class ZBankingScreen extends StatefulWidget {
  const ZBankingScreen({super.key});

  @override
  State<ZBankingScreen> createState() => _ZBankingScreenState();
}

class _ZBankingScreenState extends State<ZBankingScreen> {
  bool _balanceHidden = false;

  // Used only by the savings-create sheet until a dedicated savings
  // repository exists; the token/interceptor config lives in ApiClient.
  final Dio _dio = ApiClient().dio;

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
    // Full width by design: the header and the white sheet below it both run
    // edge-to-edge (no tablet cap) so the sheet reads as one continuous panel.
    return ListenableBuilder(
      listenable: BankAccountsRepository.instance,
      builder: (context, _) {
        final repo = BankAccountsRepository.instance;
        final snapshot = repo.data ?? BankAccountsSnapshot.empty;
        final primary = snapshot.primary;
        // The primary already has its own card in the header, so the
        // bottom strip renders only the remaining accounts.
        final others = snapshot.others;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, primary)),
            SliverToBoxAdapter(
              child: const SizedBox(height: AppTheme.spacingMd),
            ),
            // Fills whatever vertical space is left in the viewport and only
            // starts scrolling once its content genuinely needs more room —
            // so the white sheet always reaches the bottom of the screen.
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.gray50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppTheme.spacingMd,
                    children: [
                      // Header shows the empty-state card until a primary
                      // exists, so the strip only makes sense alongside one.
                      if (primary != null) ...[
                        OtherBankAccountsStrip(accounts: others),
                        const SizedBox(height: AppTheme.spacingLg),
                      ],
                      _buildAccountOptionsSection(context),
                      const SizedBox(height: AppTheme.spacingLg),
                      _buildAiInsights(context),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context, BankAccounts? primaryAccount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: primaryAccount == null
          ? _emptyAccount()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------------------------------------------- title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Primary account',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppColors.primary.withAlpha(185),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            primaryAccount.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.headlineSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    // A labelled pill reads far better than a bare "+" now the
                    // screen can hold several banks and linking is a real flow.
                    _headerActionPill(
                      label: 'Link bank',
                      onTap: () => showLinkBankSheet(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),
                // -------------------------------------------- account / balance
                // One glass card groups the account face and the balance so the
                // header reads as a single object instead of loose text blocks.
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(16),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(38),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Account number',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppColors.primary.withAlpha(165),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  primaryAccount.maskedNumber,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.bodyLarge.copyWith(
                                    color: AppColors.primary,
                                    letterSpacing: 1.6,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingXs),
                          _statusChip(primaryAccount.connectionStatus),
                        ],
                      ),
                      Divider(
                        color: AppColors.primary.withAlpha(35),
                        height: AppTheme.spacingLg,
                        thickness: 1,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total balance',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppColors.primary.withAlpha(165),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _balanceAmount(),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                          _visibilityToggle(),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
              ],
            ),
    );
  }

  // Labelled pill for the header's call to action. Filled with secondaryNavy so
  // every primary action in the app reads the same way.
  Widget _headerActionPill({
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.secondaryNavy,
      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 16, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTheme.labelLarge.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "active" / "pending" marker next to the account number.
  Widget _statusChip(String status) {
    final isActive = status.toLowerCase() != 'inactive';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.primary : AppTheme.warningOrange)
            .withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.primary : AppTheme.warningOrange,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: AppTheme.bodySmall.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  /// Total balance, or the mask placeholder when the eye is toggled off.
  ///
  /// Wrapped in a `ListenableBuilder` so the figure appears the moment the
  /// repository resolves — the header is built once by `build()` and would
  /// otherwise keep showing the pre-load placeholder.
  Widget _balanceAmount() {
    if (_balanceHidden) {
      return Text(
        'GHS ••••••',
        style: AppTheme.headlineSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );
    }
    return ListenableBuilder(
      listenable: BankAccountsRepository.instance,
      builder: (context, _) {
        final data = BankAccountsRepository.instance.data;
        if (data == null) {
          return Text(
            'GHS --',
            style: AppTheme.headlineSmall.copyWith(
              color: AppColors.primary.withAlpha(150),
              fontWeight: FontWeight.w700,
            ),
          );
        }
        final currency = data.accounts.isNotEmpty
            ? data.accounts.first.currencyCode
            : 'GHS';
        return Text(
          formatMoney(data.totalBalance.toStringAsFixed(2), symbol: '$currency '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.headlineSmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        );
      },
    );
  }

  /// Eye / eye-off button that flips `_balanceHidden`.
  Widget _visibilityToggle() {
    return GestureDetector(
      onTap: () => setState(() => _balanceHidden = !_balanceHidden),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(24),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: Icon(
          _balanceHidden ? Icons.visibility : Icons.visibility_off,
          size: 18,
          color: AppColors.primary,
        ),
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
                        "No bank linked yet.",
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.primaryWhite,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      // Empty state is the natural place to start the flow.
                      GestureDetector(
                        onTap: () => showLinkBankSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMd,
                            vertical: 6.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Link a bank",
                                style: AppTheme.whiteBodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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
  // ACCOUNT OPTIONS (Micro-loan / Financial goals / Conversion / ...)
  // ============================================================
  // Icon-above-label shortcuts laid out in a Wrap: the row never scrolls
  // sideways, it simply flows onto a second line when the tiles no longer
  // fit, so every option stays reachable on the narrowest phone without a
  // horizontally clipped last tile.

  Widget _buildAccountOptionsSection(BuildContext context) {
    List<Map<String, dynamic>> goals = [
      {
        "title": "testing",
        "description": "hellow there, testing goals",
        "progress": "80%",
      },
    ];
    // Icon-above-label shortcuts laid out in a Wrap: the row never scrolls
    // sideways, it simply flows onto a second line when the tiles no longer
    // fit — so every option stays reachable on the narrowest phone without a
    // horizontally clipped last tile.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Quick actions", style: AppTheme.bodyMedium),
        const SizedBox(height: AppTheme.spacingMd),
        Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: AppTheme.spacingSm,
          alignment: WrapAlignment.start,
          children: [
            // Jumps back to the Home tab — a "back to the dashboard" shortcut
            // from deep inside ZBank. TabSwitchNotifier is the app-level
            // signal ResponsiveNavigation listens to, since a screen this deep
            // can't reach the shell's local _selectedIndex.
            _quickAction(
              icon: Icons.home_outlined,
              label: "Home",
              onTap: () => TabSwitchNotifier.instance.select(AppTab.home),
            ),
            _quickAction(
              icon: Icons.payments_outlined,
              label: "Micro-loan",
              onTap: () => _showLoanApplyDialog(context),
            ),
            _quickAction(
              icon: Icons.track_changes_outlined,
              label: "Financial goals",
              onTap: () => _showCreateSavingsDialog(context, goals),
            ),
            _quickAction(
              icon: Icons.currency_exchange_outlined,
              label: "Conversion",
              onTap: () => Navigator.pushNamed(context, "/converter"),
            ),
            _quickAction(
              icon: Icons.account_balance_outlined,
              label: "Open Banking",
              onTap: () => showComingSoon(context, "Open Banking"),
            ),
            _quickAction(
              icon: Icons.hub_outlined,
              label: "Liquidity",
              onTap: () => showComingSoon(context, "Global liquidity"),
            ),
          ],
        ),
      ],
    );
  }

  /// Compact square shortcut: icon on top, label underneath, no description and
  /// no chevron. Fixed width so every tile is identical and the `Wrap` above
  /// packs them into even columns.
  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Container(
        width: 82,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: AppTheme.secondaryNavy.withAlpha(10),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.secondaryNavy.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.secondaryNavy, size: 22),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textBlack,
                height: 1.2,
              ),
            ),
          ],
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
                    top: Radius.circular(30),
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
                          // No dedicated savings repository exists yet, so call
                          // the documented endpoint directly
                          // (POST /api/zbanking/savings/create).
                          await _dio.post(
                            '/api/zbanking/savings/create',
                            data: {
                              'savingsName': name,
                              'currencyCode': 'GHS',
                              'targetAmount': target.isEmpty ? null : target,
                              'initialDeposit': deposit,
                            },
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
                    top: Radius.circular(30),
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
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
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

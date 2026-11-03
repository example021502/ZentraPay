import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/afrilink_bank_connect_screen/AfriLinkBankConnectScreen.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/features/zbanking/repository/cache_zbanking_data.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/theme/section_header.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/payments/milestones_screen.dart';
import 'package:zentrapay_application/features/zbanking/pay_loans_screen.dart';
import 'package:zentrapay_application/features/zbanking/widgets/other_bank_accounts_strip.dart';
import 'package:zentrapay_application/features/wallet_topup/saved_cards_screen.dart';
import 'package:zentrapay_application/features/wallet_topup/topup_screen.dart';
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
    BankingInsightsRepository.instance.ensureLoaded();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BankAccountsRepository.instance,
      builder: (context, _) {
        final repo = BankAccountsRepository.instance;
        final snapshot = repo.data ?? BankAccountsSnapshot.empty;
        final primary = snapshot.primary;
        // The primary already has its own card in the header, so the
        // bottom strip renders only the remaining accounts.
        final others = snapshot.others;

        return SectionScrollView(
          header: SectionHeader(
            title: 'ZBank',
            subtitle: primary == null
                ? 'Link your bank to manage it here'
                : primary.displayName,
            icon: Icons.account_balance_rounded,
            sheetColor: AppTheme.gray50,
            actions: [
              if (primary != null)
                _headerActionPill(
                  label: 'Link bank',
                  onTap: () => linkBankWithAfriLink(context),
                ),
            ],
            child: _buildHeaderCard(primary),
          ),
          sheet: SectionSheet(
            color: AppTheme.gray50,
            topPadding: AppTheme.spacingMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  /// Primary account card (or the empty state) shown inside the shared
  /// [SectionHeader], like the ZRemit rate card.
  Widget _buildHeaderCard(BankAccounts? primaryAccount) {
    return primaryAccount == null
        ? _emptyAccount()
        : _accountCard(primaryAccount);
  }

  /// The primary account as a single card: bank + masked number + status on
  /// top, the balance (with its eye toggle) underneath.
  Widget _accountCard(BankAccounts account) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(AppTheme.isDark ? 70 : 28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.brand.withAlpha(AppTheme.isDark ? 60 : 24),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_outlined,
                  size: 20,
                  color: AppTheme.textBlack,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.bankName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.labelLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.maskedNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.gray500,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingXs),
              _statusChip(account.connectionStatus),
            ],
          ),
          Divider(color: AppTheme.dividerColor, height: AppTheme.spacingLg),
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
                        color: AppTheme.gray500,
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
    );
  }

  // Labelled pill for the header's call to action. White on the pink header so
  // it reads as the one action of the screen header.
  Widget _headerActionPill({
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.primary.withAlpha(36),
      shape: StadiumBorder(
        side: BorderSide(color: AppColors.primary.withAlpha(90)),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16, color: AppTheme.primaryWhite),
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
    final tone = isActive ? AppTheme.successGreen : AppTheme.warningOrange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withAlpha(32),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: tone),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: AppTheme.bodySmall.copyWith(
              color: tone,
              fontWeight: FontWeight.w600,
            ),
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
    final style = AppTheme.headlineMedium.copyWith(fontWeight: FontWeight.w700);
    if (_balanceHidden) {
      return Text('GHS ••••••', style: style.copyWith(letterSpacing: 1.2));
    }
    return ListenableBuilder(
      listenable: BankAccountsRepository.instance,
      builder: (context, _) {
        final data = BankAccountsRepository.instance.data;
        if (data == null) {
          return Text('GHS --', style: style.copyWith(color: AppTheme.gray500));
        }
        final currency = data.accounts.isNotEmpty
            ? data.accounts.first.currencyCode
            : 'GHS';
        return Text(
          formatMoney(
            data.totalBalance.toStringAsFixed(2),
            symbol: '$currency ',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
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
          color: AppTheme.brand.withAlpha(AppTheme.isDark ? 60 : 20),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _balanceHidden ? Icons.visibility : Icons.visibility_off,
          size: 18,
          color: AppTheme.textBlack,
        ),
      ),
    );
  }

  /// Empty state, in the same card layout as the ZRemit rate card: one flat
  /// glass card (no stacked layers) with the message and the link-bank action
  /// centred.
  Widget _emptyAccount() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.glassSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_outlined,
            color: AppTheme.primaryWhite,
            size: 30,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'No bank linked yet',
            textAlign: TextAlign.center,
            style: AppTheme.whiteHeadline.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            'Link a bank account to see your balance here.',
            textAlign: TextAlign.center,
            style: AppTheme.whiteBodySmall.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Center(
            child: _headerActionPill(
              label: 'Link a bank',
              onTap: () => linkBankWithAfriLink(context),
            ),
          ),
        ],
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
    // Every row opens its own section. Open Banking and Liquidity have no
    // backing service yet, so they say so with a light notice instead of
    // opening an empty page.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Banking services", style: AppTheme.bodyMedium),
        const SizedBox(height: AppTheme.spacingSm),
        Container(
          width: double.infinity,
          decoration: AppTheme.cardDecoration,
          child: Column(
            children: [
              _optionRow(
                icon: Icons.payments_outlined,
                title: "Micro-loan",
                subtitle: "Apply for a loan or repay one",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PayLoansScreen()),
                ),
              ),
              _optionDivider(),
              _optionRow(
                icon: Icons.track_changes_outlined,
                title: "Financial goals",
                subtitle: "Save towards what matters",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MilestonesScreen()),
                ),
              ),
              _optionDivider(),
              _optionRow(
                icon: Icons.currency_exchange_outlined,
                title: "Currency conversion",
                subtitle: "Convert money at live rates",
                onTap: () => Navigator.pushNamed(context, "/converter"),
              ),
              _optionDivider(),
              _optionRow(
                icon: Icons.add_circle_outlined,
                title: "Top Up Wallet",
                subtitle: "Add money from your linked bank",
                onTap: () => showTopupSheet(context),
              ),
              _optionDivider(),
              _optionRow(
                icon: Icons.credit_card_rounded,
                title: "Saved cards",
                subtitle: "Top up with a card you already used",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedCardsScreen()),
                ),
              ),
              _optionDivider(),
              _optionRow(
                icon: Icons.account_balance_outlined,
                title: "Open Banking",
                subtitle: "Connect your other accounts",
                onTap: _serviceUnavailable,
              ),
              _optionDivider(),
              _optionRow(
                icon: Icons.hub_outlined,
                title: "Liquidity",
                subtitle: "Move money across borders",
                onTap: _serviceUnavailable,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _serviceUnavailable() {
    ZentraNotifier.notice(
      "This service isn't available right now. We'll let you know when it is.",
      icon: Icons.schedule_rounded,
    );
  }

  Widget _optionDivider() =>
      Divider(height: 1, indent: 70, color: AppTheme.dividerColor);

  /// One service row: icon chip, title + one-line description, chevron.
  Widget _optionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.brand.withAlpha(AppTheme.isDark ? 60 : 22),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.textBlack, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textBlack),
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
        Text("AI Insights", style: AppTheme.bodyMedium),
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
}

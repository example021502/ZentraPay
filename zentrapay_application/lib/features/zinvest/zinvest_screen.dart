import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/models/zinvest.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/features/wallet_topup/topup_screen.dart';
import 'package:zentrapay_application/features/zinvest/repository/cache_zinvest_data.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/features/payments/widgets/investment_list.dart';
import 'package:zentrapay_application/main.dart';

import '../../core/theme/app_theme.dart';

// Investment types the server accepts today (crypto is not available yet, so it is not offered).
const Map<String, String> _investmentTypeLabels = {
  'STOCK': 'Stock',
  'ETF': 'ETF',
  'COMMODITY': 'Commodity',
  'OTHER': 'Other',
};

// Money of one currency held in positions: what it cost and what it is worth now.
class _CurrencyTotals {
  double cost = 0;
  double value = 0;
  double get gainPercent => cost <= 0 ? 0 : (value - cost) / cost * 100;
}

// Active positions grouped by currency (different currencies are never added together).
Map<String, _CurrencyTotals> _totalsByCurrency(List<Investment> investments) {
  final totals = <String, _CurrencyTotals>{};
  for (final i in investments) {
    if (i.status.toUpperCase() != 'ACTIVE') continue;
    final quantity = i.quantity.toAmount();
    final t = totals.putIfAbsent(i.currencyCode, () => _CurrencyTotals());
    t.cost += quantity * i.buyPrice.toAmount();
    t.value += quantity * i.currentPrice.toAmount();
  }
  return totals;
}

/// ZInvest Screen - Micro-investments (stocks, crypto, commodities)
/// and AI-guided portfolios. Reached from ZGrow, not the bottom nav.
class ZInvestScreen extends StatefulWidget {
  const ZInvestScreen({super.key});

  @override
  State<ZInvestScreen> createState() => _ZInvestScreenState();
}

class _ZInvestScreenState extends State<ZInvestScreen> {
  final GlobalKey _investmentsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Ensure repository data is fetched on screen initialization. The
    // repository keeps its error for the UI, so the rethrow is swallowed here.
    InvestmentsRepository.instance.ensureLoaded().catchError((_) => null);
    // The form offers the currencies of the user's wallet accounts.
    WalletsRepository.instance.ensureLoaded().catchError((_) => null);
  }

  // Opens the bottom sheet form to create a new investment
  void _openInvestSheet({String? type}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _InvestForm(initialType: type),
    );
  }

  // Brings the "Your Investments" list (with its Sell buttons) into view
  void _scrollToInvestments() {
    final target = _investmentsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  // Allocation by type and profit/loss per currency, from the real portfolio
  void _openAnalyticsSheet() {
    final investments = (InvestmentsRepository.instance.data ?? const <Investment>[])
        .where((i) => i.status.toUpperCase() == 'ACTIVE')
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AnalyticsSheet(investments: investments),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppTheme.responsivePadding(context);

    return Scaffold(
      // Fixed appBar syntax error by wrapping the custom top bar inside PreferredSize
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 8,
            ),
            child: _buildTopBar(context),
          ),
        ),
      ),
      body: Container(
        color: AppTheme.gray50,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppTheme.spacingMd,
                horizontalPadding,
                AppTheme.responsiveBottomPadding(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: AppTheme.spacingXl),
                  _buildPortfolioCard(),
                  const SizedBox(height: AppTheme.spacingXl),
                  const SectionTitle(title: "Quick Actions"),
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildQuickActions(context),
                  const SizedBox(height: AppTheme.spacingXl),
                  KeyedSubtree(
                    key: _investmentsKey,
                    child: SectionTitle(
                      title: "Your Investments",
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppTheme.zinvestColor,
                        onPressed: () => _openInvestSheet(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildInvestmentsSection(),
                  const SizedBox(height: AppTheme.spacingXl),
                  const SectionTitle(title: "Market & AI Portfolios"),
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildInvestmentFeatures(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Builds the top navigation bar with a custom back button and screen title
  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        InkResponse(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.arrow_back, size: 24, color: AppTheme.textBlack),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Text("ZInvest", style: AppTheme.headlineSmall),
      ],
    );
  }

  // Hero card with a gradient background and promotional text overlay
  Widget _buildHeroCard() {
    return Container(
      decoration: AppTheme.coloredCardDecoration(
        AppTheme.brand,
      ).copyWith(gradient: AppTheme.secondaryGradient),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  Icons.currency_bitcoin_outlined,
                  size: 90,
                  color: AppTheme.textBlack,
                ),
                Icon(
                  Icons.diamond_outlined,
                  size: 90,
                  color: AppTheme.textBlack,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            // Bottom gradient fade to ensure high text legibility
            Text("Grow your wealth", style: AppTheme.whiteHeadline),
            const SizedBox(height: 4),
            Text(
              "Micro-invest in stocks and commodities from your wallet — start small, grow steadily.",
              style: AppTheme.whiteBodySmall,
            ),
          ],
        ),
      ),
    );
  }

  // Portfolio summary card: what the active positions are worth now, per currency
  // (worked out from the real portfolio, so it always matches the list below).
  Widget _buildPortfolioCard() {
    return ListenableBuilder(
      listenable: InvestmentsRepository.instance,
      builder: (context, _) {
        final repo = InvestmentsRepository.instance;
        final investments = repo.data;
        final totals = investments == null
            ? const <String, _CurrencyTotals>{}
            : _totalsByCurrency(investments);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            boxShadow: AppTheme.elevatedShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Portfolio Value",
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (repo.isLoading && investments == null)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              if (repo.error != null && investments == null)
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Couldn't load portfolio value.",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () => repo
                          .ensureLoaded(forceRefresh: true)
                          .catchError((_) => null),
                      child: const Text(
                        "Retry",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                )
              else if (investments == null)
                const Text(
                  "—",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (totals.isEmpty)
                const Text(
                  "Nothing invested yet",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                for (final entry in totals.entries) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          formatMoney(
                            entry.value.value.toStringAsFixed(2),
                            symbol: "${entry.key} ",
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      _gainChip(entry.value.gainPercent),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
            ],
          ),
        );
      },
    );
  }

  // ▲ / ▼ percentage pill used on the portfolio card
  Widget _gainChip(double percent) {
    final up = percent >= 0;
    final tone = up ? Colors.greenAccent : AppTheme.warningOrange;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: tone.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: tone,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            "${percent.abs().toStringAsFixed(1)}%",
            style: TextStyle(
              color: tone,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Quick actions toolbar for primary account functions
  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: AppTheme.cardDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Investments are bought from the wallet, so "Add money" is a wallet top-up
          _buildActionTile(
            context,
            Icons.add_rounded,
            "Add money",
            () => showTopupSheet(context),
          ),
          _buildActionTile(
            context,
            Icons.swap_horiz_rounded,
            "Invest",
            () => _openInvestSheet(),
          ),
          _buildActionTile(
            context,
            Icons.arrow_downward_rounded,
            "Sell",
            _scrollToInvestments,
          ),
          _buildActionTile(
            context,
            Icons.bar_chart_rounded,
            "Analytics",
            _openAnalyticsSheet,
          ),
        ],
      ),
    );
  }

  // Reusable action tile builder component
  Widget _buildActionTile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.main.withAlpha(15),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Icon(icon, color: AppTheme.textBlack, size: 24),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Dynamic investments list view container
  Widget _buildInvestmentsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: AppTheme.cardDecoration,
      child: ListenableBuilder(
        listenable: InvestmentsRepository.instance,
        builder: (context, _) {
          final repo = InvestmentsRepository.instance;
          final investments = repo.data;

          if (repo.isLoading && investments == null) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (repo.error != null && investments == null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  const Text(
                    "Couldn't load your investments.",
                    style: TextStyle(color: Colors.black54),
                  ),
                  TextButton(
                    onPressed: () => repo.ensureLoaded(forceRefresh: true),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          if (investments == null || investments.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.show_chart,
              message: "No investments yet.",
              actionLabel: "Buy your first investment",
              onAction: _openInvestSheet,
            );
          }

          return InvestmentList(
            investments: investments,
            onSell: (id) => InvestmentsRepository.instance.sell(id),
          );
        },
      ),
    );
  }

  // Market categories and features section listing
  Widget _buildInvestmentFeatures(BuildContext context) {
    final features = [
      {
        'icon': Icons.show_chart,
        'title': "Stocks",
        'subtitle': "Invest in local & global stocks",
        'onTap': () => _openInvestSheet(type: 'STOCK'),
      },
      {
        'icon': Icons.diamond_outlined,
        'title': "Commodities",
        'subtitle': "Gold, silver & other commodities",
        'onTap': () => _openInvestSheet(type: 'COMMODITY'),
      },
      {
        'icon': Icons.smart_toy_rounded,
        'title': "AI-Guided Portfolios",
        'subtitle': "Let AI optimize your investments",
        'onTap': () => Navigator.pushNamed(context, '/ai_assistance'),
      },
    ];

    return Column(
      children: features.map((feature) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          decoration: AppTheme.cardDecoration,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              onTap: feature['onTap'] as VoidCallback,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.purple.withAlpha(15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: AppTheme.textBlack,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature['title'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            feature['subtitle'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppTheme.textBlack,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Bottom sheet form that buys a position. The cost (quantity x buy price) is taken
/// from the wallet account in the chosen currency, so only currencies the user has
/// an account in are offered.
class _InvestForm extends StatefulWidget {
  const _InvestForm({this.initialType});

  final String? initialType;

  @override
  State<_InvestForm> createState() => _InvestFormState();
}

class _InvestFormState extends State<_InvestForm> {
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _buyPriceController = TextEditingController();

  late String _investmentType;
  String? _currencyCode;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _investmentType = _investmentTypeLabels.containsKey(widget.initialType)
        ? widget.initialType!
        : _investmentTypeLabels.keys.first;
    // The cost preview follows the typing
    _quantityController.addListener(_refresh);
    _buyPriceController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _quantityController.dispose();
    _buyPriceController.dispose();
    super.dispose();
  }

  // Currencies of the user's wallet accounts (the money has to come from one of them)
  List<String> get _currencies {
    final accounts = WalletsRepository.instance.data?.fiatAccounts ?? const [];
    final codes = <String>[];
    for (final a in accounts) {
      if (a.currencyCode.isNotEmpty && !codes.contains(a.currencyCode)) {
        codes.add(a.currencyCode);
      }
    }
    return codes;
  }

  double? get _cost {
    final q = double.tryParse(_quantityController.text.trim());
    final p = double.tryParse(_buyPriceController.text.trim());
    if (q == null || p == null || q <= 0 || p <= 0) return null;
    return q * p;
  }

  // Validates inputs and triggers the purchase through the repository
  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final quantity = _quantityController.text.trim();
    final buyPrice = _buyPriceController.text.trim();
    final currency = _currencyCode ?? (_currencies.isNotEmpty ? _currencies.first : null);

    if (name.isEmpty || _cost == null) {
      setState(() => _error = "Enter a name, a valid quantity and a buy price.");
      return;
    }
    if (currency == null) {
      setState(() => _error = "You need a wallet account to invest from. Create one first.");
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await InvestmentsRepository.instance.invest(
        name: name,
        investmentType: _investmentType,
        symbol: _symbolController.text.trim().isEmpty
            ? null
            : _symbolController.text.trim(),
        quantity: quantity,
        buyPrice: buyPrice,
        currencyCode: currency,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencies = _currencies;
    final currency = _currencyCode ?? (currencies.isNotEmpty ? currencies.first : null);
    final cost = _cost;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Buy Investment", style: AppTheme.headlineLarge),
              const SizedBox(height: 4),
              Text(
                "The cost is taken from your wallet. Selling puts it back.",
                style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              AppTextField(controller: _nameController, labelText: "Name"),
              const SizedBox(height: AppTheme.spacingMd),
              DropdownButtonFormField<String>(
                initialValue: _investmentType,
                decoration: const InputDecoration(labelText: "Investment type"),
                items: _investmentTypeLabels.entries
                    .map(
                      (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _investmentType = value);
                },
              ),
              const SizedBox(height: AppTheme.spacingMd),
              AppTextField(
                controller: _symbolController,
                labelText: "Symbol (optional)",
              ),
              const SizedBox(height: AppTheme.spacingMd),
              AppTextField(
                controller: _quantityController,
                labelText: "Quantity",
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              AppTextField(
                controller: _buyPriceController,
                labelText: "Buy price",
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              if (currencies.isEmpty)
                Text(
                  "No wallet account found yet. Create one from the home screen to invest.",
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.warningOrange),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: currency,
                  decoration: const InputDecoration(labelText: "Pay from (currency)"),
                  items: currencies
                      .map(
                        (code) =>
                            DropdownMenuItem(value: code, child: Text(code)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _currencyCode = value);
                  },
                ),
              if (cost != null && currency != null) ...[
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  "Total cost: ${formatMoney(cost.toStringAsFixed(2), symbol: '$currency ')}",
                  style: AppTheme.labelLarge,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppTheme.errorRed,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacingLg),
              PrimaryButton(
                label: "Invest",
                loading: _submitting,
                onPressed: currencies.isEmpty ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Allocation by type and profit/loss per currency for the active positions.
class _AnalyticsSheet extends StatelessWidget {
  const _AnalyticsSheet({required this.investments});

  final List<Investment> investments;

  @override
  Widget build(BuildContext context) {
    final totals = _totalsByCurrency(investments);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Analytics", style: AppTheme.headlineLarge),
              const SizedBox(height: AppTheme.spacingMd),
              if (investments.isEmpty)
                Text(
                  "Buy your first investment to see how your money is spread.",
                  style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
                )
              else ...[
                Text("Profit / loss", style: AppTheme.labelLarge),
                const SizedBox(height: AppTheme.spacingSm),
                for (final entry in totals.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${entry.key}: ${formatMoney(entry.value.cost.toStringAsFixed(2))} invested",
                            style: AppTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          "${entry.value.gainPercent >= 0 ? '+' : ''}"
                          "${entry.value.gainPercent.toStringAsFixed(1)}%",
                          style: AppTheme.labelLarge.copyWith(
                            color: entry.value.gainPercent >= 0
                                ? AppTheme.successGreen
                                : AppTheme.errorRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppTheme.spacingMd),
                Text("Where your money is", style: AppTheme.labelLarge),
                const SizedBox(height: AppTheme.spacingSm),
                ..._allocationRows(),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  "Prices are the ones recorded for each position. Live market prices are not connected yet, so a position is valued at its recorded price.",
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // One bar per investment type, as a share of the money in each currency
  List<Widget> _allocationRows() {
    final rows = <Widget>[];
    final currencies = investments.map((i) => i.currencyCode).toSet();
    for (final currency in currencies) {
      final inCurrency = investments.where((i) => i.currencyCode == currency).toList();
      final byType = <String, double>{};
      var total = 0.0;
      for (final i in inCurrency) {
        final value = i.quantity.toAmount() * i.currentPrice.toAmount();
        byType[i.investmentType] = (byType[i.investmentType] ?? 0) + value;
        total += value;
      }
      if (total <= 0) continue;
      if (currencies.length > 1) {
        rows.add(Text(currency, style: AppTheme.bodySmall));
      }
      for (final e in byType.entries) {
        final share = e.value / total;
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _investmentTypeLabels[e.key] ?? e.key,
                        style: AppTheme.bodyMedium,
                      ),
                    ),
                    Text("${(share * 100).toStringAsFixed(0)}%", style: AppTheme.labelLarge),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  child: LinearProgressIndicator(
                    value: share,
                    minHeight: 8,
                    backgroundColor: AppTheme.gray300,
                    color: AppTheme.zinvestColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return rows;
  }
}

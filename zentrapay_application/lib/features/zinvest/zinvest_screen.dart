import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/features/zinvest/repository/cache_zinvestData.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/features/payments/widgets/investment_list.dart';
import 'package:zentrapay_application/main.dart';

import '../../core/theme/app_theme.dart';

// Constants defining available investment types and currency choices
const List<String> _investmentTypes = ['STOCK', 'CRYPTO', 'COMMODITY', 'OTHER'];
const List<String> _currencyCodes = ['GHS', 'USD', 'KES'];

/// ZInvest Screen - Micro-investments (stocks, crypto, commodities)
/// and AI-guided portfolios. Reached from ZGrow, not the bottom nav.
class ZInvestScreen extends StatefulWidget {
  const ZInvestScreen({super.key});

  @override
  State<ZInvestScreen> createState() => _ZInvestScreenState();
}

class _ZInvestScreenState extends State<ZInvestScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure repository data is fetched on screen initialization
    InvestmentsRepository.instance.ensureLoaded();
    LiquidityProfileRepository.instance.ensureLoaded();
  }

  // Opens the bottom sheet form to create a new investment
  void _openInvestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _InvestForm(),
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
                  SectionTitle(
                    title: "Your Investments",
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppTheme.zinvestColor,
                      onPressed: _openInvestSheet,
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
        Material(
          color: AppColors.primary,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, size: 22),
            ),
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
        AppColors.secondary,
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
                  color: Colors.white.withAlpha(60),
                ),
                Icon(
                  Icons.diamond_outlined,
                  size: 90,
                  color: Colors.white.withAlpha(60),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            // Bottom gradient fade to ensure high text legibility
            Text("Grow your wealth", style: AppTheme.whiteHeadline),
            const SizedBox(height: 4),
            Text(
              "Micro-invest in stocks, crypto and commodities — start small, grow steadily.",
              style: AppTheme.whiteBodySmall,
            ),
          ],
        ),
      ),
    );
  }

  // Portfolio summary card displaying total valuation and risk parameters
  Widget _buildPortfolioCard() {
    return ListenableBuilder(
      listenable: LiquidityProfileRepository.instance,
      builder: (context, _) {
        final repo = LiquidityProfileRepository.instance;
        final profile = repo.data;

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
                  if (repo.isLoading && profile == null)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    )
                  else
                    const Icon(
                      Icons.visibility_outlined,
                      color: Colors.white70,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              if (repo.error != null && profile == null)
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Couldn't load portfolio value.",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () => repo.ensureLoaded(forceRefresh: true),
                      child: const Text(
                        "Retry",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  profile == null
                      ? "—"
                      : formatMoney(profile.totalValue, symbol: "GHS "),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              const SizedBox(height: AppTheme.spacingLg),
              if (profile != null)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSm,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (profile.totalGainLossPercent.toAmount() >= 0
                                    ? Colors.greenAccent
                                    : AppTheme.warningOrange)
                                .withAlpha(30),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            profile.totalGainLossPercent.toAmount() >= 0
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            color: profile.totalGainLossPercent.toAmount() >= 0
                                ? Colors.greenAccent
                                : AppTheme.warningOrange,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${profile.totalGainLossPercent.toAmount().toStringAsFixed(1)}%",
                            style: TextStyle(
                              color:
                                  profile.totalGainLossPercent.toAmount() >= 0
                                  ? Colors.greenAccent
                                  : AppTheme.warningOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      "Risk profile: ${profile.riskProfile}",
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
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
          _buildActionTile(
            context,
            Icons.add_rounded,
            "Deposit",
            () => showComingSoon(context, "Deposit"),
          ),
          _buildActionTile(
            context,
            Icons.arrow_downward_rounded,
            "Withdraw",
            () => showComingSoon(context, "Withdraw"),
          ),
          _buildActionTile(
            context,
            Icons.swap_horiz_rounded,
            "Trade",
            _openInvestSheet,
          ),
          _buildActionTile(
            context,
            Icons.bar_chart_rounded,
            "Analytics",
            () => showComingSoon(context, "Analytics"),
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
            child: Icon(icon, color: AppColors.main, size: 24),
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
        'onTap': () => showComingSoon(context, "Stocks"),
      },
      {
        'icon': Icons.currency_bitcoin,
        'title': "Crypto",
        'subtitle': "Coming soon — Trade Bitcoin, Ethereum & more",
        'onTap': () => showComingSoon(context, "Crypto"),
      },
      {
        'icon': Icons.diamond_outlined,
        'title': "Commodities",
        'subtitle': "Gold, silver & other commodities",
        'onTap': () => showComingSoon(context, "Commodities"),
      },
      {
        'icon': Icons.smart_toy_rounded,
        'title': "AI-Guided Portfolios",
        'subtitle': "Let AI optimize your investments",
        'onTap': () => Navigator.pushNamed(context, '/ai_assistance'),
      },
      {
        'icon': Icons.auto_awesome,
        'title': "Auto-Invest",
        'subtitle': "Set up recurring investments",
        'onTap': () => showComingSoon(context, "Auto-Invest"),
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
                        color: AppColors.purple,
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
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey,
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

/// Bottom sheet form widget used to collect user inputs for purchasing investments.
class _InvestForm extends StatefulWidget {
  const _InvestForm();

  @override
  State<_InvestForm> createState() => _InvestFormState();
}

class _InvestFormState extends State<_InvestForm> {
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _buyPriceController = TextEditingController();

  String _investmentType = _investmentTypes.first;
  String _currencyCode = _currencyCodes.first;
  bool _submitting = false;
  String? _error;

  bool get _isCrypto => _investmentType == 'CRYPTO';

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _quantityController.dispose();
    _buyPriceController.dispose();
    super.dispose();
  }

  // Validates inputs and triggers investment purchase through repository
  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final quantity = _quantityController.text.trim();
    final buyPrice = _buyPriceController.text.trim();

    if (name.isEmpty ||
        quantity.isEmpty ||
        buyPrice.isEmpty ||
        double.tryParse(quantity) == null ||
        double.tryParse(buyPrice) == null) {
      setState(() => _error = "Enter a name, valid quantity and buy price.");
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
        currencyCode: _currencyCode,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = "Couldn't complete purchase: $e");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Buy Investment", style: AppTheme.headlineLarge),
              const SizedBox(height: AppTheme.spacingLg),
              AppTextField(controller: _nameController, labelText: "Name"),
              const SizedBox(height: AppTheme.spacingMd),
              DropdownButtonFormField<String>(
                initialValue: _investmentType,
                decoration: const InputDecoration(labelText: "Investment type"),
                items: _investmentTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          type == 'CRYPTO' ? '$type (coming soon)' : type,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _investmentType = value);
                },
              ),
              if (_isCrypto) ...[
                const SizedBox(height: AppTheme.spacingSm),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppTheme.warningOrange,
                    ),
                    const SizedBox(width: AppTheme.spacingXs),
                    const Expanded(
                      child: Text(
                        "Crypto investing is coming soon and can't be submitted yet.",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.warningOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
              DropdownButtonFormField<String>(
                initialValue: _currencyCode,
                decoration: const InputDecoration(labelText: "Currency"),
                items: _currencyCodes
                    .map(
                      (code) =>
                          DropdownMenuItem(value: code, child: Text(code)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _currencyCode = value);
                },
              ),
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
                onPressed: _isCrypto ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

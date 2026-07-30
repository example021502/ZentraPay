import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';

import '../../core/theme/app_theme.dart';

// ZInvest Screen - Micro-investments (stocks, crypto, commodities)
// and AI-guided portfolios with a modernized, professional UI.
class ZInvestScreen extends StatelessWidget {
  const ZInvestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryWhite,
      body: CustomScrollView(
        slivers: [
          _buildModernHeader(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildPortfolioCard(),
                  const SizedBox(height: AppTheme.spacingXl),
                  _buildSectionHeader("Quick Actions"),
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildQuickActions(context),
                  const SizedBox(height: AppTheme.spacingXl),
                  _buildSectionHeader("Market & AI Portfolios"),
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildInvestmentFeatures(context),
                  const SizedBox(height: AppTheme.spacingXl * 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Modern Sliver App Bar Header
  Widget _buildModernHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.zinvestColor,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLg,
          vertical: AppTheme.spacingMd,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(
                Icons.trending_up,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            const Text(
              "ZInvest",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section Header with clean typography
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // Modernized Portfolio Card with subtle shadow and glassmorphic stats
  Widget _buildPortfolioCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppTheme.zinvestColor.withAlpha(50),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
              const Icon(
                Icons.visibility_outlined,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          const Text(
            "GHS 3,728.28",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withAlpha(30),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.greenAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "+35.6%",
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                "+GHS 978.42 All time",
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
  }

  // Refined Quick Actions Grid/Row
  Widget _buildQuickActions(BuildContext context) {
    return Row(
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
          () => showComingSoon(context, "Trade"),
        ),
        _buildActionTile(
          context,
          Icons.bar_chart_rounded,
          "Analytics",
          () => showComingSoon(context, "Analytics"),
        ),
      ],
    );
  }

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
              color: AppTheme.zinvestColor.withAlpha(15),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Icon(icon, color: AppTheme.zinvestColor, size: 24),
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

  // Modern List of Investment Features using Custom Cards
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
        'subtitle': "Trade Bitcoin, Ethereum & more",
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                        color: AppTheme.zinvestColor.withAlpha(15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: AppTheme.zinvestColor,
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

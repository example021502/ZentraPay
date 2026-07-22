import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';

/// ZInvest Screen - Micro-investments (stocks, crypto, commodities)
/// and AI-guided portfolios.
class ZInvestScreen extends StatelessWidget {
  const ZInvestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.zinvestColor,
      child: SingleChildScrollView(
        child: Column(
          children: [
            FeatureScreenHeader(
              title: "ZInvest",
              subtitle: "Micro-investments & AI-guided portfolios",
              backgroundColor: AppTheme.zinvestColor,
              icon: Icons.trending_up,
            ),
            FeatureScreenBody(
              children: [
                const SectionTitle(title: "Quick Actions"),
                const SizedBox(height: AppTheme.spacingMd),
                _buildQuickActions(context),
                const SizedBox(height: AppTheme.spacingXl),
                const SectionTitle(title: "Investment Features"),
                const SizedBox(height: AppTheme.spacingMd),
                ActionItemCard(
                  icon: Icons.show_chart,
                  title: "Stocks",
                  subtitle: "Invest in local & global stocks",
                  onTap: () => showComingSoon(context, "Stocks"),
                  iconColor: AppTheme.zinvestColor,
                ),
                ActionItemCard(
                  icon: Icons.currency_bitcoin,
                  title: "Crypto",
                  subtitle: "Trade Bitcoin, Ethereum & more",
                  onTap: () => showComingSoon(context, "Crypto"),
                  iconColor: AppTheme.zinvestColor,
                ),
                ActionItemCard(
                  icon: Icons.diamond_outlined,
                  title: "Commodities",
                  subtitle: "Gold, silver & other commodities",
                  onTap: () => showComingSoon(context, "Commodities"),
                  iconColor: AppTheme.zinvestColor,
                ),
                ActionItemCard(
                  icon: Icons.smart_toy,
                  title: "AI-Guided Portfolios",
                  subtitle: "Let AI optimize your investments",
                  onTap: () => Navigator.pushNamed(context, '/ai_assistance'),
                  iconColor: AppTheme.zinvestColor,
                ),
                ActionItemCard(
                  icon: Icons.auto_awesome,
                  title: "Auto-Invest",
                  subtitle: "Set up recurring investments",
                  onTap: () => showComingSoon(context, "Auto-Invest"),
                  iconColor: AppTheme.zinvestColor,
                ),
                const SizedBox(height: AppTheme.spacingXl),
                const SectionTitle(title: "Portfolio Overview"),
                const SizedBox(height: AppTheme.spacingMd),
                _buildPortfolioCard(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        QuickActionButton(
          icon: Icons.add,
          label: "Deposit",
          onTap: () => showComingSoon(context, "Deposit"),
          color: AppTheme.zinvestColor,
        ),
        QuickActionButton(
          icon: Icons.remove,
          label: "Withdraw",
          onTap: () => showComingSoon(context, "Withdraw"),
          color: AppTheme.zinvestColor,
        ),
        QuickActionButton(
          icon: Icons.swap_horiz,
          label: "Trade",
          onTap: () => showComingSoon(context, "Trade"),
          color: AppTheme.zinvestColor,
        ),
        QuickActionButton(
          icon: Icons.analytics,
          label: "Analytics",
          onTap: () => showComingSoon(context, "Analytics"),
          color: AppTheme.zinvestColor,
        ),
      ],
    );
  }

  Widget _buildPortfolioCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Total Portfolio Value", style: AppTheme.whiteBodySmall),
          const SizedBox(height: AppTheme.spacingSm),
          Text("GHS 3,728.28", style: AppTheme.whiteDisplayMedium),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: AppTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_upward,
                      color: Colors.greenAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "+35.6%",
                      style: AppTheme.whiteBodySmall.copyWith(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text("All time", style: AppTheme.whiteBodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

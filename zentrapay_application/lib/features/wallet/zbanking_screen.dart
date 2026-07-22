import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'zbanking_header.dart';
import 'linked_accounts_carousel.dart';
import 'zbanking_action_item.dart';

class ZBankingScreen extends StatelessWidget {
  const ZBankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final maxWidth = isTablet ? 800.0 : double.infinity;
    final horizontalPadding = isTablet ? 40.0 : 15.0;
    final bottomPadding = isTablet
        ? 40.0
        : MediaQuery.of(context).padding.bottom + 120;

    return Container(
      color: AppColors.main,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const ZBankingHeader(),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                width: maxWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: Text(
                        "Linked Bank Accounts Overview",
                        style: AppStyles.header,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const LinkedAccountsCarousel(),
                    _buildAIInsight(),

                    // Global Liquidity Hub - Main Feature
                    ZBankingActionItem(
                      icon: Icons.account_balance_wallet,
                      title: "ZentraPay Global Liquidity Hub",
                      subtitle: "Unified treasury & liquidity management",
                      onTap: () {
                        Navigator.pushNamed(context, '/liquidity_hub');
                      },
                    ),

                    // Settings & Security
                    ZBankingActionItem(
                      icon: Icons.settings_outlined,
                      title: "Settings & Security Hub",
                      subtitle: "All systems clear. Check your health.",
                      onTap: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),

                    // Smart Converter
                    ZBankingActionItem(
                      icon: Icons.currency_exchange,
                      title: "Smart Currency Converter",
                      subtitle: "Best rates guaranteed",
                      onTap: () {
                        Navigator.pushNamed(context, '/converter');
                      },
                    ),

                    // Milestones/Goals
                    ZBankingActionItem(
                      icon: Icons.track_changes_outlined,
                      title: "Your Financial Goals",
                      subtitle: "Invest savings into your future",
                      onTap: () {
                        Navigator.pushNamed(context, '/milestones');
                      },
                    ),

                    // AI Assistance
                    ZBankingActionItem(
                      icon: Icons.smart_toy_outlined,
                      title: "AI Financial Assistant",
                      subtitle: "Get intelligent insights",
                      onTap: () {
                        Navigator.pushNamed(context, '/ai_assistance');
                      },
                    ),

                    SizedBox(height: bottomPadding),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsight() => Container(
    margin: const EdgeInsets.all(15),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[300]!),
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Row(
      children: [
        Icon(Icons.lightbulb_outline, size: 20),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            "AI-insight: You are on track to save GHS 40 this week.",
            style: TextStyle(fontSize: 14),
          ),
        ),
        Icon(Icons.chevron_right, size: 20),
      ],
    ),
  );
}

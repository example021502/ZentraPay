import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'zgrow_header.dart';
import 'saving_challenges.dart';
import 'zgrow_quick_actions.dart';
import 'zgrow_rewards.dart';
import 'learn_and_earn.dart';
import 'financial_tools.dart';
import 'ai_couch.dart';

class ZGrowScreen extends StatelessWidget {
  const ZGrowScreen({super.key});

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
            const ZGrowHeader(),
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 20,
                ),
                width: maxWidth,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  spacing: 40,
                  children: [
                    const ZGrowQuickActions(),
                    const SavingChallenges(),
                    const ZGrowRewards(),
                    const LearnAndEarn(),
                    const FinancialTools(),
                    const AiCouch(),
                    _buildQuickLinks(context),
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

  Widget _buildQuickLinks(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Quick Links",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 15),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLinkButton(context, Icons.trending_up, "ZInvest", () {
            Navigator.pushNamed(context, '/zinvest');
          }),
          _buildLinkButton(context, Icons.flag, "Milestones", () {
            Navigator.pushNamed(context, '/milestones');
          }),
          _buildLinkButton(context, Icons.smart_toy, "AI Coach", () {
            Navigator.pushNamed(context, '/ai_assistance');
          }),
        ],
      ),
    ],
  );

  Widget _buildLinkButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.main.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.main, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  );
}

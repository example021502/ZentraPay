import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';

/// ZGrow Screen - Financial Wellness Hub with gamified savings challenges,
/// rewards for saving & paying on time, and finance literacy videos + AI coach.
class ZGrowScreen extends StatelessWidget {
  const ZGrowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.zgrowColor,
      child: SingleChildScrollView(
        child: Column(
          children: [
            FeatureScreenHeader(
              title: "ZGrow",
              subtitle: "Financial Wellness Hub",
              backgroundColor: AppTheme.zgrowColor,
              icon: Icons.emoji_events,
            ),
            FeatureScreenBody(
              children: [
                const SectionTitle(title: "Your Financial Health"),
                const SizedBox(height: AppTheme.spacingMd),
                _buildHealthScoreCard(),
                const SizedBox(height: AppTheme.spacingXl),
                const SectionTitle(title: "Wellness Features"),
                const SizedBox(height: AppTheme.spacingMd),
                ActionItemCard(
                  icon: Icons.emoji_events_outlined,
                  title: "Gamified Savings Challenges",
                  subtitle: "Fun challenges to boost your savings",
                  onTap: () => showComingSoon(context, "Savings Challenges"),
                  iconColor: AppTheme.zgrowColor,
                ),
                ActionItemCard(
                  icon: Icons.card_giftcard,
                  title: "Rewards & Cashback",
                  subtitle: "Earn rewards for saving & paying on time",
                  onTap: () => showComingSoon(context, "Rewards"),
                  iconColor: AppTheme.zgrowColor,
                ),
                ActionItemCard(
                  icon: Icons.school,
                  title: "Finance Literacy Videos",
                  subtitle: "Learn about money management",
                  onTap: () => showComingSoon(context, "Finance Videos"),
                  iconColor: AppTheme.zgrowColor,
                ),
                ActionItemCard(
                  icon: Icons.smart_toy,
                  title: "AI Financial Coach",
                  subtitle: "Personalized financial guidance",
                  onTap: () => Navigator.pushNamed(context, '/ai_assistance'),
                  iconColor: AppTheme.zgrowColor,
                ),
                ActionItemCard(
                  icon: Icons.flag,
                  title: "Milestones & Goals",
                  subtitle: "Track your financial milestones",
                  onTap: () => Navigator.pushNamed(context, '/milestones'),
                  iconColor: AppTheme.zgrowColor,
                ),
                const SizedBox(height: AppTheme.spacingXl),
                const SectionTitle(title: "Quick Links"),
                const SizedBox(height: AppTheme.spacingMd),
                _buildQuickLinks(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: AppTheme.successGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: 0.867,
                  strokeWidth: 15,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("86.7%", style: AppTheme.whiteDisplayMedium),
                  Text("Health Score", style: AppTheme.whiteBodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            "Your next Milestone unlocks in 3 days",
            style: AppTheme.whiteBody,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    return Row(
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
    );
  }

  Widget _buildLinkButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLg,
          vertical: AppTheme.spacingMd,
        ),
        decoration: BoxDecoration(
          color: AppTheme.zgrowColor.withAlpha(25),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.zgrowColor, size: 28),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

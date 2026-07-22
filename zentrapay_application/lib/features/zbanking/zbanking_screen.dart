import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';

/// ZBank Lite Screen - Digital savings & micro-loans, AI-powered financial
/// insights, auto-budgeting & tracking, and emergency vault.
class ZBankingScreen extends StatelessWidget {
  const ZBankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.secondary,
      child: SingleChildScrollView(
        child: Column(
          children: [
            FeatureScreenHeader(
              title: "ZBank Lite",
              subtitle: "Digital savings & micro-loans",
              backgroundColor: AppColors.secondary,
              icon: Icons.account_balance,
            ),
            FeatureScreenBody(
              children: [
                const SectionTitle(title: "Quick Actions"),
                const SizedBox(height: AppTheme.spacingMd),
                _buildQuickActions(context),
                const SizedBox(height: AppTheme.spacingXl),
                const SectionTitle(title: "Banking Features"),
                const SizedBox(height: AppTheme.spacingMd),
                ActionItemCard(
                  icon: Icons.savings,
                  title: "Digital Savings",
                  subtitle: "Save securely with competitive rates",
                  onTap: () => showComingSoon(context, "Digital Savings"),
                  iconColor: AppColors.secondary,
                ),
                ActionItemCard(
                  icon: Icons.handshake,
                  title: "Micro-Loans",
                  subtitle: "Quick access to small loans",
                  onTap: () => showComingSoon(context, "Micro-Loans"),
                  iconColor: AppColors.secondary,
                ),
                ActionItemCard(
                  icon: Icons.auto_graph,
                  title: "Auto-Budgeting & Tracking",
                  subtitle: "AI-powered expense tracking",
                  onTap: () => showComingSoon(context, "Auto-Budgeting"),
                  iconColor: AppColors.secondary,
                ),
                ActionItemCard(
                  icon: Icons.lock_outline,
                  title: "Emergency Vault",
                  subtitle: "Secure savings for emergencies",
                  onTap: () => showComingSoon(context, "Emergency Vault"),
                  iconColor: AppColors.secondary,
                ),
                ActionItemCard(
                  icon: Icons.smart_toy_outlined,
                  title: "AI Financial Insights",
                  subtitle: "Get intelligent financial advice",
                  onTap: () => Navigator.pushNamed(context, '/ai_assistance'),
                  iconColor: AppColors.secondary,
                ),
                const SizedBox(height: AppTheme.spacingXl),
                const SectionTitle(title: "AI Insights"),
                const SizedBox(height: AppTheme.spacingMd),
                const AIInsightCard(
                  message:
                      "You are on track to save GHS 40 this week. Keep saving!",
                ),
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
          icon: Icons.savings,
          label: "Save",
          onTap: () => showComingSoon(context, "Save Money"),
          color: AppColors.secondary,
        ),
        QuickActionButton(
          icon: Icons.account_balance_wallet,
          label: "Borrow",
          onTap: () => showComingSoon(context, "Borrow Money"),
          color: AppColors.secondary,
        ),
        QuickActionButton(
          icon: Icons.track_changes,
          label: "Budget",
          onTap: () => showComingSoon(context, "Budget Tracker"),
          color: AppColors.secondary,
        ),
        QuickActionButton(
          icon: Icons.lock,
          label: "Vault",
          onTap: () => showComingSoon(context, "Emergency Vault"),
          color: AppColors.secondary,
        ),
      ],
    );
  }
}

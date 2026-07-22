import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';

/// Pay Anywhere Screen - Scan & pay with QR, accept payments as a merchant,
/// works online or offline.
class PayAnywhereScreen extends StatelessWidget {
  const PayAnywhereScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.payAnywhereColor,
      child: SingleChildScrollView(
        child: Column(
          children: [
            FeatureScreenHeader(
              title: "Pay Anywhere",
              subtitle: "Scan & pay with QR, online or offline",
              backgroundColor: AppTheme.payAnywhereColor,
              icon: Icons.qr_code_2,
            ),
            FeatureScreenBody(
              children: [
                const SectionTitle(title: "Quick Actions"),
                const SizedBox(height: AppTheme.spacingMd),
                _buildQuickActions(context),
                const SizedBox(height: AppTheme.spacingXl),
                const SectionTitle(title: "Payment Features"),
                const SizedBox(height: AppTheme.spacingMd),
                ActionItemCard(
                  icon: Icons.qr_code_scanner,
                  title: "Scan & Pay with QR",
                  subtitle: "Pay merchants by scanning QR codes",
                  onTap: () => showComingSoon(context, "QR Scanner"),
                  iconColor: AppTheme.payAnywhereColor,
                ),
                ActionItemCard(
                  icon: Icons.store,
                  title: "Accept Payments as Merchant",
                  subtitle: "Receive payments from customers",
                  onTap: () => showComingSoon(context, "Merchant Payments"),
                  iconColor: AppTheme.payAnywhereColor,
                ),
                ActionItemCard(
                  icon: Icons.wifi_off,
                  title: "Offline Payments",
                  subtitle: "Works online or offline",
                  onTap: () => showComingSoon(context, "Offline Payments"),
                  iconColor: AppTheme.payAnywhereColor,
                ),
                ActionItemCard(
                  icon: Icons.link,
                  title: "Payment Links",
                  subtitle: "Share payment links with anyone",
                  onTap: () => showComingSoon(context, "Payment Links"),
                  iconColor: AppTheme.payAnywhereColor,
                ),
                ActionItemCard(
                  icon: Icons.receipt,
                  title: "Transaction History",
                  subtitle: "View all your payment history",
                  onTap: () => showComingSoon(context, "Transaction History"),
                  iconColor: AppTheme.payAnywhereColor,
                ),
                const SizedBox(height: AppTheme.spacingXl),
                const SectionTitle(title: "Merchant Tools"),
                const SizedBox(height: AppTheme.spacingMd),
                _buildMerchantTools(),
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
          icon: Icons.qr_code_scanner,
          label: "Scan QR",
          onTap: () => showComingSoon(context, "QR Scanner"),
          color: AppTheme.payAnywhereColor,
        ),
        QuickActionButton(
          icon: Icons.qr_code,
          label: "My QR",
          onTap: () => showComingSoon(context, "My QR Code"),
          color: AppTheme.payAnywhereColor,
        ),
        QuickActionButton(
          icon: Icons.send,
          label: "Send",
          onTap: () => Navigator.pushNamed(context, '/instant_transfer'),
          color: AppTheme.payAnywhereColor,
        ),
        QuickActionButton(
          icon: Icons.store,
          label: "Merchant",
          onTap: () => showComingSoon(context, "Merchant Mode"),
          color: AppTheme.payAnywhereColor,
        ),
      ],
    );
  }

  Widget _buildMerchantTools() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.payAnywhereColor.withAlpha(10),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.payAnywhereColor.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Merchant Dashboard", style: AppTheme.headlineSmall),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Today", "GHS 450", Icons.today),
              _buildStatItem("Week", "GHS 3,200", Icons.date_range),
              _buildStatItem("Month", "GHS 12,500", Icons.calendar_month),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.payAnywhereColor, size: 24),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          value,
          style: AppTheme.headlineSmall.copyWith(
            color: AppTheme.payAnywhereColor,
          ),
        ),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: AppColors.lightGrey),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';

/// ZPay Wallet Screen - Multi-currency & crypto wallet with NFC/QR payments,
/// virtual & physical cards, and contactless merchant payments.
class ZPayScreen extends StatelessWidget {
  const ZPayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.main,
      child: SingleChildScrollView(
        child: Column(
          children: [
            FeatureScreenHeader(
              title: "ZPay Wallet",
              subtitle: "Multi-currency & crypto payments",
              icon: Icons.account_balance_wallet,
            ),
            FeatureScreenBody(
              children: [
                const SectionTitle(title: "Quick Actions"),
                const SizedBox(height: AppTheme.spacingMd),
                _buildQuickActions(context),
                const SizedBox(height: AppTheme.spacingXl),
                const SectionTitle(title: "Wallet Features"),
                const SizedBox(height: AppTheme.spacingMd),
                ActionItemCard(
                  icon: Icons.credit_card,
                  title: "Virtual & Physical Cards",
                  subtitle: "Manage your ZPay cards",
                  onTap: () => showComingSoon(context, "Cards Management"),
                ),
                ActionItemCard(
                  icon: Icons.nfc,
                  title: "NFC/QR Payments",
                  subtitle: "Pay offline with NFC or QR codes",
                  onTap: () => showComingSoon(context, "NFC/QR Payments"),
                ),
                ActionItemCard(
                  icon: Icons.contactless,
                  title: "Contactless Merchant Payments",
                  subtitle: "Tap to pay at any merchant",
                  onTap: () => showComingSoon(context, "Contactless Payments"),
                ),
                ActionItemCard(
                  icon: Icons.currency_exchange,
                  title: "Multi-Currency Exchange",
                  subtitle: "Convert between currencies instantly",
                  onTap: () => Navigator.pushNamed(context, '/converter'),
                ),
                ActionItemCard(
                  icon: Icons.send,
                  title: "Send Money",
                  subtitle: "Transfer to anyone, anywhere",
                  onTap: () =>
                      Navigator.pushNamed(context, '/instant_transfer'),
                ),
                const SizedBox(height: AppTheme.spacingXl),
                const SectionTitle(title: "AI Insights"),
                const SizedBox(height: AppTheme.spacingMd),
                const AIInsightCard(
                  message:
                      "You saved GHS 45 this month using ZPay. Keep it up!",
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
          icon: Icons.qr_code_scanner,
          label: "Scan QR",
          onTap: () => showComingSoon(context, "QR Scanner"),
        ),
        QuickActionButton(
          icon: Icons.send,
          label: "Send",
          onTap: () => Navigator.pushNamed(context, '/instant_transfer'),
        ),
        QuickActionButton(
          icon: Icons.download,
          label: "Receive",
          onTap: () => showComingSoon(context, "Receive Money"),
        ),
        QuickActionButton(
          icon: Icons.add_card,
          label: "Add Card",
          onTap: () => showComingSoon(context, "Add Card"),
        ),
      ],
    );
  }
}

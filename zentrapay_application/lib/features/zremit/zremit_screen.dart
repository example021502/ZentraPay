import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';

/// ZRemit Screen - Instant cross-border transfers, smart currency conversion,
/// and easy bill payments.
class ZRemitScreen extends StatelessWidget {
  const ZRemitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.zremitColor,
      child: SingleChildScrollView(
        child: Column(
          children: [
            FeatureScreenHeader(
              title: "ZRemit",
              subtitle: "Instant cross-border transfers",
              backgroundColor: AppTheme.zremitColor,
              icon: Icons.public,
            ),
            FeatureScreenBody(
              children: [
                const SectionTitle(title: "Quick Actions"),
                const SizedBox(height: AppTheme.spacingMd),
                _buildQuickActions(context),
                const SizedBox(height: AppTheme.spacingXl),
                const SectionTitle(title: "Transfer Features"),
                const SizedBox(height: AppTheme.spacingMd),
                ActionItemCard(
                  icon: Icons.send,
                  title: "Send Money Abroad",
                  subtitle: "Instant cross-border transfers",
                  onTap: () =>
                      Navigator.pushNamed(context, '/instant_transfer'),
                  iconColor: AppTheme.zremitColor,
                ),
                ActionItemCard(
                  icon: Icons.currency_exchange,
                  title: "Smart Currency Conversion",
                  subtitle: "Best rates guaranteed",
                  onTap: () => Navigator.pushNamed(context, '/converter'),
                  iconColor: AppTheme.zremitColor,
                ),
                ActionItemCard(
                  icon: Icons.receipt_long,
                  title: "Pay Bills Internationally",
                  subtitle: "Pay bills or send money easily",
                  onTap: () => showComingSoon(context, "International Bills"),
                  iconColor: AppTheme.zremitColor,
                ),
                ActionItemCard(
                  icon: Icons.history,
                  title: "Transfer History",
                  subtitle: "View all your transactions",
                  onTap: () => showComingSoon(context, "Transfer History"),
                  iconColor: AppTheme.zremitColor,
                ),
                ActionItemCard(
                  icon: Icons.people,
                  title: "Saved Recipients",
                  subtitle: "Quick send to frequent contacts",
                  onTap: () => showComingSoon(context, "Saved Recipients"),
                  iconColor: AppTheme.zremitColor,
                ),
                const SizedBox(height: AppTheme.spacingXl),
                const SectionTitle(title: "Exchange Rates"),
                const SizedBox(height: AppTheme.spacingMd),
                _buildExchangeRateCard(),
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
          icon: Icons.person_add,
          label: "New Contact",
          onTap: () => showComingSoon(context, "New Contact"),
          color: AppTheme.zremitColor,
        ),
        QuickActionButton(
          icon: Icons.account_balance,
          label: "To Bank",
          onTap: () {
            Navigator.pushNamed(
              context,
              '/external_payment',
              arguments: {'token': 'user_token_here', 'userData': {}},
            );
          },
          color: AppTheme.zremitColor,
        ),
        QuickActionButton(
          icon: Icons.qr_code_scanner,
          label: "Scan QR",
          onTap: () => showComingSoon(context, "QR Scanner"),
          color: AppTheme.zremitColor,
        ),
        QuickActionButton(
          icon: Icons.history,
          label: "History",
          onTap: () => showComingSoon(context, "Transaction History"),
          color: AppTheme.zremitColor,
        ),
      ],
    );
  }

  Widget _buildExchangeRateCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.zremitColor.withAlpha(10),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.zremitColor.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Live Exchange Rates", style: AppTheme.headlineSmall),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: AppTheme.spacingXs,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: AppTheme.successGreen),
                    const SizedBox(width: 4),
                    Text(
                      "Live",
                      style: TextStyle(
                        color: AppTheme.successGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildRateRow("1 USD", "87.03 GHS"),
          const Divider(),
          _buildRateRow("1 EUR", "95.12 GHS"),
          const Divider(),
          _buildRateRow("1 GBP", "110.45 GHS"),
        ],
      ),
    );
  }

  Widget _buildRateRow(String from, String to) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(from, style: AppTheme.bodyMedium),
          Text(
            to,
            style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

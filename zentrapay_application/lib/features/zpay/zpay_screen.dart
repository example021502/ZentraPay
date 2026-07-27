import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

// AppColors alias for backward compatibility with main.dart
extension AppColors on AppTheme {
  static const Color primaryPink = AppTheme.primaryPink;
  static const Color primaryWhite = AppTheme.primaryWhite;
  static const Color secondaryNavy = AppTheme.secondaryNavy;
  static const Color textBlack = AppTheme.textBlack;
  static const Color accentPurple = AppTheme.accentPurple;
  static const Color accentBlue = AppTheme.accentBlue;
  static const Color successGreen = AppTheme.successGreen;
  static const Color warningOrange = AppTheme.warningOrange;
  static const Color lightGrey = AppTheme.lightGrey;
}

class ZPayScreen extends StatelessWidget {
  const ZPayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryPink, Color(0xFF210163)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Text(
                      "ZPay Wallet",
                      style: AppTheme.whiteDisplayMedium.copyWith(fontSize: 24),
                    ),
                  ],
                ),
              ),

              // Balance Card
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Balance Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.spacingXl),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusXl,
                          ),
                          boxShadow: AppTheme.elevatedShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Balance",
                              style: AppTheme.whiteBodySmall,
                            ),
                            const SizedBox(height: AppTheme.spacingSm),
                            Text(
                              "GHS 3,345,456.00",
                              style: AppTheme.whiteDisplayLarge.copyWith(
                                fontSize: 36,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingSm),
                            Row(
                              children: [
                                _buildBalanceChip(
                                  "Fiat: GHS 2.5M",
                                  AppColors.accentBlue,
                                ),
                                const SizedBox(width: AppTheme.spacingMd),
                                _buildBalanceChip(
                                  "Crypto: GHS 845K",
                                  AppColors.successGreen,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingXl),

                      // Quick Actions
                      Text(
                        "Quick Actions",
                        style: AppTheme.whiteHeadline.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: AppTheme.spacingLg),

                      Row(
                        children: [
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.send,
                              label: "Send",
                              color: AppTheme.accentBlue,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.download,
                              label: "Receive",
                              color: AppTheme.successGreen,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: _buildActionCard(
                              icon: Icons.qr_code_scanner,
                              label: "Scan QR",
                              color: AppColors.warningOrange,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppTheme.spacingXl),

                      // Cards Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "My Cards",
                            style: AppTheme.whiteHeadline.copyWith(
                              fontSize: 18,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              "See All",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingLg),

                      // Card Preview
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.spacingLg),
                        decoration: BoxDecoration(
                          gradient: AppTheme.secondaryGradient,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg,
                          ),
                          boxShadow: AppTheme.elevatedShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  Icons.credit_card,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.spacingSm,
                                    vertical: AppTheme.spacingXs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(40),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusFull,
                                    ),
                                  ),
                                  child: Text(
                                    "ACTIVE",
                                    style: AppTheme.whiteBodySmall.copyWith(
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingXl),
                            Text(
                              "•••• •••• •••• 4242",
                              style: AppTheme.whiteDisplayMedium.copyWith(
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Card Holder",
                                      style: AppTheme.whiteBodySmall,
                                    ),
                                    Text(
                                      "JOHN DOE",
                                      style: AppTheme.whiteHeadline,
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "Expires",
                                      style: AppTheme.whiteBodySmall,
                                    ),
                                    Text(
                                      "12/28",
                                      style: AppTheme.whiteHeadline,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingXl),

                      // Features Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: AppTheme.spacingMd,
                        crossAxisSpacing: AppTheme.spacingMd,
                        children: [
                          _buildFeatureCard(
                            icon: Icons.nfc,
                            title: "NFC Payment",
                            subtitle: "Tap to pay",
                            color: AppColors.accentBlue,
                          ),
                          _buildFeatureCard(
                            icon: Icons.qr_code,
                            title: "QR Payment",
                            subtitle: "Scan & pay",
                            color: AppColors.successGreen,
                          ),
                          _buildFeatureCard(
                            icon: Icons.public,
                            title: "Multi-Currency",
                            subtitle: "50+ currencies",
                            color: AppColors.warningOrange,
                          ),
                          _buildFeatureCard(
                            icon: Icons.security,
                            title: "Secure",
                            subtitle: "Bank-grade encryption",
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.white.withAlpha(60)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            label,
            style: AppTheme.whiteBody.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppTheme.spacingMd),
          Text(title, style: AppTheme.whiteHeadline.copyWith(fontSize: 14)),
          const SizedBox(height: AppTheme.spacingXs),
          Text(subtitle, style: AppTheme.whiteBodySmall.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

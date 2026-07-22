import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';

/// Secure & Trusted Screen - Bank-grade security, biometric authentication,
/// and real-time fraud protection.
class SecureScreen extends StatelessWidget {
  const SecureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.secureColor,
      child: SingleChildScrollView(
        child: Column(
          children: [
            FeatureScreenHeader(
              title: "Secure & Trusted",
              subtitle: "Bank-grade security for your finances",
              backgroundColor: AppTheme.secureColor,
              icon: Icons.shield,
            ),
            FeatureScreenBody(
              children: [
                const SectionTitle(title: "Security Status"),
                const SizedBox(height: AppTheme.spacingMd),
                _buildSecurityStatusCard(),
                const SizedBox(height: AppTheme.spacingXl),
                const SectionTitle(title: "Security Features"),
                const SizedBox(height: AppTheme.spacingMd),
                ActionItemCard(
                  icon: Icons.fingerprint,
                  title: "Biometric Authentication",
                  subtitle: "Secure login with fingerprint or face ID",
                  onTap: () => showComingSoon(context, "Biometric Settings"),
                  iconColor: AppTheme.secureColor,
                ),
                ActionItemCard(
                  icon: Icons.shield_outlined,
                  title: "Real-Time Fraud Protection",
                  subtitle: "AI-powered fraud detection & prevention",
                  onTap: () => Navigator.pushNamed(context, '/fraud_detection'),
                  iconColor: AppTheme.secureColor,
                ),
                ActionItemCard(
                  icon: Icons.lock_outline,
                  title: "Two-Factor Authentication",
                  subtitle: "Extra layer of security for your account",
                  onTap: () => showComingSoon(context, "2FA Settings"),
                  iconColor: AppTheme.secureColor,
                ),
                ActionItemCard(
                  icon: Icons.history,
                  title: "Login History",
                  subtitle: "Track all login attempts",
                  onTap: () => showComingSoon(context, "Login History"),
                  iconColor: AppTheme.secureColor,
                ),
                ActionItemCard(
                  icon: Icons.notifications_active,
                  title: "Security Alerts",
                  subtitle: "Get notified of suspicious activity",
                  onTap: () => showComingSoon(context, "Security Alerts"),
                  iconColor: AppTheme.secureColor,
                ),
                const SizedBox(height: AppTheme.spacingXl),
                const SectionTitle(title: "Security Tips"),
                const SizedBox(height: AppTheme.spacingMd),
                _buildSecurityTips(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityStatusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: AppTheme.secondaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(
        children: [
          Icon(Icons.shield, color: Colors.white, size: 60),
          const SizedBox(height: AppTheme.spacingMd),
          Text("All Systems Secure", style: AppTheme.whiteHeadline),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            "Your account is protected with bank-grade security",
            style: AppTheme.whiteBodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                const SizedBox(width: AppTheme.spacingSm),
                Text("Last checked: Just now", style: AppTheme.whiteBodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTips() {
    final tips = [
      {
        "icon": Icons.password,
        "title": "Use Strong Passwords",
        "desc": "Mix letters, numbers & symbols",
      },
      {
        "icon": Icons.update,
        "title": "Keep App Updated",
        "desc": "Latest security patches included",
      },
      {
        "icon": Icons.wifi_off,
        "title": "Avoid Public WiFi",
        "desc": "Use mobile data for transactions",
      },
      {
        "icon": Icons.phonelink_lock,
        "title": "Enable 2FA",
        "desc": "Double protection for your account",
      },
    ];

    return Column(
      children: tips.map((tip) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.secureColor.withAlpha(10),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.secureColor.withAlpha(30)),
          ),
          child: Row(
            children: [
              Icon(
                tip["icon"] as IconData,
                color: AppTheme.secureColor,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tip["title"] as String, style: AppTheme.headlineSmall),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      tip["desc"] as String,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppColors.lightGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

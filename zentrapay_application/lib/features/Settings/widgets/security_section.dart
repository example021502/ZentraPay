import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/utils/Common/format_date_time_string.dart';
import 'package:zentrapay_application/features/Settings/widgets/section_label.dart';
import 'package:zentrapay_application/features/Settings/widgets/settings_card.dart';

/// The SECURITY block of the Settings screen: the three live security toggles
/// (biometric, two-factor, real-time fraud protection), the read-only Security
/// Alerts link, and the recent-login activity list.
///
/// Purely presentational — the toggle flags, the loading flag and the activity
/// list are owned by `Settings` (which is what persists them through
/// `SecuritySettingsRepository` / `LoginHistoryRepository`) and handed in here,
/// with every interaction reported back through a callback.
class SecuritySection extends StatelessWidget {
  final bool biometricEnabled;
  final bool twoFactorEnabled;
  final bool fraudProtection;

  /// True while the activity list is still being fetched — renders a spinner
  /// instead of the (still empty) list so the section doesn't flash its
  /// "no recent activity" copy first.
  final bool isLoading;

  /// Login history rows as built by `Settings` — each is a map with `title`,
  /// `device`, `time` and `color`.
  final List<Map<String, dynamic>> protectionHistory;

  final Future<void> Function() onToggleBiometric;
  final Future<void> Function() onToggleTwoFactor;
  final Future<void> Function() onToggleFraudProtection;

  const SecuritySection({
    super.key,
    required this.biometricEnabled,
    required this.twoFactorEnabled,
    required this.fraudProtection,
    required this.isLoading,
    required this.protectionHistory,
    required this.onToggleBiometric,
    required this.onToggleTwoFactor,
    required this.onToggleFraudProtection,
  });

  // Refactored security section to remove unnecessary outer spacing
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionLabel("SECURITY"),
        const SizedBox(height: 4),
        _buildSecurityOptions(context),
      ],
    );
  }

  Widget _buildSecurityOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsCard(
          children: [
            SettingsSwitchTile(
              icon: Icons.fingerprint,
              title: "Biometric Authentication",
              value: biometricEnabled,
              onChanged: onToggleBiometric,
            ),
            SettingsSwitchTile(
              icon: Icons.lock_outline,
              title: "Two-Factor Authentication",
              value: twoFactorEnabled,
              onChanged: onToggleTwoFactor,
            ),
            SettingsSwitchTile(
              icon: Icons.shield_outlined,
              title: "Real-Time Fraud Protection",
              value: fraudProtection,
              onChanged: onToggleFraudProtection,
            ),
            SettingsNavTile(
              icon: Icons.notifications_active_outlined,
              title: "Security Alerts",
              onTap: () => Navigator.pushNamed(context, '/fraud_detection'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingLg),
        Text("Recent Activity", style: AppTheme.labelLarge),
        const SizedBox(height: AppTheme.spacingSm),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (protectionHistory.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "No recent login activity",
              style: AppTheme.bodySmall.copyWith(color: AppColors.lightGrey),
            ),
          )
        else
          ...protectionHistory.map(_buildHistoryItem),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item['color'] as Color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.shield, color: AppTheme.textBlack, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item['title'],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                ),
                if ((item['device'] as String).isNotEmpty)
                  Text(
                    item['device'],
                    style: TextStyle(fontSize: 12, color: AppColors.textBlack),
                  ),
                Text(
                  formatDateTimeString(item['time']?.toString()),
                  style: TextStyle(fontSize: 11, color: AppColors.textBlack),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

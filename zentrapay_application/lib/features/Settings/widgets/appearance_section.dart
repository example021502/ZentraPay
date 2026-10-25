import 'package:flutter/material.dart';
import 'package:zentrapay_application/features/Settings/widgets/section_label.dart';
import 'package:zentrapay_application/features/Settings/widgets/settings_card.dart';

/// The APPEARANCE block of the Settings screen: the dark-mode switch and the
/// notification preferences. Purely presentational — `Settings` owns the flags
/// and does the optimistic update / backend save / revert.
class AppearanceSection extends StatelessWidget {
  final bool darkMode;
  final bool pushNotifications;
  final bool transactionAlerts;
  final Future<void> Function() onToggleDarkMode;
  final Future<void> Function() onTogglePush;
  final Future<void> Function() onToggleTransactionAlerts;

  const AppearanceSection({
    super.key,
    required this.darkMode,
    required this.pushNotifications,
    required this.transactionAlerts,
    required this.onToggleDarkMode,
    required this.onTogglePush,
    required this.onToggleTransactionAlerts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionLabel("APPEARANCE & ALERTS"),
        const SizedBox(height: 4),
        SettingsCard(
          children: [
            SettingsSwitchTile(
              icon: darkMode
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
              title: "Dark mode",
              subtitle: darkMode ? "On" : "Off",
              value: darkMode,
              onChanged: onToggleDarkMode,
            ),
            SettingsSwitchTile(
              icon: Icons.notifications_active_outlined,
              title: "Push notifications",
              value: pushNotifications,
              onChanged: onTogglePush,
            ),
            SettingsSwitchTile(
              icon: Icons.receipt_long_outlined,
              title: "Transaction alerts",
              value: transactionAlerts,
              onChanged: onToggleTransactionAlerts,
            ),
          ],
        ),
      ],
    );
  }
}

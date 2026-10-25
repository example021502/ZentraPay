import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:zentrapay_application/features/Settings/credential_sheets.dart';
import 'package:zentrapay_application/features/Settings/repository/cache_settings_data.dart';
import 'package:zentrapay_application/features/Settings/repository/credential_service.dart';
import 'package:zentrapay_application/core/models/security.dart';
import 'package:zentrapay_application/core/theme/section_header.dart';
import 'package:zentrapay_application/core/theme/theme_controller.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/Settings/widgets/appearance_section.dart';
import 'package:zentrapay_application/features/Settings/widgets/list_section.dart';
import 'package:zentrapay_application/features/Settings/widgets/security_section.dart';
import 'package:zentrapay_application/features/profile/repository/cache_profile_data.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/features/home/notifications_overlay.dart';
import 'package:zentrapay_application/features/profile/edit_profile_sheet.dart';
import 'package:zentrapay_application/main.dart';

/// Placeholder for the Merchant tab — content to be added later.
///
/// The former standalone Secure screen and the former standalone
/// profile/settings_screen.dart (security score, biometric/2FA/fraud
/// toggles, protection history) are both folded into this single widget's
/// SECURITY section — there's no separate "Secure" or "SettingsScreen"
/// destination in the app anymore.
class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  // General buttons list for settings options
  static const List<Map<String, dynamic>> _generalButtons = [
    {"name": "Account", "icon": Icons.person_2_outlined},
    {"name": "Notifications", "icon": Icons.notifications_outlined},
    {"name": "Support", "icon": Icons.support_agent_outlined},
  ];

  // Feedback buttons list for user reporting and feedback
  static const List<Map<String, dynamic>> _feedbackButtons = [
    {"name": "Report a bug", "icon": Icons.warning_amber_outlined},
    {"name": "Send feedback", "icon": Icons.send_outlined},
  ];

  // Danger zone buttons list for deleting account and logging out
  static const List<Map<String, dynamic>> _dangerZoneButtons = [
    {"name": "Logout", "icon": Icons.exit_to_app_outlined},
    {"name": "Delete Account", "icon": Icons.delete_outlined},
  ];

  bool biometricEnabled = false;
  bool twoFactorEnabled = false;
  bool fraudProtection = true;
  bool pushNotifications = true;
  bool transactionAlerts = true;
  bool darkMode = AppTheme.isDark;
  bool isLoadingSecurity = true;
  List<Map<String, dynamic>> protectionHistory = [];

  @override
  void initState() {
    super.initState();
    // Load settings and history on init
    _loadSecuritySettings();
  }

  /// Copies the server's row onto the screen. The saved dark-mode choice
  /// follows the user across devices, so it wins over this device's value.
  void _applySettings(SecuritySettings settings) {
    biometricEnabled = settings.biometricEnabled;
    twoFactorEnabled = settings.twoFactorEnabled;
    fraudProtection = settings.fraudProtectionEnabled;
    pushNotifications = settings.pushNotificationsEnabled;
    transactionAlerts = settings.transactionAlertsEnabled;
    darkMode = settings.darkMode;
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final settings = await SecuritySettingsRepository.instance.ensureLoaded();
      if (settings != null && mounted) {
        setState(() => _applySettings(settings));
        ThemeController.instance.setDark(settings.darkMode);
      }
    } catch (_) {
      // Keep defaults on failure.
    }

    try {
      final history = await LoginHistoryRepository.instance.ensureLoaded();
      if (mounted) {
        setState(() {
          protectionHistory = (history ?? []).map((h) {
            return {
              'title': h.success ? 'Successful login' : 'Failed login attempt',
              'device': h.deviceInfo ?? '',
              'time': h.createdAt,
              'color': h.success ? AppColors.green : AppColors.main,
            };
          }).toList();
        });
      }
    } catch (_) {
      // Keep an empty list on failure rather than fabricating history.
    } finally {
      if (mounted) setState(() => isLoadingSecurity = false);
    }
  }

  /// Optimistic update shared by every setting: [assign] puts [newValue] on
  /// screen at once, [save] writes it to the backend in the background, and if
  /// that fails the old value is put back and a light notice says so.
  Future<void> _change(
    bool newValue,
    void Function(bool value) assign,
    Future<void> Function(bool value) save,
    String label,
  ) async {
    void show(bool value) {
      if (mounted) {
        setState(() => assign(value));
      } else {
        assign(value);
      }
    }

    show(newValue);
    try {
      await save(newValue);
    } catch (_) {
      show(!newValue);
      ZentraNotifier.notice(
        "Couldn't save $label. Please try again.",
        icon: Icons.sync_problem_rounded,
      );
    }
  }

  Future<void> _toggleBiometric() => _change(
    !biometricEnabled,
    (v) => biometricEnabled = v,
    (v) => SecuritySettingsRepository.instance.setBiometric(v),
    "biometric sign-in",
  );

  Future<void> _toggleTwoFactor() => _change(
    !twoFactorEnabled,
    (v) => twoFactorEnabled = v,
    (v) => SecuritySettingsRepository.instance.setTwoFactor(v),
    "two-factor authentication",
  );

  Future<void> _toggleFraudProtection() => _change(
    !fraudProtection,
    (v) => fraudProtection = v,
    (v) => SecuritySettingsRepository.instance.setFraudProtection(v),
    "fraud protection",
  );

  Future<void> _togglePush() => _change(
    !pushNotifications,
    (v) => pushNotifications = v,
    (v) => SecuritySettingsRepository.instance.updatePreferences(
      pushNotifications: v,
    ),
    "notification preference",
  );

  Future<void> _toggleTransactionAlerts() => _change(
    !transactionAlerts,
    (v) => transactionAlerts = v,
    (v) => SecuritySettingsRepository.instance.updatePreferences(
      transactionAlerts: v,
    ),
    "transaction alerts",
  );

  Future<void> _toggleDarkMode() => _change(
    !darkMode,
    (v) {
      darkMode = v;
      ThemeController.instance.setDark(v);
    },
    (v) => SecuritySettingsRepository.instance.updatePreferences(darkMode: v),
    "appearance",
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: [
          ListenableBuilder(
            listenable: UserProfileRepository.instance,
            builder: (context, _) {
              final user = UserProfileRepository.instance.user;
              return SectionHeader(
                title: (user?.fullName.trim().isNotEmpty ?? false)
                    ? user!.fullName
                    : "Your account",
                subtitle: (user?.email.isNotEmpty ?? false)
                    ? user!.email
                    : "Profile, security and appearance",
                icon: Icons.manage_accounts_rounded,
                sheetColor: AppTheme.gray50,
              );
            },
          ),
          Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            color: AppTheme.gray50,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 25, 15, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppearanceSection(
                    darkMode: darkMode,
                    pushNotifications: pushNotifications,
                    transactionAlerts: transactionAlerts,
                    onToggleDarkMode: _toggleDarkMode,
                    onTogglePush: _togglePush,
                    onToggleTransactionAlerts: _toggleTransactionAlerts,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  ListSection(
                    title: "GENERAL",
                    buttons: _generalButtons,
                    onTapOption: _showOptionSheet,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  SecuritySection(
                    biometricEnabled: biometricEnabled,
                    twoFactorEnabled: twoFactorEnabled,
                    fraudProtection: fraudProtection,
                    isLoading: isLoadingSecurity,
                    protectionHistory: protectionHistory,
                    onToggleBiometric: _toggleBiometric,
                    onToggleTwoFactor: _toggleTwoFactor,
                    onToggleFraudProtection: _toggleFraudProtection,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  ListSection(
                    title: "FEEDBACK",
                    buttons: _feedbackButtons,
                    onTapOption: _showOptionSheet,
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  ListSection(
                    title: "DANGER ZONE",
                    buttons: _dangerZoneButtons,
                    onTapOption: _showOptionSheet,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // Settings option overlays — each General/Feedback/Danger-Zone button used
  // to just fire a "Coming Soon" toast. Every option now opens the same
  // slide-up sheet (showAppOverlaySheet, the History-overlay shape) with
  // real content where a backend already backs it (Account -> the real
  // edit-profile flow; Notifications -> the real notifications list) and
  // clearly-labeled standard/placeholder content where nothing exists yet
  // to link to.
  // ==========================================================================
  void _showOptionSheet(BuildContext context, String option) {
    switch (option) {
      case "Account":
        _showAccountSheet(context);
        return;
      case "Notifications":
        // Comment: reuse the real notification bell overlay — same backend
        // data, no separate "preferences" panel pretending to be something
        // that isn't wired up.
        showNotificationsOverlay(context);
        return;
      case "Support":
        _showInfoSheet(
          context,
          title: "Support",
          icon: Icons.support_agent_outlined,
          rows: const [
            _InfoRow(Icons.email_outlined, "Email", "support@zentrapay.com"),
            _InfoRow(
              Icons.chat_outlined,
              "Live chat",
              "In-app chat — coming soon",
            ),
            _InfoRow(Icons.help_outline, "Help center", "help.zentrapay.com"),
          ],
        );
        return;
      case "Report a bug":
        _showInfoSheet(
          context,
          title: "Report a Bug",
          icon: Icons.warning_amber_outlined,
          rows: const [
            _InfoRow(
              Icons.email_outlined,
              "Email us",
              "Describe what happened and the screen you were on: bugs@zentrapay.com",
            ),
          ],
        );
        return;
      case "Send feedback":
        _showInfoSheet(
          context,
          title: "Send Feedback",
          icon: Icons.send_outlined,
          rows: const [
            _InfoRow(
              Icons.email_outlined,
              "We'd love to hear from you",
              "feedback@zentrapay.com",
            ),
          ],
        );
        return;
      case "Delete Account":
        _showInfoSheet(
          context,
          title: "Delete Account",
          icon: Icons.delete_outlined,
          rows: const [
            _InfoRow(
              Icons.info_outline,
              "Contact support to delete your account",
              "Account deletion isn't self-service yet — email support@zentrapay.com from your registered email and we'll process it.",
            ),
          ],
        );
        return;
    }
  }

  void _showAccountSheet(BuildContext context) {
    showAppOverlaySheet(
      context: context,
      builder: (context) => ListenableBuilder(
        listenable: UserProfileRepository.instance,
        builder: (context, _) {
          final user = UserProfileRepository.instance.user;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Account", style: AppTheme.headlineMedium),
                const SizedBox(height: AppTheme.spacingLg),
                _InfoRow(Icons.person_outline, "Name", user?.fullName ?? ''),
                _InfoRow(Icons.email_outlined, "Email", user?.email ?? ''),
                _InfoRow(
                  Icons.phone_outlined,
                  "Phone",
                  user?.phoneNumber ?? '',
                ),
                _InfoRow(
                  Icons.verified_user_outlined,
                  "Verification",
                  "Tier ${user?.kycTier ?? 0}",
                ),
                const SizedBox(height: AppTheme.spacingLg),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).maybePop();
                      showEditProfileSheet(context);
                    },
                    child: const Text("Edit Profile"),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_reset_outlined),
                  title: const Text("Change PIN"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      showChangeCredentialSheet(context, CredentialKind.pin),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.password_outlined),
                  title: const Text("Change Password"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showChangeCredentialSheet(
                    context,
                    CredentialKind.password,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showInfoSheet(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_InfoRow> rows,
  }) {
    showAppOverlaySheet(
      context: context,
      minHeightFraction: 0.35,
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.textBlack),
                const SizedBox(width: AppTheme.spacingSm),
                Text(title, style: AppTheme.headlineMedium),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ...rows,
          ],
        ),
      ),
    );
  }
}

/// A single labeled row inside a settings option overlay — icon, a bold
/// label, and a description/value line underneath. Used both for read-only
/// info (Account) and static contact-channel content (Support, Report a
/// bug, Send feedback, Delete Account).
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.textBlack),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.gray700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter to draw a half-circle gauge arc meter
class HalfCircleGaugePainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color valueColor;
  final double strokeWidth;

  HalfCircleGaugePainter({
    required this.progress,
    required this.backgroundColor,
    required this.valueColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintBg = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintProg = Paint()
      ..color = valueColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Bounding rect for the arc (180 degrees semicircle)
    final rect = Rect.fromLTWH(
      strokeWidth / 3,
      strokeWidth / 3,
      size.width - strokeWidth,
      size.height * 2 - strokeWidth,
    );

    // Draw background half-circle arc from 180 degrees (pi) to 360 degrees (2 * pi)
    canvas.drawArc(rect, math.pi, math.pi, false, paintBg);

    // Draw active progress arc based on score percentage
    canvas.drawArc(rect, math.pi, math.pi * progress, false, paintProg);
  }

  @override
  bool shouldRepaint(covariant HalfCircleGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.valueColor != valueColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

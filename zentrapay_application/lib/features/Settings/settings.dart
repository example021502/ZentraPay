import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:zentrapay_application/features/Settings/repository/cache_settingsData.dart';
import 'package:zentrapay_application/features/Settings/widgets/list_section.dart';
import 'package:zentrapay_application/features/Settings/widgets/security_section.dart';
import 'package:zentrapay_application/features/profile/repository/cache_profileData.dart';
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
  bool isLoadingSecurity = true;
  List<Map<String, dynamic>> protectionHistory = [];

  // Derived from the three toggles below rather than cached separately —
  // a stored percent would go stale the moment any one toggle changes
  // (each _toggleX only updates its own flag), so compute it fresh on
  // every build instead.
  double get securityScorePercent {
    final activeChecks = [
      biometricEnabled,
      twoFactorEnabled,
      fraudProtection,
    ].where((c) => c).length;
    return activeChecks / 3;
  }

  @override
  void initState() {
    super.initState();
    // Load security settings and history on init
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final settings = await SecuritySettingsRepository.instance.ensureLoaded();
      if (settings != null && mounted) {
        setState(() {
          biometricEnabled = settings.biometricEnabled;
          twoFactorEnabled = settings.twoFactorEnabled;
          fraudProtection = settings.fraudProtectionEnabled;
        });
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

  Future<void> _toggleBiometric() async {
    final newValue = !biometricEnabled;
    setState(() => biometricEnabled = newValue);
    try {
      await SecuritySettingsRepository.instance.setBiometric(newValue);
    } catch (_) {
      if (mounted) setState(() => biometricEnabled = !newValue);
    }
  }

  Future<void> _toggleTwoFactor() async {
    final newValue = !twoFactorEnabled;
    setState(() => twoFactorEnabled = newValue);
    try {
      await SecuritySettingsRepository.instance.setTwoFactor(newValue);
    } catch (_) {
      if (mounted) setState(() => twoFactorEnabled = !newValue);
    }
  }

  Future<void> _toggleFraudProtection() async {
    final newValue = !fraudProtection;
    setState(() => fraudProtection = newValue);
    try {
      await SecuritySettingsRepository.instance.setFraudProtection(newValue);
    } catch (_) {
      if (mounted) setState(() => fraudProtection = !newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        decoration: BoxDecoration(
          color: AppTheme.gray50,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacingMd),
              // General Settings Section
              ListSection(
                title: "GENERAL",
                buttons: _generalButtons,
                onTapOption: _showOptionSheet,
              ),
              const SizedBox(height: 40),
              // Security Controls Section
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
              const SizedBox(height: 40),
              // Feedback and Reporting Section
              ListSection(
                title: "FEEDBACK",
                buttons: _feedbackButtons,
                onTapOption: _showOptionSheet,
              ),
              const SizedBox(height: 40),
              // Danger zone Section
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
                  onTap: () => showComingSoon(context, "Change PIN"),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.password_outlined),
                  title: const Text("Change Password"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showComingSoon(context, "Change Password"),
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
                Icon(icon, color: AppTheme.secondaryNavy),
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
          Icon(icon, size: 20, color: AppTheme.gray500),
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

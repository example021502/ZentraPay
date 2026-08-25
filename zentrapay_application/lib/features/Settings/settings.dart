import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/repositories/security_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/features/home/closeConfirmation.dart';
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
      child: Column(
        children: [
          // Security Score half-ring gauge meter at the top
          _buildSecurityScore(),
          const SizedBox(height: AppTheme.spacingXl),
          Container(
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
                  _buildListSection(context, "GENERAL", _generalButtons),
                  const SizedBox(height: 40),
                  // Security Controls Section
                  _buildSecuritySection(context),
                  const SizedBox(height: 40),
                  // Feedback and Reporting Section
                  _buildListSection(context, "FEEDBACK", _feedbackButtons),
                  const SizedBox(height: 40),
                  // Danger zone Section
                  _buildListSection(context, "DANGER ZONE", _dangerZoneButtons),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Padding(
      // Tightened vertical padding to eliminate bloated gaps
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        title,
        style: AppTheme.bodyMedium.copyWith(
          color: AppTheme.textBlack.withAlpha(80),
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildListSection(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> buttons,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionLabel(title),
        const SizedBox(height: 4),
        // Card decoration removed completely and layout wrapped in a compact Column
        Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(buttons.length, (index) {
            final buttonData = buttons[index];
            final bool isLogout = buttonData['name'] == "Logout";
            final bool isRedColored =
                isLogout || buttonData['name'] == "Delete Account";

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: Icon(
                      buttonData["icon"],
                      color: isRedColored ? AppColors.main : AppTheme.textBlack,
                    ),
                    title: Text(
                      buttonData["name"],
                      style: TextStyle(
                        color: isRedColored
                            ? AppColors.main
                            : AppTheme.textBlack,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: isLogout
                        ? () async {
                            final confirmed = await showCloseConfirmationDialog(
                              context,
                            );
                            if (!mounted || !confirmed) return;
                            Navigator.pushReplacementNamed(context, "/login");
                          }
                        : () => showComingSoon(context, buttonData["name"]),
                  ),
                ),
                if (index < buttons.length - 1)
                  AppTheme.divider(context, AppTheme.lightGrey),
              ],
            );
          }),
        ),
      ],
    );
  }

  // Refactored security section to remove unnecessary outer spacing
  Widget _buildSecuritySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionLabel("SECURITY"),
        const SizedBox(height: 4),
        _buildSecurityOptions(context),
      ],
    );
  }

  // Horizontal expanding half-circular gauge meter for security score
  Widget _buildSecurityScore() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double height = MediaQuery.of(context).size.height * 0.16;
            final double width = MediaQuery.of(context).size.width * 0.65;
            final int score = (securityScorePercent * 100).toInt();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: width,
                  height: height,
                  child: CustomPaint(
                    painter: HalfCircleGaugePainter(
                      progress: securityScorePercent,
                      backgroundColor: AppColors.primary.withAlpha(80),
                      valueColor: score < 20
                          ? AppColors.main
                          : score < 50
                          ? AppColors.orange
                          : AppColors.green,
                      strokeWidth: 25,
                    ),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: height * 0.2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: score < 20
                                    ? AppColors.main
                                    : score < 50
                                    ? AppColors.orange
                                    : AppColors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock,
                                size: 22,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "$score%",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryWhite,
                              ),
                            ),
                            const Text(
                              "Protected",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSecurityOptions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOptionTile(
            icon: Icons.fingerprint,
            title: "Biometric Authentication",
            trailing: biometricEnabled ? "Enabled" : "Disabled",
            trailingColor: biometricEnabled ? AppColors.green : AppColors.main,
            onTap: _toggleBiometric,
          ),
          const SizedBox(height: 15),
          _buildOptionTile(
            icon: Icons.lock_outline,
            title: "Two-Factor Authentication",
            trailing: twoFactorEnabled ? "Enabled" : "Disabled",
            trailingColor: twoFactorEnabled ? AppColors.green : AppColors.main,
            onTap: _toggleTwoFactor,
          ),
          const SizedBox(height: 15),
          _buildOptionTile(
            icon: Icons.shield_outlined,
            title: "Real-Time Fraud Protection",
            trailing: fraudProtection ? "Active" : "Inactive",
            trailingColor: fraudProtection
                ? AppColors.green
                : AppColors.textBlack,
            onTap: _toggleFraudProtection,
          ),
          const SizedBox(height: 15),
          _buildOptionTile(
            icon: Icons.notifications_active,
            title: "Security Alerts",
            trailing: "",
            showArrow: true,
            onTap: () => Navigator.pushNamed(context, '/fraud_detection'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String trailing,
    Color? trailingColor,
    bool showArrow = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.lightGrey.withAlpha(50),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textBlack, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textBlack,
                ),
              ),
            ),
            if (trailing.isNotEmpty)
              Text(
                trailing,
                style: TextStyle(
                  fontSize: 13,
                  color: trailingColor ?? AppColors.textBlack,
                ),
              ),
            if (showArrow)
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.textBlack,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item['color'] as Color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item['title'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                ),
                if ((item['device'] as String).isNotEmpty)
                  Text(
                    item['device'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textBlack,
                    ),
                  ),
                Text(
                  item['time'],
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textBlack,
                  ),
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

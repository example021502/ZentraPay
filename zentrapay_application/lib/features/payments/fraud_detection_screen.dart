import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/security.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/section_header.dart';
import 'package:zentrapay_application/core/utils/Common/format_date_time_string.dart';
import 'package:zentrapay_application/features/Settings/repository/cache_settings_data.dart';

/// Security Alerts (fraud detection). Laid out like the main sections: the
/// shared [SectionHeader] on top, then one white sheet with the same 15px side
/// padding the other sections use - the rows sit directly on the sheet instead
/// of inside nested padded cards.
class FraudDetectionScreen extends StatefulWidget {
  const FraudDetectionScreen({super.key});

  @override
  State<FraudDetectionScreen> createState() => _FraudDetectionScreenState();
}

class _FraudDetectionScreenState extends State<FraudDetectionScreen> {
  // What the monitor looks at. There is no backend concept for "monitored
  // categories" yet, only raised alerts, so these are descriptive.
  static const List<(IconData, String, String)> _watched = [
    (
      Icons.swap_horiz_rounded,
      'Unusual transactions',
      'Large or rapid transfers',
    ),
    (
      Icons.devices_other_rounded,
      'Suspicious sign-ins',
      'New devices and places',
    ),
    (
      Icons.mic_none_rounded,
      'Voice impersonation',
      'Requests for your PIN or password',
    ),
    (
      Icons.location_on_outlined,
      'Unusual location',
      'Activity far from your usual area',
    ),
  ];

  @override
  void initState() {
    super.initState();
    FraudAlertsRepository.instance.ensureLoaded().catchError((_) => null);
  }

  Future<void> _refresh() async {
    try {
      await FraudAlertsRepository.instance.ensureLoaded(forceRefresh: true);
    } catch (_) {
      // The repository keeps the error for the list below.
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
      case 'HIGH':
        return AppTheme.errorRed;
      case 'MEDIUM':
        return AppTheme.warningOrange;
      default:
        return AppTheme.secureColor;
    }
  }

  String _humanizeAlertType(String alertType) {
    if (alertType.isEmpty) return 'Alert';
    return alertType
        .split('_')
        .map(
          (w) => w.isEmpty
              ? w
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Widget _statChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.glassSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textBlack),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTheme.whiteBodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return ListenableBuilder(
      listenable: FraudAlertsRepository.instance,
      builder: (context, _) {
        final alerts =
            FraudAlertsRepository.instance.data ?? const <FraudAlert>[];
        final open = alerts.where((a) => !a.isResolved).length;
        return SectionHeader(
          title: 'Security Alerts',
          subtitle: 'Fraud detection is watching your account',
          icon: Icons.shield_rounded,
          showBack: true,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statChip(Icons.check_circle_outline, 'Monitoring on'),
              _statChip(
                open == 0
                    ? Icons.verified_outlined
                    : Icons.warning_amber_rounded,
                open == 0
                    ? 'All clear'
                    : '$open open alert${open == 1 ? '' : 's'}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
    child: Text(text, style: AppTheme.headlineSmall),
  );

  Widget _watchedRow((IconData, String, String) item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.brand.withValues(alpha: 0.1),
            child: Icon(item.$1, size: 18, color: AppTheme.textBlack),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.$2, style: AppTheme.labelLarge),
                Text(
                  item.$3,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            size: 18,
            color: AppTheme.successGreen,
          ),
        ],
      ),
    );
  }

  Widget _alertRow(FraudAlert alert) {
    final color = alert.isResolved
        ? AppTheme.successGreen
        : _severityColor(alert.severity);
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color,
            child: Icon(
              alert.isResolved ? Icons.check_rounded : Icons.warning_rounded,
              color: AppTheme.textBlack,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _humanizeAlertType(alert.alertType),
                        style: AppTheme.labelLarge,
                      ),
                    ),
                    Text(
                      alert.isResolved ? 'Resolved' : alert.severity,
                      style: AppTheme.labelSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (alert.message.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(alert.message, style: AppTheme.bodyMedium),
                ],
                const SizedBox(height: 2),
                Text(
                  formatDateTimeString(alert.createdAt),
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _alerts() {
    return ListenableBuilder(
      listenable: FraudAlertsRepository.instance,
      builder: (context, _) {
        final repo = FraudAlertsRepository.instance;
        if (repo.isLoading && repo.data == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (repo.error != null && repo.data == null) {
          return Text(
            "Couldn't load your alerts. Pull down to try again.",
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
          );
        }
        final alerts = repo.data ?? const <FraudAlert>[];
        if (alerts.isEmpty) {
          return Text(
            "No fraud alerts. You're all clear.",
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
          );
        }
        return Column(children: alerts.map(_alertRow).toList());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: RefreshIndicator(
        onRefresh: _refresh,
        edgeOffset: 120,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _header(),
            SectionSheet(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title('What we watch'),
                  ..._watched.map(_watchedRow),
                  const SizedBox(height: AppTheme.spacingMd),
                  _title('Recent alerts'),
                  _alerts(),
                  const SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

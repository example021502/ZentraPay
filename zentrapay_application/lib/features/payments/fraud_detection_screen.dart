import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/models/security.dart';
import 'package:zentrapay_application/core/repositories/security_repository.dart';

class FraudDetectionScreen extends StatefulWidget {
  const FraudDetectionScreen({super.key});

  @override
  State<FraudDetectionScreen> createState() => _FraudDetectionScreenState();
}

class _FraudDetectionScreenState extends State<FraudDetectionScreen> {
  bool fraudDetectionEnabled = true;

  // Feature-category rows shown regardless of alert history — there is no
  // backend concept for "monitored categories" yet, only raised alerts.
  final List<Map<String, dynamic>> fraudItems = [
    {
      'icon': Icons.shield,
      'title': 'Unusual transactions',
      'subtitle': 'Monitoring large transfers',
    },
    {
      'icon': Icons.person_off,
      'title': 'Suspicious login activity',
      'subtitle': 'New Device was detected',
    },
    {
      'icon': Icons.mic,
      'title': 'Voice impersonation',
      'subtitle': 'Analyzing voice patterns',
    },
    {
      'icon': Icons.location_on,
      'title': 'Unusual location',
      'subtitle': 'Tracking location changes',
    },
  ];

  @override
  void initState() {
    super.initState();
    FraudAlertsRepository.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.main,
      appBar: AppBar(
        backgroundColor: AppColors.main,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Fraud Detection",
          style: TextStyle(color: AppColors.primary, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildFraudList(),
            const SizedBox(height: 20),
            _buildRecentAlerts(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Fraud Detection",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          Row(
            children: [
              const Text(
                "On",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFraudList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(20),
        ),
      ),
      child: Column(
        children: fraudItems.map((item) => _buildFraudItem(item)).toList(),
      ),
    );
  }

  Widget _buildFraudItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.main.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item['icon'], color: AppColors.textBlack, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['subtitle'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textBlack,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textBlack,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAlerts() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recent Alerts",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: FraudAlertsRepository.instance,
            builder: (context, _) {
              final repo = FraudAlertsRepository.instance;
              if (repo.isLoading && repo.data == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (repo.error != null && repo.data == null) {
                return const Text(
                  "Couldn't load fraud alerts. Pull to refresh later.",
                  style: TextStyle(fontSize: 13, color: AppColors.textBlack),
                );
              }
              final alerts = repo.data ?? [];
              if (alerts.isEmpty) {
                return const Text(
                  "No fraud alerts — you're all clear.",
                  style: TextStyle(fontSize: 13, color: AppColors.textBlack),
                );
              }
              return Column(
                children: alerts.map((alert) => _buildAlertItem(alert)).toList(),
              );
            },
          ),
        ],
      ),
    );
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

  Widget _buildAlertItem(FraudAlert alert) {
    final color = _severityColor(alert.severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _humanizeAlertType(alert.alertType),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textBlack,
                        ),
                      ),
                    ),
                    Text(
                      alert.isResolved ? "Resolved" : alert.severity,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: alert.isResolved
                            ? AppTheme.successGreen
                            : color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.createdAt,
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

import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/repositories/security_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool biometricEnabled = false;
  bool fraudProtection = true;
  double securityScorePercent = 0;
  bool isLoading = true;

  List<Map<String, dynamic>> protectionHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await SecuritySettingsRepository.instance
          .ensureLoaded();
      if (settings != null) {
        setState(() {
          biometricEnabled = settings.biometricEnabled;
          fraudProtection = settings.fraudProtectionEnabled;
          final activeChecks = [
            settings.biometricEnabled,
            settings.twoFactorEnabled,
            settings.fraudProtectionEnabled,
          ].where((c) => c).length;
          securityScorePercent = activeChecks / 3;
        });
      }
    } catch (_) {
      // Keep defaults on failure.
    }

    try {
      final history = await LoginHistoryRepository.instance.ensureLoaded();
      setState(() {
        protectionHistory = (history ?? []).map((h) {
          return {
            'type': 'login',
            'title': h.success ? 'Successful login' : 'Failed login attempt',
            'device': h.deviceInfo ?? '',
            'time': h.createdAt,
            'icon': Icons.shield,
            'color': h.success ? AppColors.green : AppColors.main,
          };
        }).toList();
      });
    } catch (_) {
      // Keep an empty list on failure rather than fabricating history.
    } finally {
      if (mounted) setState(() => isLoading = false);
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
    return Scaffold(
      backgroundColor: AppColors.main,
      appBar: AppBar(
        backgroundColor: AppColors.main,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings",
          style: TextStyle(color: AppColors.primary, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSecurityScore(),
            const SizedBox(height: 20),
            _buildSecurityOptions(),
            const SizedBox(height: 20),
            _buildProtectionHistory(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityScore() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.main,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: securityScorePercent,
                  strokeWidth: 12,
                  backgroundColor: AppColors.primary.withAlpha(50),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.green,
                  ),
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${(securityScorePercent * 100).toStringAsFixed(0)}%",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    "Protected",
                    style: TextStyle(fontSize: 14, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityOptions() {
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
        children: [
          _buildOptionTile(
            icon: Icons.fingerprint,
            title: "Biometric Authentication",
            trailing: biometricEnabled ? "Enabled" : "Disabled",
            trailingColor: biometricEnabled ? AppColors.green : AppColors.main,
            onTap: _toggleBiometric,
          ),
          const SizedBox(height: 16),
          _buildOptionTile(
            icon: Icons.lock,
            title: "Change PIN",
            trailing: "",
            showArrow: true,
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildOptionTile(
            icon: Icons.visibility,
            title: "Fraud Protection",
            trailing: fraudProtection ? "Active" : "Inactive",
            trailingColor: fraudProtection
                ? AppColors.green
                : AppColors.textBlack,
            onTap: _toggleFraudProtection,
          ),
          const SizedBox(height: 16),
          _buildOptionTile(
            icon: Icons.devices,
            title: "Trusted Devices",
            trailing: "2 devices",
            showArrow: true,
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildOptionTile(
            icon: Icons.person,
            title: "Your Profile",
            trailing: "",
            showArrow: true,
            onTap: () {},
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.lightGrey, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textBlack, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 14, color: AppColors.textBlack),
              ),
            ),
            if (trailing.isNotEmpty)
              Text(
                trailing,
                style: TextStyle(
                  fontSize: 14,
                  color: trailingColor ?? AppColors.textBlack,
                ),
              ),
            if (showArrow)
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textBlack,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtectionHistory() {
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
            "Protection history",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (protectionHistory.isEmpty)
            const Text(
              "No protection events recorded yet.",
              style: TextStyle(fontSize: 13, color: AppColors.textBlack),
            )
          else
            ...protectionHistory.map((item) => _buildHistoryItem(item)),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
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
              color: item['color'] as Color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item['icon'], color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
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
                if (item.containsKey('amount'))
                  Text(
                    item['amount'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textBlack,
                    ),
                  )
                else if (item.containsKey('device'))
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

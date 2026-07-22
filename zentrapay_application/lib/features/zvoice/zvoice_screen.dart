import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';

/// ZVoice AI Screen - Full voice control (English, French, Swahili, Twi, Hausa),
/// hands-free balance checks & transfers, and voice fraud alerts.
class ZVoiceScreen extends StatelessWidget {
  const ZVoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.zvoiceColor,
      child: SingleChildScrollView(
        child: Column(
          children: [
            FeatureScreenHeader(
              title: "ZVoice AI",
              subtitle: "Full voice control for your finances",
              backgroundColor: AppTheme.zvoiceColor,
              icon: Icons.mic,
            ),
            FeatureScreenBody(
              children: [
                const SectionTitle(title: "Voice Commands"),
                const SizedBox(height: AppTheme.spacingMd),
                _buildVoiceCommandButtons(context),
                const SizedBox(height: AppTheme.spacingXl),
                const SectionTitle(title: "Voice Features"),
                const SizedBox(height: AppTheme.spacingMd),
                ActionItemCard(
                  icon: Icons.account_balance_wallet,
                  title: "Hands-Free Balance Checks",
                  subtitle: "Ask ZVoice your balance anytime",
                  onTap: () => Navigator.pushNamed(context, '/voice_recording'),
                  iconColor: AppTheme.zvoiceColor,
                ),
                ActionItemCard(
                  icon: Icons.send,
                  title: "Voice Transfers",
                  subtitle: "Send money using voice commands",
                  onTap: () => Navigator.pushNamed(context, '/voice_recording'),
                  iconColor: AppTheme.zvoiceColor,
                ),
                ActionItemCard(
                  icon: Icons.receipt_long,
                  title: "Pay Bills by Voice",
                  subtitle: "Pay bills or send money easily",
                  onTap: () => Navigator.pushNamed(context, '/voice_recording'),
                  iconColor: AppTheme.zvoiceColor,
                ),
                ActionItemCard(
                  icon: Icons.warning_amber,
                  title: "Voice Fraud Alerts",
                  subtitle: "Get instant voice fraud notifications",
                  onTap: () => Navigator.pushNamed(context, '/fraud_detection'),
                  iconColor: AppTheme.zvoiceColor,
                ),
                const SizedBox(height: AppTheme.spacingXl),
                const SectionTitle(title: "Supported Languages"),
                const SizedBox(height: AppTheme.spacingMd),
                _buildLanguageGrid(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceCommandButtons(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/voice_recording'),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 50),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          "Tap to speak",
          style: AppTheme.bodyMedium.copyWith(color: AppColors.lightGrey),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          "Try: \"Check my balance\" or \"Send 50 GHS to John\"",
          style: AppTheme.bodySmall.copyWith(color: AppColors.lightGrey),
        ),
      ],
    );
  }

  Widget _buildLanguageGrid() {
    final languages = [
      {"name": "English", "flag": "🇬🇧"},
      {"name": "French", "flag": "🇫🇷"},
      {"name": "Swahili", "flag": "🇰🇪"},
      {"name": "Twi", "flag": "🇬🇭"},
      {"name": "Hausa", "flag": "🇳🇬"},
    ];

    return Wrap(
      spacing: AppTheme.spacingSm,
      runSpacing: AppTheme.spacingSm,
      children: languages.map((lang) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          decoration: BoxDecoration(
            color: AppTheme.zvoiceColor.withAlpha(10),
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(color: AppTheme.zvoiceColor.withAlpha(50)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lang["flag"]!, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                lang["name"]!,
                style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

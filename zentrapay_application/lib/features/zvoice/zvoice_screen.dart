import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zentrapay_application/core/repositories/voice_command_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/main.dart';

/// ZVoice AI Screen - Full voice control (English, French, Swahili, Twi, Hausa),
/// hands-free balance checks & transfers, and voice fraud alerts.
class ZVoiceScreen extends StatefulWidget {
  const ZVoiceScreen({super.key});

  @override
  State<ZVoiceScreen> createState() => _ZVoiceScreenState();
}

class _ZVoiceScreenState extends State<ZVoiceScreen> {
  @override
  void initState() {
    super.initState();
    VoiceCommandHistoryRepository.instance.ensureLoaded();
    VoiceFraudAlertsRepository.instance.ensureLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppTheme.gray50,
        child: Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 15.0,
                horizontal: 20.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Icon(
                            Icons.arrow_back,
                            color: AppTheme.textBlack,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        const Text("ZVoice AI", style: AppTheme.headlineSmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  const _VoiceCommandActionSection(),
                  const SizedBox(height: AppTheme.spacingXl),
                  const _ActivitySummarySection(),
                  const SizedBox(height: AppTheme.spacingXl),
                  Text(
                    "More On Voice AI",
                    style: AppTheme.headlineSmall.copyWith(
                      color: AppTheme.lightGrey,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  ActionItemCard(
                    icon: Icons.account_balance_wallet,
                    title: "Hands-Free Balance Checks",
                    subtitle: "Ask ZVoice your balance anytime",
                    onTap: () =>
                        Navigator.pushNamed(context, '/voice_recording'),
                    iconColor: AppTheme.zvoiceColor,
                  ),
                  ActionItemCard(
                    icon: Icons.send,
                    title: "Voice Transfers",
                    subtitle: "Send money using voice commands",
                    onTap: () =>
                        Navigator.pushNamed(context, '/voice_recording'),
                    iconColor: AppTheme.zvoiceColor,
                  ),
                  ActionItemCard(
                    icon: Icons.receipt_long,
                    title: "Pay Bills by Voice",
                    subtitle: "Pay bills or send money easily",
                    onTap: () =>
                        Navigator.pushNamed(context, '/voice_recording'),
                    iconColor: AppTheme.zvoiceColor,
                  ),
                  ActionItemCard(
                    icon: Icons.warning_amber,
                    title: "Voice Fraud Alerts",
                    subtitle: "Get instant voice fraud notifications",
                    onTap: () =>
                        Navigator.pushNamed(context, '/fraud_detection'),
                    iconColor: AppTheme.zvoiceColor,
                  ),
                  const SizedBox(height: AppTheme.spacingXl),
                  const SectionTitle(title: "Supported Languages"),
                  const SizedBox(height: AppTheme.spacingMd),
                  const _LanguageGridSection(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivitySummarySection extends StatelessWidget {
  const _ActivitySummarySection();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        VoiceCommandHistoryRepository.instance,
        VoiceFraudAlertsRepository.instance,
      ]),
      builder: (context, _) {
        final historyRepo = VoiceCommandHistoryRepository.instance;
        final alertsRepo = VoiceFraudAlertsRepository.instance;
        final commandCount = historyRepo.data?.length;
        final alertCount = alertsRepo.data?.length;

        return Row(
          children: [
            Expanded(
              child: Container(
                decoration: AppTheme.cardDecoration,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 15.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 10,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withAlpha(20),
                          borderRadius: BorderRadius.circular(200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Icon(
                            Icons.speed,
                            size: 22,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text("0", style: AppTheme.headlineLarge),
                          Text(
                            "Latency",
                            style: AppTheme.labelLarge.copyWith(
                              color: AppTheme.lightGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Container(
                decoration: AppTheme.cardDecoration,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 15.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 10,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withAlpha(20),
                          borderRadius: BorderRadius.circular(200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Icon(
                            Icons.warning,
                            size: 22,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "${alertCount ?? 0}",
                            style: AppTheme.headlineLarge,
                          ),
                          Text(
                            "Fraud Alerts",
                            style: AppTheme.labelLarge.copyWith(
                              color: AppTheme.lightGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VoiceCommandActionSection extends StatelessWidget {
  const _VoiceCommandActionSection();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        HapticFeedback.mediumImpact();
        Navigator.pushNamed(context, '/voice_recording');
      },
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: const Icon(Icons.mic, color: Colors.white, size: 50),
      ),
    );
  }
}

class _LanguageGridSection extends StatelessWidget {
  const _LanguageGridSection();

  @override
  Widget build(BuildContext context) {
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

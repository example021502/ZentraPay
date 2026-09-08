import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zentrapay_application/core/models/security.dart';
import 'package:zentrapay_application/features/Settings/repository/cache_settingsData.dart';
import 'package:zentrapay_application/features/zvoice/repository/cache_zvoiceData.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

/// ZVoice AI Screen — Figma redesign.
///
/// A single sticky pink hero (back/help icons, floating chat launcher, and
/// the pink backdrop itself) hosts a vertical [PageView] of three in-section
/// pages — Tap-to-talk, Security, and Settings — so swiping between them
/// never rebuilds or flickers the hero chrome. Chat is a genuinely separate
/// pushed route (`/ai_assistance`, styled to match) — that's "navigating
/// outside this section" — and because Flutter keeps prior routes alive on
/// the Navigator stack, popping back off Chat lands the user on this screen
/// exactly as they left it, no reload.
class ZVoiceScreen extends StatefulWidget {
  const ZVoiceScreen({super.key});

  @override
  State<ZVoiceScreen> createState() => _ZVoiceScreenState();
}

class _ZVoiceScreenState extends State<ZVoiceScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  static const _pageCount = 3;

  @override
  void initState() {
    super.initState();
    VoiceCommandHistoryRepository.instance.ensureLoaded();
    VoiceFraudAlertsRepository.instance.ensureLoaded();
    FraudAlertsRepository.instance.ensureLoaded();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _openHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: const Text("ZVoice AI"),
        content: const Text(
          "Tap the microphone and speak naturally to check your balance, "
          "send money, or pay a bill. Swipe up for security status and "
          "language settings, or tap the chat bubble to type instead.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it"),
          ),
        ],
      ),
    );
  }

  void _openChat() => Navigator.pushNamed(context, '/ai_assistance');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryPink,
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) => setState(() => _pageIndex = i),
              children: [
                const _ZVoiceTapPage(),
                const _ZVoiceSecurityPage(),
                _ZVoiceSettingsPage(onAskAnything: () => _goToPage(0)),
              ],
            ),
          ),
          // Pinned top chrome — never rebuilds as pages swipe underneath.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    _CircleIconButton(
                      icon: Icons.help_outline_rounded,
                      onTap: _openHelp,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Pinned chat launcher — "navigating to other parts of ZVoice AI
          // like chat" pushes a real route (see _openChat), which is what
          // keeps this whole sticky page underneath, untouched, on the
          // Navigator stack for when the user comes back.
          Positioned(
            right: 20,
            bottom: 44,
            child: SafeArea(
              top: false,
              child: _CircleIconButton(
                icon: Icons.chat_bubble_outline_rounded,
                onTap: _openChat,
                size: 52,
              ),
            ),
          ),
          // Swipe-for-more hint + page dots.
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: SafeArea(
              top: false,
              child: _PageSwipeHint(
                pageCount: _pageCount,
                currentIndex: _pageIndex,
                onTap: () => _goToPage((_pageIndex + 1) % _pageCount),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White-on-pink circular icon button used for the back/help/chat controls.
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: AppTheme.cardShadow,
        ),
        child: Icon(icon, color: AppTheme.primaryPink, size: size * 0.42),
      ),
    );
  }
}

/// Bouncing chevron + drag-handle pill at the bottom of every in-section
/// page — the Figma's "swipe up for more" affordance. Also tappable to
/// advance (and cycle) through the pages for anyone who'd rather tap.
class _PageSwipeHint extends StatefulWidget {
  final int pageCount;
  final int currentIndex;
  final VoidCallback onTap;

  const _PageSwipeHint({
    required this.pageCount,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<_PageSwipeHint> createState() => _PageSwipeHintState();
}

class _PageSwipeHintState extends State<_PageSwipeHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -4 * _controller.value),
              child: child,
            ),
            child: const Icon(
              Icons.keyboard_arrow_up_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(210),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.pageCount, (i) {
              final active = i == widget.currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(active ? 255 : 120),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Page 1 — "Tap" — the tap-to-talk mic hero, per the first Figma frame.
class _ZVoiceTapPage extends StatefulWidget {
  const _ZVoiceTapPage();

  @override
  State<_ZVoiceTapPage> createState() => _ZVoiceTapPageState();
}

class _ZVoiceTapPageState extends State<_ZVoiceTapPage>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  // On-device speech-to-text isn't wired up (no transcription package in
  // this app), so a stopped recording is logged as a voice session with the
  // backend rather than fabricating transcript text — matches the prior
  // VoiceRecordingScreen behavior this page now replaces.
  Future<void> _onTapMic() async {
    HapticFeedback.mediumImpact();
    final wasRecording = _isRecording;
    setState(() => _isRecording = !_isRecording);
    if (wasRecording) {
      try {
        await VoiceCommandHistoryRepository.instance.sendCommand(
          commandType: 'VOICE',
          transcript: '(no transcription available)',
        );
      } catch (_) {
        // Best-effort — recording UI state already reflects the stop.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isRecording ? "Listening…" : "Tap",
            style: AppTheme.whiteHeadline,
          ),
          const SizedBox(height: 44),
          GestureDetector(
            onTap: _onTapMic,
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                final t = _glowController.value;
                final glow = _isRecording ? 0.55 + 0.35 * t : 0.22 + 0.12 * t;
                final scale = _isRecording ? 1.0 + 0.05 * t : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 220,
                    height: 220,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: glow * 0.45),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 150,
                height: 150,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFB0104E),
                ),
                child: Container(
                  width: 122,
                  height: 122,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 54,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Page 2 — Security status, per the second Figma frame: fraud-monitoring
/// categories plus real recent alerts from [FraudAlertsRepository].
class _ZVoiceSecurityPage extends StatelessWidget {
  const _ZVoiceSecurityPage();

  static const _fraudItems = [
    {
      'icon': Icons.shield_outlined,
      'title': 'Unusual transactions',
      'subtitle': 'Monitoring large transfers',
    },
    {
      'icon': Icons.person_off_outlined,
      'title': 'Suspicious login activity',
      'subtitle': 'New Device was detected',
    },
    {
      'icon': Icons.mic_none_rounded,
      'title': 'Voice impersonation',
      'subtitle': 'Analyzing voice patterns',
    },
    {
      'icon': Icons.location_on_outlined,
      'title': 'Unusual location',
      'subtitle': 'Tracking location changes',
    },
  ];

  Color _severityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
      case 'HIGH':
        return AppTheme.errorRed;
      case 'MEDIUM':
        return AppTheme.warningOrange;
      default:
        return AppTheme.successGreen;
    }
  }

  String _humanize(String alertType) {
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

  Widget _whiteCard({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      boxShadow: AppTheme.cardShadow,
    ),
    child: child,
  );

  Widget _fraudRow(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryPink.withAlpha(20),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              item['icon'] as IconData,
              color: AppTheme.primaryPink,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] as String,
                  style: AppTheme.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item['subtitle'] as String,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.lightGrey),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _alertRow(FraudAlert alert) {
    final color = _severityColor(alert.severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(
              alert.isResolved ? Icons.check_rounded : Icons.warning_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _humanize(alert.alertType),
                  style: AppTheme.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  alert.createdAt,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.lightGrey),
                ),
              ],
            ),
          ),
          Text(
            alert.isResolved ? "Secure" : alert.severity,
            style: AppTheme.labelSmall.copyWith(
              color: alert.isResolved ? AppTheme.successGreen : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 96, 20, 80),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _whiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Fraud Detection", style: AppTheme.headlineMedium),
                    Row(
                      children: [
                        Text(
                          "On",
                          style: AppTheme.labelLarge.copyWith(
                            color: AppTheme.successGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppTheme.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),
                ..._fraudItems.map(_fraudRow),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _whiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Recent Alerts", style: AppTheme.headlineMedium),
                const SizedBox(height: AppTheme.spacingMd),
                ListenableBuilder(
                  listenable: FraudAlertsRepository.instance,
                  builder: (context, _) {
                    final repo = FraudAlertsRepository.instance;
                    if (repo.isLoading && repo.data == null) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (repo.error != null && repo.data == null) {
                      return Text(
                        "Couldn't load fraud alerts. Pull to refresh later.",
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.lightGrey,
                        ),
                      );
                    }
                    final alerts = repo.data ?? [];
                    if (alerts.isEmpty) {
                      return Text(
                        "No fraud alerts — you're all clear.",
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.lightGrey,
                        ),
                      );
                    }
                    return Column(children: alerts.map(_alertRow).toList());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Page 3 — Settings, per the third Figma frame: supported languages,
/// hands-free confirmation, preferred language, and the "ask anything" CTA
/// that jumps back to the tap-to-talk page.
class _ZVoiceSettingsPage extends StatefulWidget {
  final VoidCallback onAskAnything;

  const _ZVoiceSettingsPage({required this.onAskAnything});

  @override
  State<_ZVoiceSettingsPage> createState() => _ZVoiceSettingsPageState();
}

class _ZVoiceSettingsPageState extends State<_ZVoiceSettingsPage> {
  // No backend concept for these preferences yet (voice command language is
  // passed per-request, not stored) — kept as local UI state, same pattern
  // FraudDetectionScreen uses for its own on/off toggle.
  bool _handsFree = true;
  String _preferredLanguage = 'French';

  static const _supportedLanguages = ['French', 'Swahili', 'Twi', 'Hausa'];
  static const _dropdownLanguages = [
    'English',
    'French',
    'Swahili',
    'Twi',
    'Hausa',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 96, 20, 80),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Command Your Finances with Intuitive Voice AI",
                  style: AppTheme.headlineLarge,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Text(
                  "Supported Languages",
                  style: AppTheme.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                ..._supportedLanguages.map(
                  (lang) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        AppTheme.dot(AppTheme.textBlack),
                        const SizedBox(width: 4),
                        Text(lang, style: AppTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.gray100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          "Hands Free Confirmation Speaker",
                          style: AppTheme.bodyMedium,
                        ),
                      ),
                      Switch(
                        value: _handsFree,
                        activeThumbColor: AppTheme.successGreen,
                        onChanged: (v) => setState(() => _handsFree = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Preferred Language:", style: AppTheme.bodyMedium),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _preferredLanguage,
                          items: _dropdownLanguages
                              .map(
                                (l) => DropdownMenuItem(
                                  value: l,
                                  child: Text(l, style: AppTheme.bodySmall),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(
                            () => _preferredLanguage = v ?? _preferredLanguage,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          GestureDetector(
            onTap: widget.onAskAnything,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 18,
              ),
              decoration: BoxDecoration(
                color: AppTheme.warningOrange.withAlpha(70),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppTheme.textBlack,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Tap the button and ask anything!",
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

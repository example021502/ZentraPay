import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:zentrapay_application/core/models/security.dart';
import 'package:zentrapay_application/core/models/voice_command.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/section_header.dart';
import 'package:zentrapay_application/core/utils/Common/format_date_time_string.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/Settings/repository/cache_settings_data.dart';
import 'package:zentrapay_application/features/zvoice/repository/cache_zvoice_data.dart';

/// ZVoice AI.
///
/// Three tabs under the shared [SectionHeader]:
///  * Talk     - speak (on-device speech-to-text) or type an instruction; the
///               transcript, how long it took and how sure the recogniser was
///               are sent to the backend, which answers and RECORDS it.
///  * Activity - the full history of everything said or typed, newest first,
///               with filters and the answer given for each.
///  * Safety   - instructions flagged as suspicious and the account's fraud
///               alerts.
class ZVoiceScreen extends StatefulWidget {
  const ZVoiceScreen({super.key});

  @override
  State<ZVoiceScreen> createState() => _ZVoiceScreenState();
}

enum _VoiceTab { talk, activity, safety }

class _ZVoiceScreenState extends State<ZVoiceScreen> {
  _VoiceTab _tab = _VoiceTab.talk;

  @override
  void initState() {
    super.initState();
    VoiceCommandHistoryRepository.instance.ensureLoaded().catchError(
      (_) => null,
    );
    VoiceFraudAlertsRepository.instance.ensureLoaded().catchError((_) => null);
    FraudAlertsRepository.instance.ensureLoaded().catchError((_) => null);
  }

  void _openHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        ),
        title: const Text("ZVoice AI"),
        content: const Text(
          "Tap the microphone and speak naturally, or type below, to check "
          "your balance or review recent payments. Every instruction and the "
          "answer you got is saved under Activity. ZVoice never asks for, and "
          "will never read out, your PIN or password.",
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

  Widget _tabStrip() {
    const labels = {
      _VoiceTab.talk: ("Talk", Icons.mic_rounded),
      _VoiceTab.activity: ("Activity", Icons.history_rounded),
      _VoiceTab.safety: ("Safety", Icons.shield_outlined),
    };
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.glassSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: _VoiceTab.values.map((tab) {
          final selected = tab == _tab;
          final (label, icon) = labels[tab]!;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = tab),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 17,
                      color: selected ? AppTheme.primaryPink : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: AppTheme.labelLarge.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? AppTheme.primaryPink : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          SectionHeader(
            title: "ZVoice AI",
            subtitle: "Speak or type. Every instruction is recorded.",
            icon: Icons.graphic_eq_rounded,
            showBack: true,
            actions: [
              SectionHeaderButton(
                icon: Icons.help_outline_rounded,
                onTap: _openHelp,
                tooltip: "Help",
              ),
            ],
            child: _tabStrip(),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab.index,
              children: const [_TalkTab(), _ActivityTab(), _SafetyTab()],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Talk
// ---------------------------------------------------------------------------

class _VoiceLanguage {
  final String label;
  final String code; // sent to the backend
  final String locale; // preferred speech-recognition locale

  const _VoiceLanguage(this.label, this.code, this.locale);
}

class _TalkTab extends StatefulWidget {
  const _TalkTab();

  @override
  State<_TalkTab> createState() => _TalkTabState();
}

class _TalkTabState extends State<_TalkTab>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static const _languages = [
    _VoiceLanguage('English', 'en', 'en_US'),
    _VoiceLanguage('French', 'fr', 'fr_FR'),
    _VoiceLanguage('Swahili', 'sw', 'sw_KE'),
    _VoiceLanguage('Twi', 'tw', 'ak_GH'),
    _VoiceLanguage('Hausa', 'ha', 'ha_NG'),
  ];

  static const _suggestions = [
    "What is my balance?",
    "Show my recent transactions",
    "Did I receive money today?",
  ];

  final SpeechToText _speech = SpeechToText();
  final TextEditingController _typed = TextEditingController();
  late final AnimationController _pulse;

  _VoiceLanguage _language = _languages.first;
  bool _ready = false;
  bool _listening = false;
  bool _submitting = false;
  bool _handled = true;
  String _heard = '';
  double _confidence = 0;
  DateTime? _startedAt;
  List<String> _deviceLocales = const [];
  VoiceCommandResult? _latest;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    _pulse.dispose();
    _typed.dispose();
    super.dispose();
  }

  Future<bool> _ensureSpeech() async {
    if (_ready) return true;
    try {
      _ready = await _speech.initialize(
        onStatus: _onStatus,
        onError: (error) {
          if (!mounted) return;
          if (_listening) _finishListening(error: error.errorMsg);
        },
      );
      if (_ready) {
        final locales = await _speech.locales();
        _deviceLocales = locales.map((l) => l.localeId).toList();
      }
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  String? _localeFor(_VoiceLanguage language) {
    final wanted = language.locale.toLowerCase().replaceAll('-', '_');
    for (final id in _deviceLocales) {
      if (id.toLowerCase().replaceAll('-', '_') == wanted) return id;
    }
    // Same language, other region (e.g. en_GB for English).
    final prefix = language.code.toLowerCase();
    for (final id in _deviceLocales) {
      if (id.toLowerCase().replaceAll('-', '_').startsWith('${prefix}_')) {
        return id;
      }
    }
    return null;
  }

  void _onStatus(String status) {
    if (!mounted) return;
    if ((status == 'done' || status == 'notListening') && _listening) {
      _finishListening();
    }
  }

  Future<void> _toggleMic() async {
    if (_submitting) return;
    if (_listening) {
      await _speech.stop();
      _finishListening();
      return;
    }
    HapticFeedback.lightImpact();
    final ok = await _ensureSpeech();
    if (!ok) {
      ZentraNotifier.error(
        "Microphone unavailable",
        "Allow microphone and speech access for ZentraPay in your phone "
            "settings, or type your instruction instead.",
      );
      return;
    }
    final locale = _localeFor(_language);
    if (locale == null && _language.code != 'en') {
      ZentraNotifier.notice(
        "${_language.label} voice isn't installed on this phone, using the default language",
        icon: Icons.translate_rounded,
      );
    }
    setState(() {
      _heard = '';
      _confidence = 0;
      _handled = false;
      _listening = true;
      _startedAt = DateTime.now();
    });
    _pulse.repeat(reverse: true);
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _heard = result.recognizedWords;
          if (result.finalResult) _confidence = result.confidence;
        });
        if (result.finalResult && _listening) _finishListening();
      },
      // ignore: deprecated_member_use
      localeId: locale,
      // ignore: deprecated_member_use
      listenFor: const Duration(seconds: 30),
      // ignore: deprecated_member_use
      pauseFor: const Duration(seconds: 4),
    );
  }

  /// Ends a listening session exactly once and records what was heard.
  void _finishListening({String? error}) {
    if (_handled) return;
    _handled = true;
    _pulse
      ..stop()
      ..value = 0;
    final text = _heard.trim();
    final millis = _startedAt == null
        ? null
        : DateTime.now().difference(_startedAt!).inMilliseconds;
    setState(() => _listening = false);
    if (text.isEmpty) {
      ZentraNotifier.notice(
        error == null || error.contains('no_match')
            ? "We didn't catch that. Tap the microphone and try again."
            : "Voice input stopped. Try again or type your instruction.",
        icon: Icons.mic_off_rounded,
      );
      return;
    }
    _submit(
      text,
      commandType: 'VOICE',
      durationMs: millis,
      confidence: _confidence > 0 ? _confidence : null,
    );
  }

  Future<void> _submit(
    String text, {
    required String commandType,
    int? durationMs,
    double? confidence,
  }) async {
    if (_submitting || text.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      final result = await VoiceCommandHistoryRepository.instance.sendCommand(
        commandType: commandType,
        transcript: text.trim(),
        language: _language.code,
        durationMs: durationMs,
        confidence: confidence,
      );
      if (!mounted) return;
      setState(() => _latest = result);
      if (commandType == 'CHAT') _typed.clear();
    } catch (e) {
      if (!mounted) return;
      ZentraNotifier.error("ZVoice", _messageOf(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _messageOf(Object e) {
    if (e is DioException && e.response?.data is Map) {
      final message = (e.response!.data as Map)['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return "We couldn't process that right now. Please try again.";
  }

  Widget _micButton() {
    final size = 128.0;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        return SizedBox(
          width: size + 60,
          height: size + 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_listening)
                Container(
                  width: size + 60 * t,
                  height: size + 60 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryPink.withValues(
                      alpha: 0.16 * (1 - t),
                    ),
                  ),
                ),
              child!,
            ],
          ),
        );
      },
      child: GestureDetector(
        onTap: _toggleMic,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPink.withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _submitting
              ? const Padding(
                  padding: EdgeInsets.all(44),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  _listening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: AppTheme.textBlack,
                  size: 54,
                ),
        ),
      ),
    );
  }

  Widget _languagePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_VoiceLanguage>(
          value: _language,
          icon: const Icon(Icons.translate_rounded, size: 18),
          items: _languages
              .map(
                (l) => DropdownMenuItem(
                  value: l,
                  child: Text(l.label, style: AppTheme.bodySmall),
                ),
              )
              .toList(),
          onChanged: _listening || _submitting
              ? null
              : (v) => setState(() => _language = v ?? _language),
        ),
      ),
    );
  }

  Widget _transcriptCard() {
    final text = _listening
        ? (_heard.isEmpty ? "Listening…" : _heard)
        : (_latest?.transcript ?? '');
    if (text.isEmpty) return const SizedBox.shrink();
    return _VoiceCard(
      icon: Icons.record_voice_over_outlined,
      title: _listening ? "Hearing you" : "You said",
      child: Text(text, style: AppTheme.bodyLarge),
    );
  }

  Widget _answerCard() {
    final latest = _latest;
    if (latest == null || _listening) return const SizedBox.shrink();
    final flagged = latest.fraudAlert;
    final reply = (latest.responseText ?? '').trim();
    return _VoiceCard(
      icon: flagged ? Icons.gpp_maybe_outlined : Icons.auto_awesome_outlined,
      title: flagged ? "Held for your safety" : "ZVoice says",
      color: flagged ? AppTheme.errorRed : AppTheme.brand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reply.isEmpty ? "No answer was returned for that." : reply,
            style: AppTheme.bodyLarge,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            "Saved to Activity · ${formatDateTimeString(latest.createdAt)}",
            style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingXs,
        AppTheme.spacingLg,
        AppTheme.spacingXl,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Language", style: AppTheme.labelLarge),
              _languagePicker(),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _micButton(),
          Text(
            _submitting
                ? "Working on it…"
                : _listening
                ? "Listening… tap to finish"
                : "Tap the microphone and speak",
            style: AppTheme.labelLarge,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _transcriptCard(),
          _answerCard(),
          const SizedBox(height: AppTheme.spacingMd),
          Align(
            alignment: Alignment.centerLeft,
            child: Text("Try asking", style: AppTheme.labelLarge),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map(
                  (s) => ActionChip(
                    label: Text(s, style: AppTheme.bodySmall),
                    onPressed: _submitting || _listening
                        ? null
                        : () => _submit(s, commandType: 'CHAT'),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _typed,
                  enabled: !_submitting && !_listening,
                  textInputAction: TextInputAction.send,
                  maxLength: 2000,
                  onSubmitted: (v) => _submit(v, commandType: 'CHAT'),
                  decoration: InputDecoration(
                    hintText: "Or type your instruction…",
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryPink,
                ),
                onPressed: _submitting || _listening
                    ? null
                    : () => _submit(_typed.text, commandType: 'CHAT'),
                icon: Icon(Icons.send_rounded, color: AppTheme.textBlack),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Color? color;

  const _VoiceCard({
    required this.icon,
    required this.title,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppTheme.brand;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTheme.labelSmall.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Activity (history)
// ---------------------------------------------------------------------------

enum _ActivityFilter { all, voice, typed, flagged }

class _ActivityTab extends StatefulWidget {
  const _ActivityTab();

  @override
  State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> {
  _ActivityFilter _filter = _ActivityFilter.all;

  bool _matches(VoiceCommandResult c) => switch (_filter) {
    _ActivityFilter.all => true,
    _ActivityFilter.voice => c.isVoice,
    _ActivityFilter.typed => !c.isVoice,
    _ActivityFilter.flagged => c.fraudAlert,
  };

  String _filterLabel(_ActivityFilter f) => switch (f) {
    _ActivityFilter.all => "All",
    _ActivityFilter.voice => "Voice",
    _ActivityFilter.typed => "Typed",
    _ActivityFilter.flagged => "Flagged",
  };

  Future<void> _refresh() async {
    try {
      await VoiceCommandHistoryRepository.instance.ensureLoaded(
        forceRefresh: true,
      );
    } catch (_) {
      // The error state is shown from the repository.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: VoiceCommandHistoryRepository.instance,
      builder: (context, _) {
        final repo = VoiceCommandHistoryRepository.instance;
        final all = repo.data ?? const <VoiceCommandResult>[];
        final items = all.where(_matches).toList();

        return Column(
          children: [
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                ),
                children: _ActivityFilter.values.map((f) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_filterLabel(f)),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: _body(repo, all, items),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _body(
    VoiceCommandHistoryRepository repo,
    List<VoiceCommandResult> all,
    List<VoiceCommandResult> items,
  ) {
    if (repo.isLoading && repo.data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (repo.error != null && repo.data == null) {
      return _EmptyState(
        icon: Icons.cloud_off_rounded,
        title: "Couldn't load your activity",
        message: "Pull down to try again.",
      );
    }
    if (items.isEmpty) {
      return _EmptyState(
        icon: Icons.history_rounded,
        title: all.isEmpty ? "Nothing here yet" : "No matches",
        message: all.isEmpty
            ? "Everything you say or type to ZVoice shows up here."
            : "Try another filter.",
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingSm,
        AppTheme.spacingLg,
        AppTheme.spacingXl,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _ActivityTile(command: items[i]),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final VoiceCommandResult command;

  const _ActivityTile({required this.command});

  String _intentLabel() {
    if (command.intent.isEmpty) return '';
    final words = command.intent.split('_');
    return words
        .map(
          (w) => w.isEmpty
              ? w
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final flagged = command.fraudAlert;
    final accent = flagged ? AppTheme.errorRed : AppTheme.brand;
    final reply = (command.responseText ?? '').trim();
    final meta = <String>[
      formatDateTimeString(command.createdAt),
      if (command.durationMs != null)
        "${(command.durationMs! / 1000).toStringAsFixed(1)}s",
      if (command.confidence != null)
        "${(command.confidence! * 100).round()}% sure",
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: flagged
              ? AppTheme.errorRed.withValues(alpha: 0.4)
              : AppTheme.dividerColor,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: accent.withValues(alpha: 0.12),
            child: Icon(
              flagged
                  ? Icons.gpp_maybe_outlined
                  : command.isVoice
                  ? Icons.mic_rounded
                  : Icons.keyboard_alt_outlined,
              color: accent,
              size: 20,
            ),
          ),
          title: Text(
            command.transcript,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.labelLarge,
          ),
          subtitle: Text(
            meta,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
          ),
          children: [
            if (_intentLabel().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  "${command.isVoice ? 'Spoken' : 'Typed'} · ${_intentLabel()}",
                  style: AppTheme.labelSmall.copyWith(color: accent),
                ),
              ),
            Text(
              reply.isEmpty ? "No answer was recorded." : reply,
              style: AppTheme.bodyMedium,
            ),
            if (flagged && (command.fraudReason ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                command.fraudReason!,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.errorRed),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Safety
// ---------------------------------------------------------------------------

class _SafetyTab extends StatelessWidget {
  const _SafetyTab();

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

  Future<void> _refresh() async {
    await Future.wait([
      VoiceFraudAlertsRepository.instance
          .ensureLoaded(forceRefresh: true)
          .catchError((_) => null),
      FraudAlertsRepository.instance.ensureLoaded().catchError((_) => null),
    ]);
  }

  Widget _section(String title, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.headlineSmall),
        const SizedBox(height: AppTheme.spacingSm),
        child,
      ],
    ),
  );

  Widget _row({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelLarge,
                ),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingLg,
          AppTheme.spacingSm,
          AppTheme.spacingLg,
          AppTheme.spacingXl,
        ),
        children: [
          _section(
            "Flagged instructions",
            ListenableBuilder(
              listenable: VoiceFraudAlertsRepository.instance,
              builder: (context, _) {
                final repo = VoiceFraudAlertsRepository.instance;
                if (repo.isLoading && repo.data == null) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final flagged = repo.data ?? const <VoiceCommandResult>[];
                if (flagged.isEmpty) {
                  return Text(
                    repo.error != null
                        ? "Couldn't load flagged instructions. Pull down to retry."
                        : "Nothing suspicious. Your ZVoice activity looks normal.",
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.gray500,
                    ),
                  );
                }
                return Column(
                  children: flagged
                      .map(
                        (c) => _row(
                          icon: Icons.gpp_maybe_outlined,
                          color: AppTheme.errorRed,
                          title: c.fraudReason?.isNotEmpty == true
                              ? c.fraudReason!
                              : c.transcript,
                          subtitle: formatDateTimeString(c.createdAt),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
          _section(
            "Account alerts",
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
                final List<FraudAlert> alerts = repo.data ?? const [];
                if (alerts.isEmpty) {
                  return Text(
                    "No fraud alerts. You're all clear.",
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.gray500,
                    ),
                  );
                }
                return Column(
                  children: alerts
                      .map(
                        (a) => _row(
                          icon: a.isResolved
                              ? Icons.check_rounded
                              : Icons.warning_rounded,
                          color: a.isResolved
                              ? AppTheme.successGreen
                              : _severityColor(a.severity),
                          title: _humanize(a.alertType),
                          subtitle:
                              "${a.isResolved ? 'Secure' : a.severity} · ${formatDateTimeString(a.createdAt)}",
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/fraud_detection'),
            icon: const Icon(Icons.shield_outlined),
            label: const Text("Open Security Alerts"),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 60),
        Icon(icon, size: 52, color: AppTheme.textBlack),
        const SizedBox(height: AppTheme.spacingMd),
        Center(child: Text(title, style: AppTheme.headlineSmall)),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
          ),
        ),
      ],
    );
  }
}

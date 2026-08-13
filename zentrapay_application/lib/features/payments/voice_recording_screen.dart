import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/repositories/voice_command_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

class VoiceRecordingScreen extends StatefulWidget {
  const VoiceRecordingScreen({super.key});

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen> {
  bool isRecording = false;

  // On-device speech-to-text isn't wired up yet (no transcription package in
  // this app), so a stopped recording is logged as a voice session with the
  // backend rather than fabricating transcript text. There's no client-side
  // fraud heuristic on this screen, so fraudAlert/fraudReason are left at
  // their defaults (false/none) rather than fabricated.
  Future<void> _onRecordingStopped() async {
    try {
      await VoiceCommandHistoryRepository.instance.sendCommand(
        commandType: 'VOICE',
        transcript: '(no transcription available)',
      );
    } catch (_) {
      // Best-effort — recording UI state already reflects the stop.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.main,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Voice Recording",
          style: TextStyle(color: AppColors.primary, fontSize: 18),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Tap",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                final wasRecording = isRecording;
                setState(() => isRecording = !isRecording);
                if (wasRecording) {
                  _onRecordingStopped();
                }
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.main,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withAlpha(100),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: Icon(
                    Icons.mic,
                    size: 80,
                    color: isRecording ? AppColors.main : AppColors.main,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/ai_assistance'),
              icon: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat, color: AppColors.main, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

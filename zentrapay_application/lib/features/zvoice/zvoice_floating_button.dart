import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

/// Floating, glowing launcher for ZVoice AI — sits bottom-right on the Home
/// tab, just above the curved bottom navigation bar, and pulses continuously
/// to invite a tap. Positioned by the caller (see [HomeWalletMain]); this
/// widget only owns the glow animation and the tap-to-navigate behavior.
class ZVoiceFloatingButton extends StatefulWidget {
  const ZVoiceFloatingButton({super.key});

  @override
  State<ZVoiceFloatingButton> createState() => _ZVoiceFloatingButtonState();
}

class _ZVoiceFloatingButtonState extends State<ZVoiceFloatingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/zvoice');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPink.withValues(alpha: 0.45 + 0.3 * t),
                  blurRadius: 10 * t,
                  spreadRadius: 1 * t,
                ),
              ],
            ),
            child: child,
          );
        },
        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

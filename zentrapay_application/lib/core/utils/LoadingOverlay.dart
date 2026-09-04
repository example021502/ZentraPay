import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

/// The app's one full-screen "processing, please wait" barrier.
///
/// Show it the moment a not-safe-to-repeat action starts — a payment
/// submit, a PIN verify, anything else where a double-tap or switching to
/// another option mid-flight would be a problem — and hide it once the
/// action settles (prefer [run], which does this in a `finally`).
///
/// One instance for the whole app: mounted once above the Navigator in
/// `main.dart` via [LoadingOverlay.wrap], so any screen can trigger it with
/// a static call instead of every screen wiring up its own `_loading` flag
/// and overlay widget.
class LoadingOverlay {
  LoadingOverlay._();

  static final ValueNotifier<String?> _message = ValueNotifier<String?>(null);

  static bool get isShowing => _message.value != null;

  static void show([String message = 'Please wait…']) {
    _message.value = message;
  }

  static void hide() {
    _message.value = null;
  }

  /// Runs [task] with the overlay shown for its duration, guaranteeing it's
  /// hidden again even if [task] throws — the standard shape for "submit
  /// and wait for the result" actions (see makePayment.dart / SendingForm).
  static Future<T> run<T>(
    Future<T> Function() task, {
    String message = 'Please wait…',
  }) async {
    show(message);
    try {
      return await task();
    } finally {
      hide();
    }
  }

  /// Wrap the app's Navigator with this once — see `MaterialApp.builder` in
  /// main.dart — so show()/hide()/run() work from any screen.
  static Widget wrap(Widget child) => _LoadingOverlayScope(child: child);
}

class _LoadingOverlayScope extends StatelessWidget {
  final Widget child;

  const _LoadingOverlayScope({required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: LoadingOverlay._message,
      builder: (context, message, _) {
        return Material(
          child: Stack(
            children: [
              child,
              if (message != null)
                Positioned.fill(
                  child: AbsorbPointer(
                    // Blocks every tap on the screen underneath — the point of
                    // this overlay — while still painting over it.
                    absorbing: true,
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.45),
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingXxl,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingXl,
                            vertical: AppTheme.spacingLg,
                          ),
                          decoration: AppTheme.cardDecoration,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: AppTheme.primaryPink,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingMd),
                              Text(
                                message,
                                textAlign: TextAlign.center,
                                style: AppTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

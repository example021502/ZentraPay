import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';

/// Stops a single back press from closing the app.
///
/// While the wrapped screen is the only route on the stack (the Home shell
/// after login, or the login screen after a logout) the first back press shows
/// a light "tap back again" notice and only a second press within [window]
/// closes the app. When another route sits underneath, back behaves normally.
///
/// [onBack] lets the host consume the first press for something more useful
/// than the notice — the Home shell uses it to return to the Home tab. Return
/// `true` when the press was handled.
class DoubleBackToExit extends StatefulWidget {
  final Widget child;
  final bool Function()? onBack;
  final Duration window;

  const DoubleBackToExit({
    super.key,
    required this.child,
    this.onBack,
    this.window = const Duration(seconds: 2),
  });

  @override
  State<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<DoubleBackToExit> {
  DateTime? _lastBackPress;

  void _handleBack() {
    if (widget.onBack?.call() ?? false) return;

    final now = DateTime.now();
    final last = _lastBackPress;
    if (last != null && now.difference(last) <= widget.window) {
      SystemNavigator.pop();
      return;
    }
    _lastBackPress = now;
    ZentraNotifier.notice(
      'Tap back again to close the app',
      icon: Icons.exit_to_app_rounded,
      duration: widget.window,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only take over when there is nothing underneath to go back to.
    final isRoot = ModalRoute.of(context)?.isFirst ?? true;

    return PopScope(
      canPop: !isRoot,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: widget.child,
    );
  }
}

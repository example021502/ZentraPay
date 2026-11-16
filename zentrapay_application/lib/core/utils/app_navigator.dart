import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/core/utils/session_reset.dart';

/// The app's root navigator, so code without a BuildContext (the HTTP layer) can change screens.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

bool _endingSession = false;

/// The server refused to renew the session (token revoked, account closed, 30 days passed):
/// forget the signed-in user and send them to the login screen. Safe to call from many
/// failing requests at once - only the first one acts.
Future<void> endSessionAndShowLogin() async {
  if (_endingSession) return;
  _endingSession = true;
  try {
    await resetUserSession();
    appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (_) => false,
    );
    ZentraNotifier.error(
      'Session expired',
      'Please sign in again to continue.',
    );
  } finally {
    _endingSession = false;
  }
}

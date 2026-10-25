import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/main.dart';

/// What the user sees whenever something fails and we have nothing safe to say.
const String kGenericErrorMessage =
    'Something went wrong. Please try again in a moment.';

/// What the user sees when the request never reached the server.
const String kConnectionErrorMessage =
    "We couldn't reach Zentrapay. Check your internet connection and try again.";

/// Words that mean a message was written for developers, not customers:
/// exception types, HTTP/transport details, database and framework names, and
/// the third-party providers we run on. A message containing any of them is
/// swapped for a generic one before it reaches the screen.
const List<String> _technicalMarkers = [
  'exception',
  'stacktrace',
  'stack trace',
  'dioerror',
  'xmlhttprequest',
  'socketexception',
  'handshake',
  'status code',
  'http status',
  'statuscode',
  'errno',
  'null check',
  'is not a subtype',
  'nosuchmethod',
  'type \'',
  'sql',
  'jdbc',
  'hibernate',
  'spring',
  'database',
  'localhost',
  '127.0.0.1',
  'connection refused',
  'connection error',
  'connection timeout',
  'timed out',
  'jwt',
  'bearer',
  'afriqlink',
  'paystack',
  'flutterwave',
  'onafriq',
  'privy',
  'gateway',
  'endpoint',
  'null pointer',
  'nullpointer',
  'internal server error',
  'bad gateway',
  '<html',
  '{"',
];

/// Turns any error text into something safe to show a customer.
///
/// Business messages written for users ("You have already linked this bank",
/// "Insufficient balance") pass through untouched. Anything that exposes how
/// the system is built — exceptions, status codes, SQL, provider names — is
/// replaced, so a failure never leaks the technical makeup of the app.
String friendlyMessage(String? raw, {String fallback = kGenericErrorMessage}) {
  final text = (raw ?? '').trim();
  if (text.isEmpty) return fallback;

  final lower = text.toLowerCase();
  if (lower.contains('socket') ||
      lower.contains('connection') ||
      lower.contains('network') ||
      lower.contains('timed out') ||
      lower.contains('timeout') ||
      lower.contains('could not connect')) {
    return kConnectionErrorMessage;
  }
  if (text.length > 160 || _technicalMarkers.any(lower.contains)) {
    return fallback;
  }
  return text;
}

/// Customer-safe text for any caught error. A failed request shows the
/// server's own business message (made safe by [friendlyMessage]); a request
/// that never arrived shows the connection message; everything else — a
/// thrown `Exception`, a parsing error — shows [fallback].
String errorMessage(Object? error, {String fallback = kGenericErrorMessage}) {
  if (error is DioException) {
    final body = error.response?.data;
    if (body is Map && body['message'] is String) {
      return friendlyMessage(body['message'] as String, fallback: fallback);
    }
    if (error.response == null) return kConnectionErrorMessage;
    return fallback;
  }
  // A plain `throw Exception('Insufficient balance')` carries a message meant
  // for the user; anything technical is still masked by [friendlyMessage].
  final text = (error ?? '').toString().replaceFirst(
    RegExp(r'^(Exception|Error): '),
    '',
  );
  return friendlyMessage(text, fallback: fallback);
}

class ZentraNotifier {
  static void success(String title, String message) {
    toastification.show(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      alignment: Alignment.topLeft,
      dragToClose: true,
      showIcon: true,
      icon: Icon(Icons.check_circle_sharp, size: 30, color: AppColors.green),
      foregroundColor: AppTheme.brand,
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      // Matches banking app themes
      title: Text(
        title,
        style: AppStyles.header.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      description: Text(
        message,
        style: AppStyles.text.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textBlack,
        ),
      ),

      // autoCloseDuration: const Duration(seconds: 3),
      primaryColor: AppTheme.surface,
      backgroundColor: AppTheme.surface,
      borderRadius: BorderRadius.circular(20),
    );
  }

  static void error(String title, String message) {
    toastification.show(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      alignment: Alignment.topLeft,
      showIcon: true,
      dragToClose: true,
      icon: Icon(Icons.cancel_outlined, size: 30, color: AppTheme.errorRed),
      foregroundColor: AppTheme.brand,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      // Matches banking app themes
      title: Text(
        title,
        style: AppStyles.header.copyWith(color: AppColors.main, fontSize: 16),
      ),
      description: Text(
        friendlyMessage(message),
        style: AppStyles.text.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textBlack,
        ),
      ),
      // autoCloseDuration: const Duration(seconds: 3),
      primaryColor: AppTheme.surface,
      backgroundColor: AppTheme.surface,
      borderRadius: BorderRadius.circular(20),
    );
  }

  static void warning(String title, String message) {
    toastification.show(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      alignment: Alignment.topLeft,
      showIcon: true,
      dragToClose: true,
      icon: Icon(Icons.warning, size: 30, color: AppColors.orange),
      foregroundColor: AppTheme.brand,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      // Matches banking app themes
      title: Text(
        title,
        style: AppStyles.header.copyWith(color: AppColors.main, fontSize: 16),
      ),
      description: Text(
        friendlyMessage(message),
        style: AppStyles.text.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textBlack,
        ),
      ),
      // autoCloseDuration: const Duration(seconds: 3),
      primaryColor: AppTheme.surface,
      backgroundColor: AppTheme.surface,
      borderRadius: BorderRadius.circular(20),
    );
  }

  /// A small, light, self-dismissing pill at the bottom of the screen — for
  /// passing information that doesn't deserve a full titled toast ("tap back
  /// again to exit", "that service isn't available yet", "your change could
  /// not be saved").
  static void notice(
    String message, {
    IconData icon = Icons.info_outline_rounded,
    Duration duration = const Duration(seconds: 2),
  }) {
    toastification.show(
      alignment: Alignment.bottomCenter,
      autoCloseDuration: duration,
      dragToClose: true,
      showProgressBar: false,
      showIcon: true,
      icon: Icon(icon, size: 22, color: AppTheme.textBlack),
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 110),
      primaryColor: AppTheme.brand,
      backgroundColor: AppTheme.surface,
      foregroundColor: AppTheme.textBlack,
      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      title: Text(
        friendlyMessage(message),
        style: AppStyles.text.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textBlack,
        ),
      ),
    );
  }
}

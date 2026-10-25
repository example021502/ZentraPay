import 'package:flutter/widgets.dart';
import 'package:privy_flutter/src/logging/privy_log_level_enum.dart';
import 'privy_logger.dart';

/// Concrete implementation of the PrivyLogger interface.
/// Handles log level filtering and internal log handling without timestamps.
class RealPrivyLogger implements PrivyLogger {
  final PrivyLogLevel level; // Current log level set during SDK initialization
  final String appId; // Unique app ID for determining internal log access

  /// Whitelist of internal app IDs that receive internal logs
  static const List<String> _internalAppIds = ["cm5vced3p01l4o5g3dyyinnd0"];

  /// Determines if logs should be printed based on the log level.
  bool get _shouldLog => level != PrivyLogLevel.none;

  /// Determines if internal logs should be printed for the current app ID.
  bool get _canLogInternal => _internalAppIds.contains(appId);

  /// Constructor to initialize logger with a given log level and app ID.
  RealPrivyLogger({
    required this.level,
    required this.appId,
  });

  /// Directly prints the log message without formatting.
  void _log(String message) {
    if (_shouldLog) {
      debugPrint("Privy: $message");
    }
  }

  @override
  void debug(String message) {
    if (level == PrivyLogLevel.verbose || level == PrivyLogLevel.debug) {
      _log(message);
    }
  }

  @override
  void info(String message) {
    if (level == PrivyLogLevel.verbose || level == PrivyLogLevel.info) {
      _log(message);
    }
  }

  @override
  void warning(String message) {
    if (level == PrivyLogLevel.verbose || level == PrivyLogLevel.warning) {
      _log(message);
    }
  }

  @override
  void error(String message) {
    if (level == PrivyLogLevel.verbose || level == PrivyLogLevel.error) {
      _log(message);
    }
  }

  @override
  void internal(String message) {
    if (_canLogInternal &&
        (level == PrivyLogLevel.verbose || level == PrivyLogLevel.error)) {
      _log(message);
    }
  }
}

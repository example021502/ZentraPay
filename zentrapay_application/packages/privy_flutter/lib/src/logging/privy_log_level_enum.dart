/// Represents the logging levels for the Privy SDK.
enum PrivyLogLevel {
  /// No logs.
  none,

  /// Debug level logs.
  debug,

  /// Informational logs.
  info,

  /// Warning level logs.
  warning,

  /// Error level logs.
  error,

  /// Logs everything.
  verbose;

  /// Convert enum to string for platform channels
  String toNativeString() {
    return name.toUpperCase();
  }
}

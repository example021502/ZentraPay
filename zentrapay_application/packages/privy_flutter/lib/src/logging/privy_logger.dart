/// Abstract logger interface for internal logging within the Privy plugin.
/// This serves as a contract for any logger implementations.
abstract class PrivyLogger {
  /// Logs a debug-level message.
  void debug(String message);

  /// Logs an informational message.
  void info(String message);

  /// Logs a warning message.
  void warning(String message);

  /// Logs an error message without including an exception.
  void error(String message);

  /// Logs internal messages restricted to whitelisted app IDs.
  void internal(String message);
}

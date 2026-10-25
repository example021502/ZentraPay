import 'package:privy_flutter/src/logging/privy_logger.dart';

class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  static late PrivyLogger _logger;

  LoggerService._internal();

  factory LoggerService() {
    return _instance;
  }

  static void initializeLogger(PrivyLogger logger) {
    _logger = logger;
  }

  static void debug(String message) => _logger.debug(message);
  static void info(String message) => _logger.info(message);
  static void warning(String message) => _logger.warning(message);
  static void error(String message) => _logger.error(message);
  static void internal(String message) => _logger.internal(message);
}

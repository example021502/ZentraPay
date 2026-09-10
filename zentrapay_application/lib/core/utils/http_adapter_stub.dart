import 'package:dio/dio.dart';

/// Fallback stub (should never be used — one of the conditional imports above
/// always matches). Throws so a misconfiguration fails loudly.
HttpClientAdapter createHttpAdapter() {
  throw UnsupportedError('No HTTP adapter available for this platform');
}

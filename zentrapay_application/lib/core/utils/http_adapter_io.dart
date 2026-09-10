import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Native/desktop adapter: trusts the dev self-signed TLS cert.
HttpClientAdapter createHttpAdapter() {
  return IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        // Comment: Accept all certificates for development environment
        return true;
      };
      return client;
    },
  );
}

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Native/desktop adapter.
///
/// The development backend uses a self-signed TLS certificate, so a certificate that fails
/// validation is accepted ONLY when the server is on this machine or on a private network
/// (localhost, 10.x, 172.16-31.x, 192.168.x, 169.254.x). A public host - the real production
/// API - always gets full certificate validation, in every build mode.
HttpClientAdapter createHttpAdapter() {
  return IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => _isLocalHost(host);
      return client;
    },
  );
}

bool _isLocalHost(String host) {
  if (host == 'localhost') return true;
  final address = InternetAddress.tryParse(host);
  if (address == null) return false;
  if (address.isLoopback) return true;
  if (address.type != InternetAddressType.IPv4) return false;
  final o = address.rawAddress;
  return o[0] == 10 ||
      (o[0] == 172 && o[1] >= 16 && o[1] <= 31) ||
      (o[0] == 192 && o[1] == 168) ||
      (o[0] == 169 && o[1] == 254);
}

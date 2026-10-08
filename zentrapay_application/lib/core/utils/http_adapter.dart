import 'package:dio/dio.dart';

/// Returns the platform-appropriate Dio HTTP adapter.
///
/// Implemented with a conditional import so `dart:io` is never compiled into
/// the web build (where it doesn't exist), while native/desktop keep trusting
/// the dev self-signed TLS cert.
import 'http_adapter_stub.dart'
    if (dart.library.io) 'http_adapter_io.dart'
    if (dart.library.html) 'http_adapter_web.dart' as impl;

HttpClientAdapter createHttpAdapter() => impl.createHttpAdapter();

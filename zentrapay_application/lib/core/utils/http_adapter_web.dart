import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// Web adapter: the browser owns TLS, so Dio's default browser adapter is used.
HttpClientAdapter createHttpAdapter() => BrowserHttpClientAdapter();

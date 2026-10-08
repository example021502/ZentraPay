import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zentrapay_application/core/utils/http_adapter.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';

class ApiClient {
  // Comment: Create a private static instance of the class
  static final ApiClient _instance = ApiClient._internal();

  // Comment: Expose a public factory constructor that always returns the same instance
  factory ApiClient() => _instance;

  late final Dio dio;

  // Comment: Private, internal constructor that sets up our HTTP client configurations
  ApiClient._internal() {
    BaseOptions options = BaseOptions(
      // Comment: Default base URL points directly to the Spring Boot backend
      // (server.port=2000 in application.properties; overridden by .env BASE_URL).
      baseUrl: dotenv.get('BASE_URL', fallback: "https://localhost:2000"),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: Headers.jsonContentType,
    );

    dio = Dio(options);

    // Comment: Accept self-signed certificates using the updated createHttpClient property.
    // Web has no dart:io HttpClient, so the adapter is chosen per-platform in
    // http_adapter.dart. On native/desktop this trusts the dev self-signed TLS
    // cert; on web the browser owns TLS (install the mkcert CA / accept the
    // warning instead).
    dio.httpClientAdapter = createHttpAdapter();

    // Comment: Attach our global interceptors for security and platform tracking
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Comment: Identify the platform source for server logs
          options.headers['X-Client-Platform'] = 'zentrapay_application.com';

          // Comment: Fetch the active user's authorization session token asynchronously from secure storage
          String? token = SecureStorageService.getToken();
          // Comment: Inject the JWT token into the headers if the user is authenticated
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Comment: Catch global errors here (like 401 unauthenticated drops)
          return handler.next(e);
        },
      ),
    );
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zentrapay_application/core/utils/app_navigator.dart';
import 'package:zentrapay_application/core/utils/http_adapter.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';

// Sign-in / sign-up / renew answer 401 for wrong credentials: those must never trigger a refresh
bool _isAuthCall(String path) =>
    path.startsWith('/api/users/login') ||
    path.startsWith('/api/users/register') ||
    path.startsWith('/api/users/refresh');

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
        onError: (DioException e, handler) async {
          // A 401 on a signed-in request means the token expired (the app can stay open longer
          // than a token lives). Renew it once and replay the request so the user never notices.
          final request = e.requestOptions;
          final expired = e.response?.statusCode == 401 &&
              !_isAuthCall(request.path) &&
              request.extra['tokenRetried'] != true &&
              (SecureStorageService.getToken()?.isNotEmpty ?? false);
          if (!expired) return handler.next(e);

          final renewed = await SecureStorageService.refreshToken();
          if (renewed == false) {
            // The server itself refused to renew: the session is really over
            await endSessionAndShowLogin();
            return handler.next(e);
          }
          // null = could not reach the server, so nothing is known: keep the user signed in.
          // A multipart upload cannot be sent twice; the user simply retries it.
          if (renewed != true || request.data is FormData) return handler.next(e);

          try {
            request.extra['tokenRetried'] = true;
            request.headers['Authorization'] =
                'Bearer ${SecureStorageService.getToken()}';
            return handler.resolve(await dio.fetch(request));
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        },
      ),
    );
  }
}

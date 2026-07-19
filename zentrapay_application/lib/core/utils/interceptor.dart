import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';

class ApiClient {
  // 1. Create a private static instance of the class
  static final ApiClient _instance = ApiClient._internal();

  // 2. Expose a public factory constructor that always returns the same instance
  factory ApiClient() => _instance;

  late final Dio dio;

  // 3. Private, internal constructor that sets up our HTTP client configurations
  ApiClient._internal() {
    BaseOptions options = BaseOptions(
      // Default base URL points directly to your backend application server
      baseUrl: dotenv.get('BASE_URL', fallback: "http://10.155.83.125:5000/"),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: Headers.jsonContentType,
    );

    dio = Dio(options);

    // Attach our global interceptors for security and platform tracking
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Identify the platform source for server logs
          options.headers['X-Client-Platform'] = 'Flutter-Mobile';

          // Fetch the active user's authorization session token
          String? token = await SecureStorageService.getToken();

          // Inject the JWT token into the headers if the user is authenticated
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // You can catch global errors here (like 401 unauthenticated drops)
          return handler.next(e);
        },
      ),
    );
  }
}

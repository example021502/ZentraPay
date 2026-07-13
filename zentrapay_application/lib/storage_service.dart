import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zentrapay_application/Notifier.dart';
import 'package:zentrapay_application/interceptor.dart';

class SecureStorageService {
  // Instantiate the storage reference globally within this helper class
  static const _secureStorage = FlutterSecureStorage();

  // Save the authentication token string securely
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  // Retrieve the saved token when configuring requests
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  // Wipe the token clear during a logout routine
  static Future<void> deleteToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }

  static Future<void> refreshToken() async {
    final dio = ApiClient().dio;

    Future<void> refresh() async {
      try {
        final result = await dio.post('/api/refreshToken');

        if (!result.data["success"]) {
          ZentraNotifier.error(
            "Authentication Error",
            "Something went wrong: ${result.data["message"]}",
          );
        }

        final newToken = result.data["token"];
        if (newToken != null) {
          await deleteToken();
          await saveToken(newToken);
          ZentraNotifier.success("Success", "Token refreshed!");
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          ZentraNotifier.error(
            "Token Error",
            "Something went wrong: ${e.response?.data["message"]}",
          );
        } else {
          ZentraNotifier.error(
            "Unknown Error",
            "Something went wrong: ${e.response?.data["message"]}",
          );
        }
        rethrow;
      }
    }

    await refresh();
  }
}

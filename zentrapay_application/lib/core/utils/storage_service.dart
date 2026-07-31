import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

class SecureStorageService {
  // Instantiate the storage reference globally within this helper class
  static const _secureStorage = FlutterSecureStorage();
  static String? _memoryToken;

  static Future<void> init() async {
    _memoryToken = await _secureStorage.read(key: "auth_token");
  }

  // Save the authentication token string securely
  static Future<void> saveToken(String token) async {
    _memoryToken = token;
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  // Retrieve the saved token when configuring requests
  static String? getToken() => _memoryToken;

  // Decode the cached JWT's "sub" claim to get the signed-in user's own
  // userId, without a round trip to /api/users/me.
  static String? getUserId() {
    final token = getToken();
    if (token == null) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final normalized = base64Url.normalize(parts[1]);
      final payload = json.decode(utf8.decode(base64Url.decode(normalized)));
      return payload['sub'] as String?;
    } catch (e) {
      debugPrint("ERROR decoding token payload:: $e");
      return null;
    }
  }

  // Wipe the token clear during a logout routine
  static Future<void> deleteToken() async {
    _memoryToken = null;
    await _secureStorage.delete(key: 'auth_token');
  }

  static Future<void> refreshToken() async {
    final dio = ApiClient().dio;

    Future<void> refresh() async {
      try {
        final result = await dio.post(
          '/api/users/refresh',
          options: Options(
            headers: {"Authorization": "Bearer ${getToken()}"},
          ),
        );

        debugPrint("REFRESH TOKEN:: $result");
        if (!result.data['success']) {
          return debugPrint("ERROR:: ${result.data['message']}");
        }
        final newToken = result.data["data"]["token"];
        await deleteToken();
        await saveToken(newToken);
        ZentraNotifier.success("Success", "Token refreshed!");
      } on DioException catch (e) {
        debugPrint("ERROR:: $e");
        rethrow;
      }
    }

    await refresh();
  }
}

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

  // ============================================================================
  // Customer Data Storage (for Paystack/Flutterwave failover persistence)
  // ============================================================================

  static const String _customerGatewayKey = 'customer_gateway';
  static const String _customerCustomerIdKey = 'customer_customer_id';
  static const String _customerEmailKey = 'customer_email';
  static const String _customerDisplayNameKey = 'customer_display_name';
  static const String _customerPhoneKey = 'customer_phone';
  static const String _customerMetadataKey = 'customer_metadata';

  /// Saves the gateway customer result to secure storage after successful
  /// customer creation (either primary Paystack or failover Flutterwave).
  ///
  /// [metadata] is JSON-encoded before being written, so any value that
  /// isn't natively JSON-encodable (model objects, for instance) is coerced
  /// to its `toString()` form first — `json.encode` would otherwise throw
  /// and abort the whole save.
  static Future<void> saveCustomer({
    required String gateway,
    required String customerId,
    required String email,
    required String displayName,
    required String phone,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      await _secureStorage.write(key: _customerGatewayKey, value: gateway);
      await _secureStorage.write(
        key: _customerCustomerIdKey,
        value: customerId,
      );
      await _secureStorage.write(key: _customerEmailKey, value: email);
      await _secureStorage.write(key: _customerDisplayNameKey, value: displayName);
      await _secureStorage.write(key: _customerPhoneKey, value: phone);
      await _secureStorage.write(
        key: _customerMetadataKey,
        value: json.encode(_jsonSafeMap(metadata)),
      );
      debugPrint('Customer data saved to secure storage successfully');
    } catch (e) {
      debugPrint('Failed to save customer data: $e');
      rethrow;
    }
  }

  /// Recursively coerces [value] into something `json.encode` accepts.
  ///
  /// Maps and lists are walked; primitives pass through; anything else
  /// (custom model instances, for example) falls back to `toString()`.
  static Object? _jsonSafeValue(Object? value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }
    if (value is Map) {
      return _jsonSafeMap(Map<String, dynamic>.from(value));
    }
    if (value is Iterable) {
      return value.map(_jsonSafeValue).toList();
    }
    return value.toString();
  }

  /// Applies [_jsonSafeValue] to every entry of [map].
  static Map<String, dynamic> _jsonSafeMap(Map<String, dynamic> map) {
    return map.map((key, value) => MapEntry(key, _jsonSafeValue(value)));
  }

  /// Retrieves the gateway customer result from secure storage.
  ///
  /// [FlutterSecureStorage.read] is asynchronous, so this returns a Future.
  /// Returns `null` when nothing has been persisted yet.
  static Future<Map<String, String>?> getCustomer() async {
    try {
      final Map<String, String?> data = {
        'gateway': await _secureStorage.read(key: _customerGatewayKey),
        'customerId': await _secureStorage.read(key: _customerCustomerIdKey),
        'email': await _secureStorage.read(key: _customerEmailKey),
        'displayName': await _secureStorage.read(key: _customerDisplayNameKey),
        'phone': await _secureStorage.read(key: _customerPhoneKey),
        'metadata': await _secureStorage.read(key: _customerMetadataKey),
      };

      // Filter out null values and return only meaningful data
      final Map<String, String> result = {};
      for (final entry in data.entries) {
        if (entry.value != null) {
          result[entry.key] = entry.value!;
        }
      }
      return result.isNotEmpty ? result : null;
    } catch (e) {
      debugPrint('Failed to get customer data: $e');
      return null;
    }
  }

  /// Clears the saved customer data from secure storage.
  static Future<void> clearCustomer() async {
    try {
      await _secureStorage.delete(key: _customerGatewayKey);
      await _secureStorage.delete(key: _customerCustomerIdKey);
      await _secureStorage.delete(key: _customerEmailKey);
      await _secureStorage.delete(key: _customerDisplayNameKey);
      await _secureStorage.delete(key: _customerPhoneKey);
      await _secureStorage.delete(key: _customerMetadataKey);
      debugPrint('Customer data cleared from secure storage');
    } catch (e) {
      debugPrint('Failed to clear customer data: $e');
      rethrow;
    }
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

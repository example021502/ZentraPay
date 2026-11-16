import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:zentrapay_application/core/utils/http_adapter.dart';
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

  // Wipe the token clear during a logout routine. The signed-in user's
  // identity goes with it so the next account never sees a stale name.
  static Future<void> deleteToken() async {
    _memoryToken = null;
    _memorySession = null;
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: _sessionKey);
  }

  // ============================================================================
  // Signed-in user identity (returned by login / register alongside the token)
  // ============================================================================

  static const String _sessionKey = 'auth_session';
  static Map<String, String>? _memorySession;

  /// Saves the identity the backend returns next to the token — userId, email,
  /// firstName, lastName — so it survives restarts and any screen can read it
  /// without being handed route arguments.
  static Future<void> saveSession(Map<String, dynamic> userData) async {
    String field(String key) => (userData[key] ?? '').toString();
    final session = {
      'userId': field('userId'),
      'email': field('email'),
      'firstName': field('firstName'),
      'lastName': field('lastName'),
    };
    _memorySession = session;
    await _secureStorage.write(key: _sessionKey, value: json.encode(session));
  }

  /// The claims inside the cached JWT (userId is the `sub` claim), or an empty
  /// map when there is no readable token.
  static Map<String, dynamic> _tokenClaims() {
    final token = getToken();
    if (token == null) return const {};
    try {
      final parts = token.split('.');
      if (parts.length != 3) return const {};
      final normalized = base64Url.normalize(parts[1]);
      final payload = json.decode(utf8.decode(base64Url.decode(normalized)));
      return payload is Map ? Map<String, dynamic>.from(payload) : const {};
    } catch (e) {
      debugPrint("ERROR decoding token payload:: $e");
      return const {};
    }
  }

  /// The signed-in user's identity: userId, email, firstName, lastName.
  ///
  /// Taken from the saved login / register response, and from the token's own
  /// claims for anything missing. A saved identity that belongs to a different
  /// user than the current token is ignored, so one account's name can never
  /// show up under another's token.
  static Map<String, String> getSession() {
    final claims = _tokenClaims();
    final tokenUserId = (claims['sub'] ?? '').toString();
    var saved = _memorySession ?? const <String, String>{};
    final savedUserId = saved['userId'] ?? '';
    if (tokenUserId.isNotEmpty &&
        savedUserId.isNotEmpty &&
        savedUserId != tokenUserId) {
      saved = const {};
    }
    String pick(String key, String claim) {
      final value = saved[key];
      if (value != null && value.isNotEmpty) return value;
      return (claims[claim] ?? '').toString();
    }

    final session = {
      'userId': pick('userId', 'sub'),
      'phoneNumber': pick('phoneNumber', 'phoneNumber'),
      'countryCode': pick('countryCode', 'countryCode'),
      'userType': pick('userType', 'userType'),
      'firstName': pick('firstName', 'firstName'),
      'lastName': pick('lastName', 'lastName'),
    };
    if (session.values.every((v) => v.isEmpty)) return const {};
    return session;
  }

  /// Loads the saved identity into memory. Call once at start-up.
  static Future<void> loadSession() async {
    try {
      final raw = await _secureStorage.read(key: _sessionKey);
      if (raw == null) return;
      final decoded = json.decode(raw) as Map<String, dynamic>;
      _memorySession = decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (e) {
      debugPrint('Failed to read saved session: $e');
    }
  }

  // ============================================================================
  // Appearance (device-local copy of the user's light / dark preference)
  // ============================================================================

  // The preference is stored PER ACCOUNT (keyed by userId) so one user's dark
  // mode never carries over to another account on the same device.
  static String _darkModeKey(String userId) => 'dark_mode_$userId';

  static Future<bool> readDarkMode(String userId) async {
    if (userId.isEmpty) return false;
    try {
      return await _secureStorage.read(key: _darkModeKey(userId)) == 'true';
    } catch (_) {
      return false;
    }
  }

  static Future<void> saveDarkMode(String userId, bool dark) async {
    if (userId.isEmpty) return;
    try {
      await _secureStorage.write(
        key: _darkModeKey(userId),
        value: dark.toString(),
      );
    } catch (e) {
      debugPrint('Failed to save appearance: $e');
    }
  }

  // ============================================================================
  // Leftover gateway-customer keys
  // ============================================================================

  // The app no longer stores a gateway customer; these keys only exist on devices
  // that ran an older build, and are wiped on logout so nothing stays behind.
  static const List<String> _legacyCustomerKeys = [
    'customer_gateway',
    'customer_customer_id',
    'customer_email',
    'customer_display_name',
    'customer_phone',
    'customer_metadata',
  ];

  /// Removes the leftover gateway-customer keys of older builds.
  static Future<void> clearCustomer() async {
    for (final key in _legacyCustomerKeys) {
      await _secureStorage.delete(key: key);
    }
  }

  static Future<bool?>? _refreshing;

  /// Swaps the saved token for a fresh one (`POST /api/users/refresh` accepts a token that
  /// expired up to 30 days ago). Callers that arrive while a refresh is running share it.
  ///
  /// `true`  - a new token is saved; `false` - the server refused (session really over);
  /// `null`  - the server could not be reached, so nothing is known: do NOT sign the user out.
  static Future<bool?> refreshToken() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  static Future<bool?> _refresh() async {
    final token = getToken();
    if (token == null || token.isEmpty) return false;
    try {
      // A bare client: this call must not go through the interceptor that triggers refreshes
      final bare = Dio(ApiClient().dio.options)
        ..httpClientAdapter = createHttpAdapter();
      final result = await bare.post(
        '/api/users/refresh',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final newToken = result.data?['data']?['token'];
      if (result.data?['success'] != true || newToken is! String) return false;
      // Only the token changes; the saved identity (name, userId...) stays valid
      await saveToken(newToken);
      return true;
    } on DioException catch (e) {
      return e.response == null ? null : false;
    } catch (_) {
      return false;
    }
  }
}

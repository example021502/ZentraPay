import 'package:flutter/foundation.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/main.dart' as app;

final dio = ApiClient().dio;

// Keep track of the active token in memory so Privy can fetch it on demand
// This is a public variable accessible from main.dart for the tokenProvider
String? currentCustomToken;

// Public getter for the current custom token (used by main.dart)
String? getCurrentCustomToken() => currentCustomToken;

// Use the global privyClient instance initialized in main.dart
// This ensures we're using the same Privy instance with custom auth configured
Privy get privy => app.privyClient;

// Logging in
Future<Map<String, dynamic>?> loginUser(Map<String, dynamic> form) async {
  try {
    debugPrint('LOGIN PAYLOAD: $form');
    debugPrint('ATTEMPT LOGIN TO: ${dio.options.baseUrl}/api/users/login');
    final response = await dio.post('/api/users/login', data: form);
    debugPrint('LOGIN RESPONSE DATA: ${response.data}');
    if (response.data is Map) {
      return Map<String, dynamic>.from(response.data);
    }
    debugPrint(
      "LOGIN TYPE ERROR: response.data is not a Map, got ${response.data.runtimeType}",
    );
    return null;
  } catch (e) {
    debugPrint("LOGIN ERROR:: $e");
  }
  return null;
}

// Registering new user
Future<Map<String, dynamic>?> registerUser(Map<String, dynamic> form) async {
  try {
    debugPrint('REGISTER PAYLOAD: $form');
    final response = await dio.post('/api/users/register', data: form);
    debugPrint('REGISTER RESPONSE: ${response.data}');
    if (response.data is Map) {
      return Map<String, dynamic>.from(response.data);
    }
    debugPrint(
      "REGISTER TYPE ERROR: response.data is not a Map, got ${response.data.runtimeType}",
    );
    return null;
  } catch (e) {
    debugPrint("REGISTER ERROR:: $e");
  }
  return null;
}

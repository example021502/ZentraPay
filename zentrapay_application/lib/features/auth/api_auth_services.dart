import 'package:flutter/foundation.dart'; // Required for debugPrint
import 'package:privy_flutter/privy_flutter.dart'; // Import Privy SDK
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
    final response = await dio.post('/api/auth/login', data: form);
    return response.data as Map<String, dynamic>?;
  } catch (e) {
    debugPrint("ERROR:: $e");
  }
}

// Registering new user
Future<Map<String, dynamic>?> registerUser(Map<String, dynamic> form) async {
  try {
    final response = await dio.post('/api/auth/register', data: form);
    return response as Map<String, dynamic>;
  } catch (e) {
    debugPrint("ERROR:: $e");
  }
}

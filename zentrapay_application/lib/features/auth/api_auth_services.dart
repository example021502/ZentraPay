import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

final dio = ApiClient().dio;

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
    return {"success": false, "message": "Format Error"};
  } catch (e) {
    debugPrint("LOGIN ERROR:: $e");
    return {"success": false, "message": "Could not connect to database"};
  }
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
    return {"success": false, "message": "Format Error"};
  } catch (e) {
    debugPrint("REGISTER ERROR:: $e");
    return {"success": false, "message": "Could not connect to database"};
  }
}

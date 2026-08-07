import 'package:dio/dio.dart'; // Required to check for DioException
import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

final dio = ApiClient().dio;

// Logging in with proper backend error message extraction
Future<Map<String, dynamic>?> loginUser(Map<String, dynamic> form) async {
  try {
    debugPrint('LOGIN PAYLOAD: $form');
    final response = await dio.post('/api/users/login', data: form);
    debugPrint('LOGIN RESPONSE DATA: ${response.data}');

    if (response.data is Map) {
      return Map<String, dynamic>.from(response.data);
    }
    return {"success": false, "message": "Format Error"};
  } catch (e) {
    debugPrint("LOGIN ERROR:: $e");

    // Check if Dio received an error response from the Spring Boot backend
    if (e is DioException && e.response != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return {"success": false, "message": data['message']};
      }
      if (data is String && data.isNotEmpty) {
        return {"success": false, "message": data};
      }
    }

    // Fallback only if it's a true network/connection failure
    return {"success": false, "message": "Could not connect to database"};
  }
}

// Registering new user with proper backend error message extraction
Future<Map<String, dynamic>?> registerUser(Map<String, dynamic> form) async {
  try {
    debugPrint('REGISTER PAYLOAD: $form');
    final response = await dio.post('/api/users/register', data: form);
    debugPrint('REGISTER RESPONSE: ${response.data}');

    if (response.data is Map) {
      return Map<String, dynamic>.from(response.data);
    }
    return {"success": false, "message": "Format Error"};
  } catch (e) {
    debugPrint("REGISTER ERROR:: $e");

    // Extract the backend's exception message from the DioException response
    if (e is DioException && e.response != null) {
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return {"success": false, "message": data['message']};
      }
      if (data is String && data.isNotEmpty) {
        return {"success": false, "message": data};
      }
    }

    // Fallback for actual connection drops or offline state
    return {"success": false, "message": "Could not connect to database"};
  }
}

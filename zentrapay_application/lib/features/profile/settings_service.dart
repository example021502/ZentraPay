import 'package:zentrapay_application/core/utils/interceptor.dart';

class SettingsService {
  final _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getSecurityScore() async {
    try {
      final response = await _dio.get('/api/settings/security-score');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> updateBiometricAuth(bool enabled) async {
    try {
      final response = await _dio.post(
        '/api/settings/biometric',
        data: {'enabled': enabled},
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> updateFraudProtection(bool enabled) async {
    try {
      final response = await _dio.post(
        '/api/settings/fraud-protection',
        data: {'enabled': enabled},
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getProtectionHistory() async {
    try {
      final response = await _dio.get('/api/settings/protection-history');
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

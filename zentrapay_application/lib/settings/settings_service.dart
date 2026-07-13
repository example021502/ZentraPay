import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingsService {
  static const String baseUrl = 'http://localhost:3000/api';

  Future<Map<String, dynamic>> getSecurityScore() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings/security-score'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load security score');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> updateBiometricAuth(bool enabled) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/settings/biometric'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'enabled': enabled}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update biometric auth');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> updateFraudProtection(bool enabled) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/settings/fraud-protection'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'enabled': enabled}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update fraud protection');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getProtectionHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings/protection-history'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load protection history');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

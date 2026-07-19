import 'package:http/http.dart' as http;
import 'dart:convert';

class FraudDetectionService {
  static const String baseUrl = 'http://localhost:3000/api';

  Future<Map<String, dynamic>> getFraudStatus() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/fraud/status'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load fraud status');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFraudAlerts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/fraud/alerts'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load fraud alerts');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFraudMonitoringItems() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/fraud/monitoring'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load monitoring items');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> reportFraud(
    Map<String, dynamic> reportData,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/fraud/report'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(reportData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to report fraud');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

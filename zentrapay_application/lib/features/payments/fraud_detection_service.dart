import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FraudDetectionService {
  static String get baseUrl => '${dotenv.get('BASE_URL')}/api';

  Future<Map<String, dynamic>> getFraudAlerts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/fraud/alerts'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load fraud alerts');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

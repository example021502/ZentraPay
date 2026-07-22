import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LiquidityHubService {
  static String get baseUrl => '${dotenv.get('BASE_URL')}/api';

  Future<Map<String, dynamic>> getLiquidityProfile() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/liquidity/profile'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load liquidity profile');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getFinancialTrend() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/liquidity/trend'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load financial trend');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTopRisks() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/liquidity/risks'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load risks');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentAlerts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/liquidity/alerts'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load alerts');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

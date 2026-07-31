import 'package:zentrapay_application/core/utils/interceptor.dart';

class LiquidityHubService {
  final _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getLiquidityProfile() async {
    try {
      final response = await _dio.get('/api/liquidity/profile');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getFinancialTrend() async {
    try {
      final response = await _dio.get('/api/liquidity/trend');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTopRisks() async {
    try {
      final response = await _dio.get('/api/liquidity/risks');
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentAlerts() async {
    try {
      final response = await _dio.get('/api/liquidity/alerts');
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

import 'package:zentrapay_application/core/utils/interceptor.dart';

class FraudDetectionService {
  final _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getFraudAlerts() async {
    try {
      final response = await _dio.get('/api/fraud/alerts');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

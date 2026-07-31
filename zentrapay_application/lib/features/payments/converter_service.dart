import 'package:zentrapay_application/core/utils/interceptor.dart';

class ConverterService {
  final _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getExchangeRates() async {
    try {
      final response = await _dio.get('/api/converter/rates');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> convertCurrency({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
    required String conversionType,
  }) async {
    try {
      final response = await _dio.post(
        '/api/converter/convert',
        data: {
          'fromCurrency': fromCurrency,
          'toCurrency': toCurrency,
          'amount': amount,
          'conversionType': conversionType,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getConversionHistory() async {
    try {
      final response = await _dio.get('/api/converter/history');
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

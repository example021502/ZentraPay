import 'package:http/http.dart' as http;
import 'dart:convert';

class ConverterService {
  static const String baseUrl = 'http://localhost:3000/api';

  Future<Map<String, dynamic>> getExchangeRates() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/converter/rates'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load exchange rates');
      }
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
      final response = await http.post(
        Uri.parse('$baseUrl/converter/convert'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fromCurrency': fromCurrency,
          'toCurrency': toCurrency,
          'amount': amount,
          'conversionType': conversionType,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to convert currency');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getConversionHistory() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/converter/history'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load conversion history');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

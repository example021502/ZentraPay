import 'package:zentrapay_application/core/utils/interceptor.dart';

class ProfileService {
  final _dio = ApiClient().dio;

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get('/api/profile/user');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getWalletInfo() async {
    try {
      final response = await _dio.get('/api/profile/wallet');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLinkedBanks() async {
    try {
      final response = await _dio.get('/api/profile/banks');
      final List<dynamic> data = response.data;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<String> generateQRCode() async {
    try {
      final response = await _dio.post('/api/profile/qr/generate');
      return response.data['qrCode'];
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

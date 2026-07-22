import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileService {
  static String get baseUrl => '${dotenv.get('BASE_URL')}/api';

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/profile/user'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load profile');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getWalletInfo() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/profile/wallet'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load wallet info');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLinkedBanks() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/profile/banks'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load linked banks');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<String> generateQRCode() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/profile/qr/generate'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['qrCode'];
      } else {
        throw Exception('Failed to generate QR code');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}

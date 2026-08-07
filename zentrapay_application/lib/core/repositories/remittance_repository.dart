import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/core/models/remittance.dart';
import 'package:zentrapay_application/core/repositories/cached_resource.dart';

class RemittanceHistoryRepository extends CachedListResource<RemittanceRecord> {
  RemittanceHistoryRepository._();
  static final RemittanceHistoryRepository instance =
      RemittanceHistoryRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<RemittanceRecord>> fetch() async {
    final response = await _dio.get('/api/remittance/history');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => RemittanceRecord.fromJson(e))
        .toList();
  }

  void prependFromSend(Map<String, dynamic> remittanceJson) {
    addItem(RemittanceRecord.fromJson(remittanceJson));
  }
}

class RemittanceService {
  static final Dio _dio = ApiClient().dio;

  static Future<RemittanceQuote> getQuote({
    required String source,
    required String destination,
  }) async {
    final response = await _dio.get(
      '/api/remittance/rates',
      queryParameters: {'source': source, 'destination': destination},
    );
    return RemittanceQuote.fromJson(response.data['data']);
  }

  static Future<Map<String, dynamic>> send({
    required String pin,
    required String amount,
    required String sourceCurrencyCode,
    required String destinationCurrencyCode,
    required String channel,
    required String recipientName,
    String? recipientPhoneNumber,
    String? recipientUserId,
    required String recipientCountryCode,
  }) async {
    final response = await _dio.post(
      '/api/remittance/send',
      data: {
        'pin': pin,
        'amount': amount,
        'sourceCurrencyCode': sourceCurrencyCode,
        'destinationCurrencyCode': destinationCurrencyCode,
        'channel': channel,
        'recipientName': recipientName,
        'recipientPhoneNumber': ?recipientPhoneNumber,
        'recipientUserId': ?recipientUserId,
        'recipientCountryCode': recipientCountryCode,
      },
    );
    final data = response.data['data'] ?? {};
    final remittanceJson = data['remittance'] ?? {};
    RemittanceHistoryRepository.instance.prependFromSend(remittanceJson);
    return data;
  }
}

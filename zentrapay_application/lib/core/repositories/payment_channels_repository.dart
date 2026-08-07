import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/core/models/reference_data.dart';

/// Bank/mobile-money directory — cached per (countryCode, type) combination
/// since that's how the bank-select UI queries it (a fresh country/type
/// selection is a deliberate refetch, not a cache miss).
class PaymentChannelsRepository {
  PaymentChannelsRepository._();
  static final PaymentChannelsRepository instance =
      PaymentChannelsRepository._();

  final Dio _dio = ApiClient().dio;
  final Map<String, List<PaymentChannel>> _cache = {};

  Future<List<PaymentChannel>> load({
    required String countryCode,
    String? type,
  }) async {
    final key = '$countryCode:${type ?? ''}';
    final cached = _cache[key];
    if (cached != null) return cached;

    final response = await _dio.get(
      '/api/payment-channels',
      queryParameters: {
        'countryCode': countryCode,
        'type': ?type,
      },
    );
    final channels = ((response.data['data'] as List?) ?? [])
        .map((e) => PaymentChannel.fromJson(e))
        .toList();
    _cache[key] = channels;
    return channels;
  }

  Future<String?> resolveAccountName({
    required String channelCode,
    required String accountNumber,
  }) async {
    final response = await _dio.get(
      '/api/payment-channels/resolve',
      queryParameters: {
        'channelCode': channelCode,
        'accountNumber': accountNumber,
      },
    );
    return response.data['data']?['accountName'];
  }
}

import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/core/models/bill_service_provider.dart';
import 'package:zentrapay_application/core/repositories/cached_resource.dart';

class BillProvidersRepository extends CachedListResource<BillProvider> {
  BillProvidersRepository._();
  static final BillProvidersRepository instance = BillProvidersRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<BillProvider>> fetch() async {
    final response = await _dio.get('/api/bill-providers');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => BillProvider.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> validate({
    required String providerId,
    required String customerReference,
  }) async {
    final response = await _dio.post(
      '/api/bill-providers/validate',
      data: {'providerId': providerId, 'customerReference': customerReference},
    );
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> pay({
    required String pin,
    required String providerId,
    required String customerReference,
    required String amount,
    required String currencyCode,
  }) async {
    final response = await _dio.post(
      '/api/bill-providers/pay',
      data: {
        'pin': pin,
        'providerId': providerId,
        'customerReference': customerReference,
        'amount': amount,
        'currencyCode': currencyCode,
      },
    );
    return response.data['data'] ?? {};
  }
}

class BillPaymentHistoryRepository extends CachedListResource<BillPaymentRecord> {
  BillPaymentHistoryRepository._();
  static final BillPaymentHistoryRepository instance =
      BillPaymentHistoryRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<BillPaymentRecord>> fetch() async {
    final response = await _dio.get('/api/bill-providers/history');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => BillPaymentRecord.fromJson(e))
        .toList();
  }
}

class ServiceProvidersRepository extends CachedListResource<ServiceProvider> {
  ServiceProvidersRepository._();
  static final ServiceProvidersRepository instance =
      ServiceProvidersRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<ServiceProvider>> fetch() async {
    final response = await _dio.get('/api/service-providers');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => ServiceProvider.fromJson(e))
        .toList();
  }
}

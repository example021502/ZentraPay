import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/core/models/converter.dart';
import 'package:zentrapay_application/core/repositories/cached_resource.dart';

class RatesRepository extends CachedResource<RatesSnapshot> {
  RatesRepository._();
  static final RatesRepository instance = RatesRepository._();

  final Dio _dio = ApiClient().dio;
  String _base = 'GHS';

  /// Rates for a given base currency are cached independently — switching
  /// base currency in the UI is a deliberate refetch, not a cache miss on
  /// the same resource.
  Future<RatesSnapshot?> loadForBase(String base) {
    if (base != _base) clear();
    _base = base;
    return ensureLoaded();
  }

  @override
  Future<RatesSnapshot> fetch() async {
    final response = await _dio.get(
      '/api/converter/rates',
      queryParameters: {'base': _base},
    );
    return RatesSnapshot.fromJson(response.data['data']);
  }
}

class ConverterHistoryRepository extends CachedListResource<ConversionHistoryEntry> {
  ConverterHistoryRepository._();
  static final ConverterHistoryRepository instance =
      ConverterHistoryRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<ConversionHistoryEntry>> fetch() async {
    final response = await _dio.get('/api/converter/history');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => ConversionHistoryEntry.fromJson(e))
        .toList();
  }
}

class ConverterService {
  static final Dio _dio = ApiClient().dio;

  static Future<ConversionResult> convert({
    required String from,
    required String to,
    required String amount,
  }) async {
    final response = await _dio.post(
      '/api/converter/convert',
      data: {'from': from, 'to': to, 'amount': amount},
    );
    final result = ConversionResult.fromJson(response.data['data']);
    // A conversion changes server-side history — refresh lazily next time
    // the history screen is opened rather than forcing a refetch now.
    ConverterHistoryRepository.instance.clear();
    return result;
  }
}

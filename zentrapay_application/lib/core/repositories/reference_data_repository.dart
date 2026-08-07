import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/core/models/reference_data.dart';
import 'package:zentrapay_application/core/repositories/cached_resource.dart';

/// Countries/currencies/categories never change during a session (and
/// barely change at all) — this is the purest case of "load once and keep
/// forever." Every dropdown/picker across signup, wallet creation, and bill
/// payment reads from these three singletons instead of hitting the network
/// each time a picker opens.
class CountriesRepository extends CachedListResource<AppCountry> {
  CountriesRepository._();
  static final CountriesRepository instance = CountriesRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<AppCountry>> fetch() async {
    final response = await _dio.get('/api/reference/countries');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => AppCountry.fromJson(e))
        .toList();
  }
}

class CurrenciesRepository extends CachedListResource<AppCurrency> {
  CurrenciesRepository._();
  static final CurrenciesRepository instance = CurrenciesRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<AppCurrency>> fetch() async {
    final response = await _dio.get('/api/reference/currencies');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => AppCurrency.fromJson(e))
        .toList();
  }
}

class ProviderCategoriesRepository extends CachedListResource<ProviderCategory> {
  ProviderCategoriesRepository._();
  static final ProviderCategoriesRepository instance =
      ProviderCategoriesRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<ProviderCategory>> fetch() async {
    final response = await _dio.get('/api/reference/provider-categories');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => ProviderCategory.fromJson(e))
        .toList();
  }
}

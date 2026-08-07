import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/core/models/zinvest.dart';
import 'package:zentrapay_application/core/repositories/cached_resource.dart';

class InvestmentsRepository extends CachedListResource<Investment> {
  InvestmentsRepository._();
  static final InvestmentsRepository instance = InvestmentsRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<Investment>> fetch() async {
    final response = await _dio.get('/api/zinvest/portfolio');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => Investment.fromJson(e))
        .toList();
  }

  Future<Investment> invest({
    required String name,
    required String investmentType,
    String? symbol,
    required String quantity,
    required String buyPrice,
    required String currencyCode,
  }) async {
    final response = await _dio.post(
      '/api/zinvest/invest',
      data: {
        'name': name,
        'investmentType': investmentType,
        'symbol': symbol,
        'quantity': quantity,
        'buyPrice': buyPrice,
        'currencyCode': currencyCode,
      },
    );
    final investment = Investment.fromJson(response.data['data']);
    addItem(investment);
    return investment;
  }

  Future<void> sell(String investmentId) async {
    await _dio.post('/api/zinvest/$investmentId/sell');
    removeItem((i) => i.investmentId == investmentId);
  }
}

class LiquidityProfileRepository extends CachedResource<LiquidityProfile> {
  LiquidityProfileRepository._();
  static final LiquidityProfileRepository instance =
      LiquidityProfileRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<LiquidityProfile> fetch() async {
    final response = await _dio.get('/api/zinvest/liquidity-profile');
    return LiquidityProfile.fromJson(response.data['data']);
  }
}

class LiquidityTrendRepository extends CachedListResource<LiquidityTrendPoint> {
  LiquidityTrendRepository._();
  static final LiquidityTrendRepository instance =
      LiquidityTrendRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<LiquidityTrendPoint>> fetch() async {
    final response = await _dio.get('/api/zinvest/liquidity-trend');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => LiquidityTrendPoint.fromJson(e))
        .toList();
  }
}

class InvestmentRisksRepository extends CachedListResource<InvestmentRisk> {
  InvestmentRisksRepository._();
  static final InvestmentRisksRepository instance =
      InvestmentRisksRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<InvestmentRisk>> fetch() async {
    final response = await _dio.get('/api/zinvest/risks');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => InvestmentRisk.fromJson(e))
        .toList();
  }
}

class InvestmentAlertsRepository extends CachedListResource<InvestmentAlert> {
  InvestmentAlertsRepository._();
  static final InvestmentAlertsRepository instance =
      InvestmentAlertsRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<InvestmentAlert>> fetch() async {
    final response = await _dio.get('/api/zinvest/alerts');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => InvestmentAlert.fromJson(e))
        .toList();
  }
}

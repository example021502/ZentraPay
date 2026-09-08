import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/core/models/zinvest.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

/// ZInvest data caches: portfolio, liquidity profile/trend, risk ranking
/// and alerts. Every repository implements the "load once, then apply
/// deltas" contract inline — there is no shared abstract cache base
/// anymore; each repository owns its own state and notifies listeners.
///
/// The payments feature's Liquidity Hub screen also imports this file.
class InvestmentsRepository extends ChangeNotifier {
  InvestmentsRepository._();
  static final InvestmentsRepository instance = InvestmentsRepository._();

  final Dio _dio = ApiClient().dio;

  List<Investment>? _data;
  bool _loading = false;
  Object? _error;

  List<Investment>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<Investment>> fetch() async {
    final response = await _dio.get('/api/zinvest/portfolio');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => Investment.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<Investment>?> ensureLoaded({bool forceRefresh = false}) async {
    if (_data != null && !forceRefresh) return _data;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await fetch();
      return _data;
    } catch (e) {
      _error = e;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Applies a POST/PUT response onto the cached value without refetching.
  void applyDelta(List<Investment> Function(List<Investment> current) updater) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<Investment> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(Investment item) => applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(Investment item) matches,
    Investment replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(Investment item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
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

/// Liquidity profile (`GET /api/zinvest/liquidity-profile`). Single-value
/// cache.
class LiquidityProfileRepository extends ChangeNotifier {
  LiquidityProfileRepository._();
  static final LiquidityProfileRepository instance =
      LiquidityProfileRepository._();

  final Dio _dio = ApiClient().dio;

  LiquidityProfile? _data;
  bool _loading = false;
  Object? _error;

  LiquidityProfile? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<LiquidityProfile> fetch() async {
    final response = await _dio.get('/api/zinvest/liquidity-profile');
    return LiquidityProfile.fromJson(response.data['data']);
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<LiquidityProfile?> ensureLoaded({bool forceRefresh = false}) async {
    if (_data != null && !forceRefresh) return _data;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await fetch();
      return _data;
    } catch (e) {
      _error = e;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Applies a POST/PUT response onto the cached value without refetching.
  void applyDelta(
    LiquidityProfile Function(LiquidityProfile current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(LiquidityProfile value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}

/// Liquidity trend series (`GET /api/zinvest/liquidity-trend`). Read-only
/// list cache.
class LiquidityTrendRepository extends ChangeNotifier {
  LiquidityTrendRepository._();
  static final LiquidityTrendRepository instance =
      LiquidityTrendRepository._();

  final Dio _dio = ApiClient().dio;

  List<LiquidityTrendPoint>? _data;
  bool _loading = false;
  Object? _error;

  List<LiquidityTrendPoint>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<LiquidityTrendPoint>> fetch() async {
    final response = await _dio.get('/api/zinvest/liquidity-trend');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => LiquidityTrendPoint.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<LiquidityTrendPoint>?> ensureLoaded({
    bool forceRefresh = false,
  }) async {
    if (_data != null && !forceRefresh) return _data;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await fetch();
      return _data;
    } catch (e) {
      _error = e;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Applies a POST/PUT response onto the cached value without refetching.
  void applyDelta(
    List<LiquidityTrendPoint> Function(List<LiquidityTrendPoint> current)
    updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<LiquidityTrendPoint> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(LiquidityTrendPoint item) =>
      applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(LiquidityTrendPoint item) matches,
    LiquidityTrendPoint replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(LiquidityTrendPoint item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}

/// Top investment risks (`GET /api/zinvest/risks`). Read-only list cache.
class InvestmentRisksRepository extends ChangeNotifier {
  InvestmentRisksRepository._();
  static final InvestmentRisksRepository instance =
      InvestmentRisksRepository._();

  final Dio _dio = ApiClient().dio;

  List<InvestmentRisk>? _data;
  bool _loading = false;
  Object? _error;

  List<InvestmentRisk>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<InvestmentRisk>> fetch() async {
    final response = await _dio.get('/api/zinvest/risks');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => InvestmentRisk.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<InvestmentRisk>?> ensureLoaded({bool forceRefresh = false}) async {
    if (_data != null && !forceRefresh) return _data;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await fetch();
      return _data;
    } catch (e) {
      _error = e;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Applies a POST/PUT response onto the cached value without refetching.
  void applyDelta(
    List<InvestmentRisk> Function(List<InvestmentRisk> current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<InvestmentRisk> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(InvestmentRisk item) =>
      applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(InvestmentRisk item) matches,
    InvestmentRisk replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(InvestmentRisk item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}

/// Investment alerts (`GET /api/zinvest/alerts`). Read-only list cache.
class InvestmentAlertsRepository extends ChangeNotifier {
  InvestmentAlertsRepository._();
  static final InvestmentAlertsRepository instance =
      InvestmentAlertsRepository._();

  final Dio _dio = ApiClient().dio;

  List<InvestmentAlert>? _data;
  bool _loading = false;
  Object? _error;

  List<InvestmentAlert>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<InvestmentAlert>> fetch() async {
    final response = await _dio.get('/api/zinvest/alerts');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => InvestmentAlert.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<InvestmentAlert>?> ensureLoaded({
    bool forceRefresh = false,
  }) async {
    if (_data != null && !forceRefresh) return _data;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await fetch();
      return _data;
    } catch (e) {
      _error = e;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Applies a POST/PUT response onto the cached value without refetching.
  void applyDelta(
    List<InvestmentAlert> Function(List<InvestmentAlert> current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<InvestmentAlert> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(InvestmentAlert item) =>
      applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(InvestmentAlert item) matches,
    InvestmentAlert replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(InvestmentAlert item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}



import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/core/models/remittance.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

/// ZRemit data caches: the remittance history (`GET /api/remittance/history`)
/// plus the quote/send service. The history implements the "load once, then
/// apply deltas" contract inline — there is no shared abstract cache base
/// anymore; the repository owns its own state and notifies listeners.
class RemittanceHistoryRepository extends ChangeNotifier {
  RemittanceHistoryRepository._();
  static final RemittanceHistoryRepository instance =
      RemittanceHistoryRepository._();

  final Dio _dio = ApiClient().dio;

  List<RemittanceRecord>? _data;
  bool _loading = false;
  Object? _error;

  List<RemittanceRecord>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<RemittanceRecord>> fetch() async {
    final response = await _dio.get('/api/remittance/history');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => RemittanceRecord.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<RemittanceRecord>?> ensureLoaded({
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
    List<RemittanceRecord> Function(List<RemittanceRecord> current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<RemittanceRecord> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(RemittanceRecord item) =>
      applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(RemittanceRecord item) matches,
    RemittanceRecord replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(RemittanceRecord item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  /// A completed send returns the new record — prepend it locally instead
  /// of re-fetching the whole history.
  void prependFromSend(Map<String, dynamic> remittanceJson) {
    addItem(RemittanceRecord.fromJson(remittanceJson));
  }
}

/// Remittance quote/send operations. Not a cached resource — each call is a
/// deliberate user action — but a successful send updates the history cache
/// instead of leaving other screens to refetch.
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

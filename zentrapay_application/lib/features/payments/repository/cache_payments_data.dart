import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/core/models/converter.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';

/// Payments data caches: converter rates/history, the currency-conversion
/// service and the money-movement operations (PaymentsService). Every
/// cached resource implements the "load once, then apply deltas" contract
/// inline — there is no shared abstract cache base anymore; each repository
/// owns its own state and notifies listeners.
///
/// The ZRemit screen imports this file for the live exchange-rate header,
/// and the transfer flows use [PaymentsService].

/// Exchange-rate snapshot for a base currency (`GET /api/converter/rates`).
class RatesRepository extends ChangeNotifier {
  RatesRepository._();
  static final RatesRepository instance = RatesRepository._();

  final Dio _dio = ApiClient().dio;
  String _base = 'GHS';

  RatesSnapshot? _data;
  bool _loading = false;
  Object? _error;

  RatesSnapshot? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// Rates for a given base currency are cached independently — switching
  /// base currency in the UI is a deliberate refetch, not a cache miss on
  /// the same resource.
  Future<RatesSnapshot?> loadForBase(String base) {
    if (base != _base) clear();
    _base = base;
    return ensureLoaded();
  }

  /// The actual network call.
  Future<RatesSnapshot> fetch() async {
    final response = await _dio.get(
      '/api/converter/rates',
      queryParameters: {'base': _base},
    );
    return RatesSnapshot.fromJson(response.data['data']);
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<RatesSnapshot?> ensureLoaded({bool forceRefresh = false}) async {
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
  void applyDelta(RatesSnapshot Function(RatesSnapshot current) updater) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(RatesSnapshot value) {
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

/// Conversion history (`GET /api/converter/history`). List cache.
class ConverterHistoryRepository extends ChangeNotifier {
  ConverterHistoryRepository._();
  static final ConverterHistoryRepository instance =
      ConverterHistoryRepository._();

  final Dio _dio = ApiClient().dio;

  List<ConversionHistoryEntry>? _data;
  bool _loading = false;
  Object? _error;

  List<ConversionHistoryEntry>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<ConversionHistoryEntry>> fetch() async {
    final response = await _dio.get('/api/converter/history');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => ConversionHistoryEntry.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<ConversionHistoryEntry>?> ensureLoaded({
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
    List<ConversionHistoryEntry> Function(List<ConversionHistoryEntry> current)
    updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<ConversionHistoryEntry> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(ConversionHistoryEntry item) =>
      applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(ConversionHistoryEntry item) matches,
    ConversionHistoryEntry replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(ConversionHistoryEntry item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}

/// Currency conversion operations. Not a cached resource — each call is a
/// deliberate user action — but a conversion changes server-side history,
/// so the history cache is cleared to refresh lazily next time it's opened.
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

/// Money-movement operations (internal transfer, bank disbursement, card
/// funding via Paystack). These aren't cached resources themselves — each
/// call is a deliberate user action — but every successful call updates the
/// two caches a payment affects (the sender's wallet balance and the
/// transaction history) instead of leaving other screens to refetch.
class PaymentsService {
  static final Dio _dio = ApiClient().dio;

  static Future<Map<String, dynamic>> payment({
    required Map<String, dynamic> payload,
  }) async {
    final response = await _dio.post('/api/payments/initialize', data: payload);
    final String message = response.data['message'] ?? 'Payment successful';
    if (response.data['success'] == true && response.data['data'] != null) {
      // _applyTransactionResult hands back the parsed AppTransaction; the
      // caller used to receive the RAW response map here and then cast it
      // `as AppTransaction?` — a TypeError that surfaced as "Payment Failed"
      // even though the backend had already committed the transfer.
      final AppTransaction transaction = _applyTransactionResult(
        response.data['data'],
      );
      return {'data': transaction, 'message': message};
    } else {
      return {
        'data': null,
        'message': 'Payment response missing transaction data',
      };
    }
  }

  /// Retry, step 1 (`POST /api/payments/retry/{id}/check`): are the sender and the receiver of this
  /// failed payment still valid? No PIN, nothing moves. When a party is no longer valid the backend
  /// keeps that reason on the failed payment.
  static Future<RetryCheck> checkRetry(String transactionId) async {
    final response = await _dio.post('/api/payments/retry/$transactionId/check');
    return RetryCheck.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
  }

  /// Retry, step 2 (`POST /api/payments/retry/{id}`): checks again, verifies the PIN and pays again.
  static Future<AppTransaction> retry(String transactionId, String pin) async {
    final response = await _dio.post(
      '/api/payments/retry/$transactionId',
      data: {'pin': pin},
    );
    return _applyTransactionResult(response.data['data']);
  }

  /// Parses a transaction payload, prepends it to the cached transaction
  /// history and refreshes the wallet snapshot.
  static AppTransaction _applyTransactionResult(Map<String, dynamic> json) {
    final transaction = AppTransaction.fromJson(json);
    TransactionsRepository.instance.prepend(transaction);
    // The wallet's balance changed server-side; the cheapest correct move
    // is a forced refresh of the (already-loaded) wallets snapshot rather
    // than trying to recompute the new balance client-side.
    WalletsRepository.instance.ensureLoaded();
    return transaction;
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/core/models/security.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

/// Security-domain caches owned by the Settings screen: the biometric/2FA/
/// fraud-protection toggle state (`GET /api/secure/status`), the fraud-alert
/// feed and the login history. Each repository implements the
/// "load once, then apply deltas" contract inline — there is no shared
/// abstract cache base anymore; every repository owns its own state and
/// notifies listeners.
///
/// Shared app-wide: the Payments fraud-detection screen and the ZVoice
/// security page import this file for [FraudAlertsRepository].
class SecuritySettingsRepository extends ChangeNotifier {
  SecuritySettingsRepository._();
  static final SecuritySettingsRepository instance =
      SecuritySettingsRepository._();

  final Dio _dio = ApiClient().dio;

  SecuritySettings? _data;
  bool _loading = false;
  Object? _error;

  SecuritySettings? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<SecuritySettings> fetch() async {
    final response = await _dio.get('/api/secure/status');
    return SecuritySettings.fromJson(response.data['data']);
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<SecuritySettings?> ensureLoaded({bool forceRefresh = false}) async {
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
    SecuritySettings Function(SecuritySettings current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright (a POST here returns the full new
  /// resource rather than something to merge).
  void setData(SecuritySettings value) {
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

  Future<void> setBiometric(bool enabled, {String type = 'FINGERPRINT'}) async {
    final response = await _dio.post(
      '/api/secure/biometric',
      data: {'enabled': enabled, 'type': type},
    );
    setData(SecuritySettings.fromJson(response.data['data']));
  }

  Future<void> setTwoFactor(bool enabled, {String? method}) async {
    final response = await _dio.post(
      '/api/secure/2fa',
      data: {'enabled': enabled, 'method': ?method},
    );
    setData(SecuritySettings.fromJson(response.data['data']));
  }

  Future<void> setFraudProtection(bool enabled) async {
    final response = await _dio.post(
      '/api/secure/fraud-protection',
      data: {'enabled': enabled},
    );
    setData(SecuritySettings.fromJson(response.data['data']));
  }
}

/// Fraud-alert feed (`GET /api/secure/fraud-alerts`) — consumed by the
/// payments fraud-detection screen and the ZVoice security page. Read-only
/// list cache.
class FraudAlertsRepository extends ChangeNotifier {
  FraudAlertsRepository._();
  static final FraudAlertsRepository instance = FraudAlertsRepository._();

  final Dio _dio = ApiClient().dio;

  List<FraudAlert>? _data;
  bool _loading = false;
  Object? _error;

  List<FraudAlert>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<FraudAlert>> fetch() async {
    final response = await _dio.get('/api/secure/fraud-alerts');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => FraudAlert.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<FraudAlert>?> ensureLoaded({bool forceRefresh = false}) async {
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
    List<FraudAlert> Function(List<FraudAlert> current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<FraudAlert> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(FraudAlert item) => applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(FraudAlert item) matches,
    FraudAlert replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(FraudAlert item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}

/// Login history (`GET /api/secure/login-history`) — shown in the Settings
/// security section. Read-only list cache.
class LoginHistoryRepository extends ChangeNotifier {
  LoginHistoryRepository._();
  static final LoginHistoryRepository instance = LoginHistoryRepository._();

  final Dio _dio = ApiClient().dio;

  List<LoginHistoryEntry>? _data;
  bool _loading = false;
  Object? _error;

  List<LoginHistoryEntry>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<LoginHistoryEntry>> fetch() async {
    final response = await _dio.get('/api/secure/login-history');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => LoginHistoryEntry.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<LoginHistoryEntry>?> ensureLoaded({
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
    List<LoginHistoryEntry> Function(List<LoginHistoryEntry> current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<LoginHistoryEntry> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(LoginHistoryEntry item) =>
      applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(LoginHistoryEntry item) matches,
    LoginHistoryEntry replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(LoginHistoryEntry item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}


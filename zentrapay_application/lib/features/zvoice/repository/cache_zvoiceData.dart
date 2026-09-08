import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/core/models/voice_command.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

/// ZVoice data caches: the command history (`GET/POST /api/zvoice/*`) and
/// the voice fraud-alert feed. Both implement the "load once, then apply
/// deltas" contract inline — there is no shared abstract cache base
/// anymore; each repository owns its own state and notifies listeners.
class VoiceCommandHistoryRepository extends ChangeNotifier {
  VoiceCommandHistoryRepository._();
  static final VoiceCommandHistoryRepository instance =
      VoiceCommandHistoryRepository._();

  final Dio _dio = ApiClient().dio;

  List<VoiceCommandResult>? _data;
  bool _loading = false;
  Object? _error;

  List<VoiceCommandResult>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<VoiceCommandResult>> fetch() async {
    final response = await _dio.get('/api/zvoice/history');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => VoiceCommandResult.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<VoiceCommandResult>?> ensureLoaded({
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
    List<VoiceCommandResult> Function(List<VoiceCommandResult> current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<VoiceCommandResult> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(VoiceCommandResult item) =>
      applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(VoiceCommandResult item) matches,
    VoiceCommandResult replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(VoiceCommandResult item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  Future<VoiceCommandResult> sendCommand({
    required String commandType,
    required String transcript,
    String language = 'en',
    bool fraudAlert = false,
    String? fraudReason,
  }) async {
    final response = await _dio.post(
      '/api/zvoice/command',
      data: {
        'commandType': commandType,
        'language': language,
        'transcript': transcript,
        'fraudAlert': fraudAlert,
        'fraudReason': ?fraudReason,
      },
    );
    final result = VoiceCommandResult.fromJson(response.data['data']);
    addItem(result);
    return result;
  }
}

/// Voice-specific fraud alerts (`GET /api/zvoice/fraud-alerts`). Read-only
/// list cache.
class VoiceFraudAlertsRepository extends ChangeNotifier {
  VoiceFraudAlertsRepository._();
  static final VoiceFraudAlertsRepository instance =
      VoiceFraudAlertsRepository._();

  final Dio _dio = ApiClient().dio;

  List<VoiceCommandResult>? _data;
  bool _loading = false;
  Object? _error;

  List<VoiceCommandResult>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<VoiceCommandResult>> fetch() async {
    final response = await _dio.get('/api/zvoice/fraud-alerts');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => VoiceCommandResult.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<VoiceCommandResult>?> ensureLoaded({
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
    List<VoiceCommandResult> Function(List<VoiceCommandResult> current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<VoiceCommandResult> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(VoiceCommandResult item) =>
      applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(VoiceCommandResult item) matches,
    VoiceCommandResult replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(VoiceCommandResult item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}


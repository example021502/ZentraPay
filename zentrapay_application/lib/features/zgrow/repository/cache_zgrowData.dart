import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

/// ZGrow data caches: savings challenges, learn-&-earn literacy content and
/// rewards. Every repository implements the "load once, then apply deltas"
/// contract inline — there is no shared abstract cache base anymore; each
/// repository owns its own state and notifies listeners directly.

final Dio _dio = ApiClient().dio;

class ChallengesRepository extends ChangeNotifier {
  ChallengesRepository._();
  static final ChallengesRepository instance = ChallengesRepository._();

  List<Challenge>? _data;
  bool _loading = false;
  Object? _error;

  List<Challenge>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<Challenge>> fetch() async {
    final response = await _dio.get('/api/zgrow/challenges');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => Challenge.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<Challenge>?> ensureLoaded({bool forceRefresh = false}) async {
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
  void applyDelta(List<Challenge> Function(List<Challenge> current) updater) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<Challenge> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(Challenge item) => applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(Challenge item) matches,
    Challenge replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(Challenge item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  Future<void> join(String challengeId) async {
    final response = await _dio.post('/api/zgrow/challenges/$challengeId/join');
    final updated = Challenge.fromJson(response.data['data']);
    replaceItem((c) => c.challengeId == challengeId, updated);
  }

  Future<void> decline(String challengeId) async {
    final response = await _dio.post(
      '/api/zgrow/challenges/$challengeId/decline',
    );
    final updated = Challenge.fromJson(response.data['data']);
    replaceItem((c) => c.challengeId == challengeId, updated);
  }
}

/// Learn-&-earn literacy content (`GET /api/zgrow/literacy`). Completing a
/// piece patches the cached item in place and triggers a rewards refresh.
class LiteracyRepository extends ChangeNotifier {
  LiteracyRepository._();
  static final LiteracyRepository instance = LiteracyRepository._();

  List<LiteracyContent>? _data;
  bool _loading = false;
  Object? _error;

  List<LiteracyContent>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<LiteracyContent>> fetch() async {
    final response = await _dio.get('/api/zgrow/literacy');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => LiteracyContent.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<LiteracyContent>?> ensureLoaded({
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
    List<LiteracyContent> Function(List<LiteracyContent> current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<LiteracyContent> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(LiteracyContent item) =>
      applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(LiteracyContent item) matches,
    LiteracyContent replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(LiteracyContent item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  Future<int> complete(String contentId) async {
    final response = await _dio.post('/api/zgrow/literacy/$contentId/complete');
    final pointsEarned = response.data['data']?['pointsEarned'] ?? 0;
    replaceItem(
      (c) => c.contentId == contentId,
      data!
          .firstWhere((c) => c.contentId == contentId)
          .copyWith(completed: true),
    );
    RewardsRepository.instance.ensureLoaded(forceRefresh: true);
    return pointsEarned;
  }
}

/// Rewards (`GET /api/challenges/rewards`) — single-value cache holding the
/// whole [RewardsList] payload.
class RewardsRepository extends ChangeNotifier {
  RewardsRepository._();
  static final RewardsRepository instance = RewardsRepository._();

  RewardsList? _data;
  bool _loading = false;
  Object? _error;

  RewardsList? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<RewardsList> fetch() async {
    final response = await _dio.get('/api/zgrow/rewards');
    print("REWARDS ARE:: ${response.data['data']}");
    return RewardsList.fromJson(response.data['data']);
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<RewardsList?> ensureLoaded({bool forceRefresh = false}) async {
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
  void applyDelta(RewardsList Function(RewardsList current) updater) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(RewardsList value) {
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

/// Rewards (`GET /api/challenges/rewards`) — single-value cache holding the
/// whole [RewardsList] payload.
class TutorialsRepository extends ChangeNotifier {
  TutorialsRepository._();
  static final TutorialsRepository instance = TutorialsRepository._();

  TutorialsList? _data;
  bool _loading = false;
  Object? _error;

  TutorialsList? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<TutorialsList> fetch() async {
    final response = await _dio.get('/api/zgrow/tutorials');
    print("TUTORIALS ARE:: ${response.data['data']}");
    return TutorialsList.fromJson(response.data['data']);
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<TutorialsList?> ensureLoaded({bool forceRefresh = false}) async {
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
  void applyDelta(TutorialsList Function(TutorialsList current) updater) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(TutorialsList value) {
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

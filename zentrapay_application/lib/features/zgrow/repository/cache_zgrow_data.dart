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

  /// Declined challenge ids for the caller — used to split the catalog into
  /// "All" vs declined. Never cached: the split must reflect the latest
  /// join/decline action even mid-session.
  Future<Set<String>> fetchDeclinedIds() async {
    final response = await _dio.get('/api/zgrow/challenges/declined');
    final raw = response.data['data'];
    if (raw is! List) return const {};
    return {for (final e in raw) e.toString()};
  }
}

class UserChallengesRepository extends ChangeNotifier {
  UserChallengesRepository._();
  static final UserChallengesRepository instance = UserChallengesRepository._();

  List<UserChallenge>? _data;
  bool _loading = false;
  Object? _error;

  List<UserChallenge>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<UserChallenge>> fetch() async {
    final response = await _dio.get('/api/zgrow/myChallenges');
    return ((response.data['data'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => UserChallenge.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<UserChallenge>?> ensureLoaded({bool forceRefresh = false}) async {
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
    List<UserChallenge> Function(List<UserChallenge> current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<UserChallenge> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(UserChallenge item) =>
      applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(UserChallenge item) matches,
    UserChallenge replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(UserChallenge item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  // Enrolls the user in a challenge and appends the returned enrollment.
  // Takes the *challenge* id (not the enrollment id) since that's what
  // POST /api/zgrow/challenges/enroll expects in its body.
  Future<void> join(String challengeId) async {
    final response = await _dio.post(
      '/api/zgrow/challenges/enroll',
      data: {'challengeId': challengeId},
    );
    final raw = response.data['data'];
    if (raw is Map) {
      addItem(UserChallenge.fromJson(Map<String, dynamic>.from(raw)));
    }
  }

  /// Declining removes the enrollment server-side, so drop it from the cache.
  Future<void> decline(String challengeId) async {
    await _dio.post('/api/zgrow/challenges/$challengeId/decline');
    removeItem((c) => c.challenge.id == challengeId);
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
    debugPrint("REWARDS ARE:: ${response.data['data']}");
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
    debugPrint("TUTORIALS ARE:: ${response.data['data']}");
    final raw = response.data['data'];
    final List<dynamic> list = raw is List ? raw : const [];
    return TutorialsList.fromJson(list);
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

/// ZGrow gamified toggle state — persisted server-side (GET/PUT
/// /api/zgrow/gamification), not a local switch. The challenges groups
/// render only while [challengesEnabled], and the screen loads the
/// challenge catalogs only after this cache resolves to enabled.
class GamificationSettingsRepository extends ChangeNotifier {
  GamificationSettingsRepository._();
  static final GamificationSettingsRepository instance =
      GamificationSettingsRepository._();

  bool _challengesEnabled = false;
  bool _loading = true;
  Object? _error;
  bool _saving = false;

  bool get challengesEnabled => _challengesEnabled;
  bool get isLoading => _loading;
  bool get isSaving => _saving;
  Object? get error => _error;

  /// Resolves the persisted toggle position. Never throws — an unreachable
  /// backend leaves the switch off rather than breaking the whole screen.
  Future<bool> ensureLoaded({bool forceRefresh = false}) async {
    if (!_loading && !forceRefresh) return _challengesEnabled;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _dio.get('/api/zgrow/gamification');
      final raw = response.data['data'];
      final bool enabled = raw is Map && raw['challengesEnabled'] == true;
      _challengesEnabled = enabled;
      return enabled;
    } catch (e) {
      _error = e;
      debugPrint('Gamification settings load failed: $e');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Persists a toggle flip. Optimistic: the switch moves immediately, the
  /// stored value rolls back to the server echo on failure.
  Future<void> setChallengesEnabled(bool enabled) async {
    final bool previous = _challengesEnabled;
    _challengesEnabled = enabled;
    _saving = true;
    notifyListeners();
    try {
      final response = await _dio.put(
        '/api/zgrow/gamification',
        data: {'challengesEnabled': enabled},
      );
      final raw = response.data['data'];
      if (raw is Map && raw['challengesEnabled'] is bool) {
        _challengesEnabled = raw['challengesEnabled'] as bool;
      }
      _error = null;
    } catch (e) {
      _challengesEnabled = previous;
      _error = e;
      rethrow;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  void clear() {
    _challengesEnabled = false;
    _loading = true;
    _error = null;
    _saving = false;
    notifyListeners();
  }
}

/// ZGrow "Overall Savings" — the server-computed per-currency totals from
/// GET /api/zgrow/savings (source of the hero card figure).
class SavingsRepository extends ChangeNotifier {
  SavingsRepository._();
  static final SavingsRepository instance = SavingsRepository._();

  List<SavingsSummary>? _buckets;
  bool _loading = false;
  Object? _error;

  List<SavingsSummary>? get buckets => _buckets;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The bucket in [currencyCode], or the first bucket when no wallet
  /// currency matches, or null when the ledger is empty.
  SavingsSummary? bucketFor(String? currencyCode) {
    final buckets = _buckets;
    if (buckets == null || buckets.isEmpty) return null;
    final code = (currencyCode ?? '').trim().toUpperCase();
    if (code.isNotEmpty) {
      for (final b in buckets) {
        if (b.currencyCode.trim().toUpperCase() == code) return b;
      }
    }
    return buckets.first;
  }

  double totalFor(String? currencyCode) =>
      bucketFor(currencyCode)?.totalAmount ?? 0.0;

  Future<List<SavingsSummary>?> ensureLoaded({
    bool forceRefresh = false,
  }) async {
    if (_buckets != null && !forceRefresh) return _buckets;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _dio.get('/api/zgrow/savings');
      final raw = response.data['data'];
      final List<dynamic> list = raw is List ? raw : const [];
      _buckets = list
          .whereType<Map>()
          .map((e) => SavingsSummary.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return _buckets;
    } catch (e) {
      _error = e;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _buckets = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}

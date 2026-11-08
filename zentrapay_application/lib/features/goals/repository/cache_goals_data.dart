import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/core/models/goals.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrow_data.dart'
    as zgrow;

/// Save Goal data: the user's goals AND their recent saving activity, both loaded from the backend
/// (`/api/zbanking/savings`, `/api/zbanking/savings/activity`).
///
/// This section owns its data. It overlaps with other sections in one direction only: when money
/// moves, the repositories that show that money ([WalletsRepository] balances, [TransactionsRepository]
/// history, ZGrow's "Overall Savings") are told to reload - see [_moneyMoved].
class GoalsRepository extends ChangeNotifier {
  GoalsRepository._();
  static final GoalsRepository instance = GoalsRepository._();

  /// How many activity rows the screen asks for.
  static const int activityLimit = 30;

  final Dio _dio = ApiClient().dio;

  List<SavingsGoal>? _goals;
  List<GoalActivity>? _activity;
  bool _loading = false;
  Object? _error;
  Object? _activityError;

  List<SavingsGoal>? get goals => _goals;

  /// Newest first. Null until the first load finished (an empty list means "no activity yet").
  List<GoalActivity>? get activity => _activity;
  bool get isLoaded => _goals != null;
  bool get isLoading => _loading;

  /// Why the goals could not be loaded. The activity list failing does not set this.
  Object? get error => _error;
  Object? get activityError => _activityError;

  Future<List<SavingsGoal>> _fetchGoals() async {
    final response = await _dio.get('/api/zbanking/savings');
    return _list(response.data).map(SavingsGoal.fromJson).toList();
  }

  Future<List<GoalActivity>> _fetchActivity() async {
    final response = await _dio.get(
      '/api/zbanking/savings/activity',
      queryParameters: {'limit': activityLimit},
    );
    return _list(response.data).map(GoalActivity.fromJson).toList();
  }

  static List<Map<String, dynamic>> _list(dynamic body) {
    final raw = body is Map ? body['data'] : null;
    return [
      if (raw is List)
        for (final e in raw)
          if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  /// Loads goals and activity the first time they are needed; later calls do nothing unless
  /// [forceRefresh] is set (pull-to-refresh, retry). The goals are what matters: if only the
  /// activity fails, the goals still show and [activityError] says why the list is empty.
  Future<List<SavingsGoal>?> ensureLoaded({bool forceRefresh = false}) async {
    if (_goals != null && !forceRefresh) return _goals;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object?>([
        _fetchGoals(),
        _fetchActivity().then<List<GoalActivity>?>((a) => a).catchError((
          Object e,
        ) {
          _activityError = e;
          return null;
        }),
      ]);
      _goals = results[0] as List<SavingsGoal>;
      final activity = results[1] as List<GoalActivity>?;
      if (activity != null) {
        _activity = activity;
        _activityError = null;
      }
      return _goals;
    } catch (e) {
      _error = e;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => ensureLoaded(forceRefresh: true);

  /// Reloads just the activity list (after a move) without blanking the screen.
  Future<void> _reloadActivity() async {
    try {
      _activity = await _fetchActivity();
      _activityError = null;
    } catch (e) {
      _activityError = e;
    }
    notifyListeners();
  }

  void clear() {
    _goals = null;
    _activity = null;
    _error = null;
    _activityError = null;
    _loading = false;
    notifyListeners();
  }

  // ------------------------------------------------------------ cache edits

  void _replace(SavingsGoal updated) {
    final current = _goals;
    if (current == null) return;
    _goals = [
      for (final g in current) g.savingsId == updated.savingsId ? updated : g,
    ];
    notifyListeners();
  }

  void _add(SavingsGoal goal) {
    _goals = [goal, ...?_goals];
    notifyListeners();
  }

  void _remove(String savingsId) {
    final current = _goals;
    if (current == null) return;
    _goals = current.where((g) => g.savingsId != savingsId).toList();
    notifyListeners();
  }

  /// Money moved (or a refused attempt was recorded): refresh everything that shows it.
  void _moneyMoved() {
    _reloadActivity();
    WalletsRepository.instance.refresh().catchError((_) => null);
    TransactionsRepository.instance
        .ensureLoaded(forceRefresh: true)
        .catchError((_) => null);
    zgrow.SavingsRepository.instance
        .ensureLoaded(forceRefresh: true)
        .catchError((_) => null);
  }

  // ---------------------------------------------------------------- actions

  SavingsGoal _goalFrom(Response<dynamic> response) =>
      SavingsGoal.fromJson(Map<String, dynamic>.from(response.data['data']));

  Future<SavingsGoal> create({
    required String savingsName,
    required String currencyCode,
    required String initialDeposit,
    String? targetAmount,
    String? targetDate,
    String? description,
  }) async {
    try {
      final response = await _dio.post(
        '/api/zbanking/savings',
        data: {
          'savingsName': savingsName,
          'currencyCode': currencyCode,
          'initialDeposit': initialDeposit,
          'targetAmount': ?targetAmount,
          'targetDate': ?targetDate,
          'description': ?description,
        },
      );
      final goal = _goalFrom(response);
      _add(goal);
      _moneyMoved();
      return goal;
    } catch (_) {
      // The goal itself may exist even when its first deposit was refused
      refresh().catchError((_) {});
      _moneyMoved();
      rethrow;
    }
  }

  Future<SavingsGoal> deposit(String savingsId, String amount) =>
      _move(savingsId, 'deposit', amount);

  Future<SavingsGoal> withdraw(String savingsId, String amount) =>
      _move(savingsId, 'withdraw', amount);

  Future<SavingsGoal> _move(String savingsId, String kind, String amount) async {
    try {
      final response = await _dio.post(
        '/api/zbanking/savings/$savingsId/$kind',
        data: {'amount': amount},
      );
      final goal = _goalFrom(response);
      _replace(goal);
      _moneyMoved();
      return goal;
    } catch (_) {
      // A refused move is saved on the server as a FAILED row: show it
      _reloadActivity();
      rethrow;
    }
  }

  /// Stops saving into the goal for [days] (1 to [SavingsGoal.maxFreezeDays]).
  Future<SavingsGoal> freeze(String savingsId, int days) async {
    final response = await _dio.post(
      '/api/zbanking/savings/$savingsId/freeze',
      data: {'days': days},
    );
    final goal = _goalFrom(response);
    _replace(goal);
    return goal;
  }

  Future<SavingsGoal> unfreeze(String savingsId) async {
    final response = await _dio.post('/api/zbanking/savings/$savingsId/unfreeze');
    final goal = _goalFrom(response);
    _replace(goal);
    return goal;
  }

  Future<SavingsGoal> setAutoSave(
    String savingsId, {
    required String amount,
    required AutoSaveFrequency frequency,
  }) async {
    final response = await _dio.put(
      '/api/zbanking/savings/$savingsId/auto-save',
      data: {'amount': amount, 'frequency': frequency.wire},
    );
    final goal = _goalFrom(response);
    _replace(goal);
    return goal;
  }

  Future<SavingsGoal> disableAutoSave(String savingsId) async {
    final response = await _dio.delete('/api/zbanking/savings/$savingsId/auto-save');
    final goal = _goalFrom(response);
    _replace(goal);
    return goal;
  }

  /// Deletes the goal; the backend returns whatever was saved in it to the wallet first.
  /// Resolves to the amount that went back to the wallet.
  Future<double> delete(String savingsId) async {
    try {
      final response = await _dio.delete('/api/zbanking/savings/$savingsId');
      final data = response.data['data'];
      final returned = data is Map
          ? (data['returnedAmount'] as num?)?.toDouble() ?? 0.0
          : 0.0;
      _remove(savingsId);
      _moneyMoved();
      return returned;
    } catch (_) {
      _reloadActivity();
      rethrow;
    }
  }
}

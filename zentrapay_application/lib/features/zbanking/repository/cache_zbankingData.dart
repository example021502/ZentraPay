import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

/// ZBanking data caches: linked savings accounts, loans, budgeting, banking
/// insights and savings goals. Every repository implements the
/// "load once, then apply deltas" contract inline — there is no shared
/// abstract cache base anymore; each repository owns its own state and
/// notifies listeners.
///
/// Shared app-wide: the ZGrow hero, the Profile screen and the Payments
/// Milestones screen import this file for the repositories they need.

/// User's ZBank Lite accounts (`GET /api/zbanking/accounts`).
  final Dio _dio = ApiClient().dio;
class BankAccountsRepository extends ChangeNotifier {
  BankAccountsRepository._();
  static final BankAccountsRepository instance = BankAccountsRepository._();


  List<BankAccounts>? _data;
  bool _loading = false;
  Object? _error;

  List<BankAccounts>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<BankAccounts>> fetch() async {
    final response = await _dio.get('/api/zbanking/accounts');
    // Backend AccountsResponseDTO wraps the list: data: {accounts: [...]}.
    final data = response.data['data'];
    final accounts = (data is Map && data['accounts'] is List)
        ? (data['accounts'] as List)
        : const <dynamic>[];
    return accounts.map((e) => BankAccounts.fromJson(e)).toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<BankAccounts>?> ensureLoaded({bool forceRefresh = false}) async {
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
    List<BankAccounts> Function(List<BankAccounts> current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<BankAccounts> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(BankAccounts item) =>
      applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(BankAccounts item) matches,
    BankAccounts replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(BankAccounts item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  Future<BankAccounts> create({
    required String savingsName,
    required String bankId,
    String? description,
  }) async {
    final response = await _dio.post(
      '/api/zbanking/new',
      data: {
        'savingsName': savingsName,
        'bankID': bankId,
        'description': ?description,
      },
    );
    final account = BankAccounts.fromJson(response.data['data']);
    addItem(account);
    return account;
  }

  Future<BankAccounts> deposit(String savingsId, String amount) async {
    final response = await _dio.post(
      '/api/zbanking/savings/$savingsId/deposit',
      data: {'amount': amount},
    );
    final account = BankAccounts.fromJson(response.data['data']);
    replaceItem((s) => s.bankId == savingsId, account);
    return account;
  }

  /*
=====================================================================
* WITHDRAWAL
=====================================================================
*/
  Future<BankAccounts> withdraw(String savingsId, String amount) async {
    final response = await _dio.post(
      '/api/zbanking/savings/$savingsId/withdraw',
      data: {'amount': amount},
    );
    final account = BankAccounts.fromJson(response.data['data']);
    replaceItem((s) => s.bankId == savingsId, account);
    return account;
  }
}

/*
=====================================================================
* BANKING LOANS
=====================================================================
*/

/// ZBank Lite loans (`GET /api/zbanking/loans`).
class LoansRepository extends ChangeNotifier {
  LoansRepository._();
  static final LoansRepository instance = LoansRepository._();

  final Dio _dio = ApiClient().dio;

  List<Loan>? _data;
  bool _loading = false;
  Object? _error;

  List<Loan>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /*
=====================================================================
* FETCHING LOANS
=====================================================================
*/
  /// The actual network call.
  Future<List<Loan>> fetch() async {
    final response = await _dio.get('/api/zbanking/loans');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => Loan.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<Loan>?> ensureLoaded({bool forceRefresh = false}) async {
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
  void applyDelta(List<Loan> Function(List<Loan> current) updater) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<Loan> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(Loan item) => applyDelta((current) => [...current, item]);

  void replaceItem(bool Function(Loan item) matches, Loan replacement) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(Loan item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  /*
=====================================================================
* LOAN APPLICATION
=====================================================================
*/
  Future<Loan> apply({
    required String amount,
    required String currencyCode,
    required int termMonths,
  }) async {
    final response = await _dio.post(
      '/api/zbanking/loans/apply',
      data: {
        'amount': amount,
        'currencyCode': currencyCode,
        'termMonths': termMonths,
      },
    );
    final loan = Loan.fromJson(response.data['data']);
    addItem(loan);
    return loan;
  }

  /*
=====================================================================
* BANKING LOANS
=====================================================================
*/
  Future<Loan> repay(String loanId, String amount) async {
    final response = await _dio.post(
      '/api/zbanking/loans/$loanId/repay',
      data: {'amount': amount},
    );
    final loan = Loan.fromJson(response.data['data']);
    replaceItem((l) => l.loanId == loanId, loan);
    return loan;
  }
}

/*
=====================================================================
* BANKING BUDGETING
=====================================================================
*/

/// Monthly budget summary (`GET/PUT /api/zbanking/budget`). Single-value
/// cache.
class BudgetRepository extends ChangeNotifier {
  BudgetRepository._();
  static final BudgetRepository instance = BudgetRepository._();

  final Dio _dio = ApiClient().dio;

  BudgetSummary? _data;
  bool _loading = false;
  Object? _error;

  BudgetSummary? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<BudgetSummary> fetch() async {
    final response = await _dio.get('/api/zbanking/budget');
    return BudgetSummary.fromJson(response.data['data']);
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<BudgetSummary?> ensureLoaded({bool forceRefresh = false}) async {
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
  void applyDelta(BudgetSummary Function(BudgetSummary current) updater) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright (a PUT here returns the full new
  /// summary rather than something to merge).
  void setData(BudgetSummary value) {
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

  Future<BudgetSummary> setMonthlyLimit(String monthlyLimit) async {
    final response = await _dio.put(
      '/api/zbanking/budget',
      data: {'monthlyLimit': monthlyLimit},
    );
    final summary = BudgetSummary.fromJson(response.data['data']);
    setData(summary);
    return summary;
  }
}

/*
=================================================================
* BANKING INSIGHTS
=================================================================
*/

/// Aggregated banking insights (`GET /api/zbanking/insights`). Single-value
/// read-only cache.
class BankingInsightsRepository extends ChangeNotifier {
  BankingInsightsRepository._();
  static final BankingInsightsRepository instance =
      BankingInsightsRepository._();

  final Dio _dio = ApiClient().dio;

  BankingInsights? _data;
  bool _loading = false;
  Object? _error;

  BankingInsights? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<BankingInsights> fetch() async {
    final response = await _dio.get('/api/zbanking/insights');
    return BankingInsights.fromJson(response.data['data']);
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<BankingInsights?> ensureLoaded({bool forceRefresh = false}) async {
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
  void applyDelta(BankingInsights Function(BankingInsights current) updater) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(BankingInsights value) {
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

/// User's ZBank Lite savings "goals" — aligned to API_CONTRACT.md §13
/// (`/api/zbanking/savings`). Restored so consumers like the Milestones
/// screen have a backend-shaped repository again.
class SavingsRepository extends ChangeNotifier {
  SavingsRepository._();
  static final SavingsRepository instance = SavingsRepository._();

  final Dio _dio = ApiClient().dio;

  List<SavingsAccount>? _data;
  bool _loading = false;
  Object? _error;

  List<SavingsAccount>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<SavingsAccount>> fetch() async {
    final response = await _dio.get('/api/zbanking/savings');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => SavingsAccount.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<SavingsAccount>?> ensureLoaded({
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
    List<SavingsAccount> Function(List<SavingsAccount> current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<SavingsAccount> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(SavingsAccount item) =>
      applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(SavingsAccount item) matches,
    SavingsAccount replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(SavingsAccount item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  Future<SavingsAccount> create({
    required String savingsName,
    required String currencyCode,
    required String initialDeposit,
    String? targetAmount,
    String? targetDate,
    String? description,
  }) async {
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
    final account = SavingsAccount.fromJson(response.data['data']);
    addItem(account);
    return account;
  }

  Future<SavingsAccount> deposit(String savingsId, String amount) async {
    final response = await _dio.post(
      '/api/zbanking/savings/$savingsId/deposit',
      data: {'amount': amount},
    );
    final account = SavingsAccount.fromJson(response.data['data']);
    replaceItem((s) => s.savingsId == savingsId, account);
    return account;
  }

  Future<SavingsAccount> withdraw(String savingsId, String amount) async {
    final response = await _dio.post(
      '/api/zbanking/savings/$savingsId/withdraw',
      data: {'amount': amount},
    );
    final account = SavingsAccount.fromJson(response.data['data']);
    replaceItem((s) => s.savingsId == savingsId, account);
    return account;
  }
}




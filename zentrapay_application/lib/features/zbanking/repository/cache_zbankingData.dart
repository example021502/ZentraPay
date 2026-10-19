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

/// User's ZBank Lite accounts (`GET /api/zbanking/userAccounts`).
final Dio _dio = ApiClient().dio;

class BankAccountsRepository extends ChangeNotifier {
  BankAccountsRepository._();
  static final BankAccountsRepository instance = BankAccountsRepository._();

  BankAccountsSnapshot? _data;
  bool _loading = false;
  Object? _error;

  /// Full snapshot: `primary` (header card) + `accounts` (bottom strip).
  BankAccountsSnapshot? get data => _data;

  /// Every linked account, primary included. Empty until loaded.
  List<BankAccounts> get accounts => _data?.accounts ?? const [];

  /// The single primary account rendered in the header, if any.
  BankAccounts? get primary => _data?.primary;

  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call — parses the `UserAccountsResponseDTO` envelope.
  Future<BankAccountsSnapshot> fetch() async {
    final response = await _dio.get('/api/zbanking/userAccounts');
    // Backend wraps the payload: data: {primary: {...}, accounts: [...]}.
    final data = response.data['data'];
    if (data is Map<String, dynamic>) {
      return BankAccountsSnapshot.fromJson(data);
    }
    return BankAccountsSnapshot.empty;
  }

  /// Loads the snapshot the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, post-mutation refetch).
  Future<BankAccountsSnapshot?> ensureLoaded({
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

  /// Refreshes after a link/promote/unlink so the header and strip stay true.
  Future<void> refresh() => ensureLoaded(forceRefresh: true);

  /// Replaces the cached snapshot outright (used by refresh + tests).
  void setData(BankAccountsSnapshot value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /* ------------------------------------------------------- mutations */

  /// Links a bank from the catalog (`POST /api/zbanking/link`), then refreshes
  /// the snapshot so the header/strip pick it up.
  ///
  /// [firstName]/[lastName] are the account holder's names exactly as typed in
  /// the sheet — both are required by the backend DTO and are forwarded in the
  /// open-banking linking request to AfriqLink (our bank-data provider).
  ///
  /// [primary] promotes this account to the header immediately; the first bank
  /// a user ever links is promoted server-side regardless.
  Future<BankAccounts> linkBank({
    required String bankId,
    required String accountNumber,
    String? linkLabel,
    bool primary = false,
  }) async {
    final response = await _dio.post(
      '/api/zbanking/link',
      data: {
        'bankId': bankId,
        'accountNumber': accountNumber,
        'primary': primary,
        if (linkLabel != null && linkLabel.trim().isNotEmpty)
          'linkLabel': linkLabel.trim(),
      },
    );
    // The POST response already carries the linked account (including the
    // primary flag the server decided), so trust it directly: refreshing
    // afterwards is best-effort, because a transient refetch failure must never
    // turn an already-successful link into "Could not link that bank" — the
    // retry would then fail again with "already linked".
    final linked = BankAccounts.fromJson(response.data['data']);
    try {
      await refresh();
    } catch (_) {
      // Snapshot stays as-is; the next load/refresh catches up.
    }
    return linked;
  }

  /// Promotes an already-linked account to be the header primary.
  ///
  /// [userBankId] is the *link* row id — deliberately not the catalog bank id.
  /// Optimistically flips the flag locally so the header updates instantly,
  /// then refetches to confirm what the server actually persisted.
  Future<void> setPrimary(String userBankId) async {
    // Optimistic: mark this one primary, demote the rest in the cache.
    final current = _data;
    if (current != null) {
      final promoted = current.accounts.firstWhere(
        (a) => a.userBankId == userBankId,
        orElse: () => current.accounts.first,
      );
      setData(
        BankAccountsSnapshot(
          primary: promoted.copyWith(isPrimary: true),
          accounts: [
            for (final a in current.accounts)
              a.copyWith(isPrimary: a.userBankId == userBankId),
          ],
        ),
      );
    }

    await _dio.post('/api/zbanking/primary/$userBankId');
    await refresh();
  }

  /// Unlinks one of the user's banks (`DELETE /api/zbanking/unlink/{id}`), then
  /// refreshes (the backend promotes another account to primary if needed).
  Future<void> unlinkBank(String userBankId) async {
    await _dio.delete('/api/zbanking/unlink/$userBankId');
    await refresh();
  }

  /// Read-only bank catalog for the "link a bank" sheet.
  ///
  /// Public endpoint, so it never needs the auth token and never throws on an
  /// empty catalog — callers render an empty-picker state themselves.
  Future<List<BankCatalogEntry>> fetchBankCatalog({
    String query = '',
    String? country,
  }) async {
    final response = await _dio.get(
      '/api/reference/banks',
      queryParameters: {
        if (query.trim().isNotEmpty) 'query': query.trim(),
        if (country != null && country.isNotEmpty) 'country': country,
      },
    );
    final data = response.data['data'];
    final banks = (data is List) ? data : const <dynamic>[];
    return banks
        .whereType<Map<String, dynamic>>()
        .map(BankCatalogEntry.fromJson)
        .toList();
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
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

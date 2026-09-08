import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/core/models/bill_service_provider.dart';
import 'package:zentrapay_application/core/models/card.dart';
import 'package:zentrapay_application/core/models/notification.dart';
import 'package:zentrapay_application/core/models/reference_data.dart';
import 'package:zentrapay_application/core/models/search_result.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/core/models/wallet.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

/// Home-screen data caches: wallets, cards, transactions, notifications,
/// bill/service provider directories, reference data, payment channels and
/// contact search. Every cached resource here implements the
/// "load once, then apply deltas" contract inline — there is no shared
/// abstract cache base anymore; each repository owns its own state and
/// notifies its listeners directly.
///
/// These caches are shared app-wide: Profile, Payments, Settings and the
/// bottom navigation bar import this file for the repositories they need.

/// Backs every screen that shows wallet balances (Home, Profile, Pay/Send,
/// Milestones' "add to goal" source picker, ...). Loaded once per app
/// session; wallet-affecting operations elsewhere (creating a wallet,
/// making a transfer that changes the sender's balance) call
/// [applyDelta]/[upsertFiatWallet] instead of forcing every listener to
/// refetch.
class WalletsRepository with ChangeNotifier {
  WalletsRepository._();
  static final WalletsRepository instance = WalletsRepository._();

  final Dio _dio = ApiClient().dio;

  // Local state fields managing cached resource lifecycle
  WalletsAccountsSnapshot? _data;
  Object? _error;
  bool _isLoading = false;

  /// Public accessors for local state
  WalletsAccountsSnapshot? get data => _data;
  Object? get error => _error;
  bool get isLoading => _isLoading;
  bool get isLoaded => _data != null;

  /// Retrieves cached snapshot or fetches fresh data if cache is empty
  Future<WalletsAccountsSnapshot?> ensureLoaded() async {
    if (isLoaded) return _data;
    return refresh();
  }

  /// Forces a GET request to update local wallet balances from server
  Future<WalletsAccountsSnapshot?> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dio.get('/api/wallet/balances');
      _data = WalletsAccountsSnapshot.fromJson(
        Map<String, dynamic>.from(response.data['data'] as Map),
      );
      return _data;
    } catch (e) {
      _error = e;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Modifies local state using delta function without re-fetching API
  void applyDelta(
    WalletsAccountsSnapshot Function(WalletsAccountsSnapshot current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces local cache data outright and notifies active UI listeners
  void setData(WalletsAccountsSnapshot value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// Clears cached state on user logout or session reset
  void clear() {
    _data = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Upserts single fiat account record into cached snapshot
  void upsertFiatWallet(FiatAccount account) {
    applyDelta((current) => current.withUpsertedFiatWallet(account));
  }

  /// Creates new fiat account on server and appends to local cache
  Future<FiatAccount> createFiatAccount({
    required String accountName,
    required String currencyCode,
    String? countryCode,
  }) async {
    final response = await _dio.post(
      '/api/wallet/newFiat',
      data: {
        'accountName': accountName,
        'currencyCode': currencyCode,
        if (countryCode != null) 'countryCode': countryCode,
      },
    );

    final account = FiatAccount.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
    upsertFiatWallet(account);
    return account;
  }

  /// Convenience getter for default fiat account selection
  FiatAccount? get defaultWallet {
    final accounts = data?.fiatAccounts ?? [];
    if (accounts.isEmpty) return null;
    return accounts.firstWhere(
      (a) => a.isDefault,
      orElse: () => accounts.first,
    );
  }

  /// Retrieves list of supported platform currencies from backend endpoint
  Future<List<SupportedCurrencies>> getSupportedCurrencies() async {
    final response = await _dio.post('/api/wallet/supportedCurrencies');

    final List<dynamic> rawList = (response.data['data']) ?? [];
    final currencies = rawList
        .map((e) => SupportedCurrencies.fromJson(e as Map<String, dynamic>))
        .toList();

    return currencies;
  }
}

/// Backs the Home screen's linked-card surfaces (quick actions' virtual-card
/// creation and the NFC/QR toggles). List cache with in-place item replaces.
class CardsRepository extends ChangeNotifier {
  CardsRepository._();
  static final CardsRepository instance = CardsRepository._();

  final Dio _dio = ApiClient().dio;

  List<AppCard>? _data;
  bool _loading = false;
  Object? _error;

  List<AppCard>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<AppCard>> fetch() async {
    final response = await _dio.get('/api/cards');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => AppCard.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<AppCard>?> ensureLoaded({bool forceRefresh = false}) async {
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
  void applyDelta(List<AppCard> Function(List<AppCard> current) updater) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<AppCard> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(AppCard item) => applyDelta((current) => [...current, item]);

  void replaceItem(bool Function(AppCard item) matches, AppCard replacement) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(AppCard item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  Future<AppCard> createVirtualCard(String brand) async {
    final response = await _dio.post(
      '/api/cards/virtual',
      data: {'brand': brand},
    );
    final card = AppCard.fromJson(response.data['data']);
    addItem(card);
    return card;
  }

  Future<AppCard> setNfcEnabled(String cardId, bool enabled) async {
    final response = await _dio.patch(
      '/api/cards/$cardId/nfc',
      data: {'enabled': enabled},
    );
    final card = AppCard.fromJson(response.data['data']);
    replaceItem((c) => c.cardId == cardId, card);
    return card;
  }

  Future<AppCard> setQrEnabled(String cardId, bool enabled) async {
    final response = await _dio.patch(
      '/api/cards/$cardId/qr',
      data: {'enabled': enabled},
    );
    final card = AppCard.fromJson(response.data['data']);
    replaceItem((c) => c.cardId == cardId, card);
    return card;
  }
}

/// Transaction history is paginated, so it doesn't fit the plain
/// single-value cache shape: the "load once" behavior here means page 0 is
/// fetched once and cached; scrolling further pages appends rather than
/// refetching everything, and a new transaction posted elsewhere (a
/// transfer, a bill payment...) is prepended locally instead of re-querying
/// page 0.
class TransactionsRepository extends ChangeNotifier {
  TransactionsRepository._();

  static final TransactionsRepository instance = TransactionsRepository._();

  final Dio _dio = ApiClient().dio;

  final List<AppTransaction> _items = [];
  int _page = 0;
  int _totalPages = 1;
  bool _loading = false;
  bool _loadedOnce = false;

  List<AppTransaction> get items => List.unmodifiable(_items);

  bool get isLoading => _loading;

  bool get hasMore => _page + 1 < _totalPages;

  Future<void> ensureLoaded({bool forceRefresh = false}) async {
    if (_loadedOnce && !forceRefresh) return;
    _loading = true;
    notifyListeners();
    try {
      final result = await _fetchPage(0);
      _items
        ..clear()
        ..addAll(result.content);
      _page = result.page;
      _totalPages = result.totalPages;
      _loadedOnce = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadNextPage() async {
    if (!hasMore || _loading) return;
    _loading = true;
    notifyListeners();
    try {
      final result = await _fetchPage(_page + 1);
      _items.addAll(result.content);
      _page = result.page;
      _totalPages = result.totalPages;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<TransactionPage> _fetchPage(int page) async {
    final response = await _dio.get(
      '/api/transactions',
      queryParameters: {'page': page, 'size': 20},
    );
    return TransactionPage.fromJson(response.data['data']);
  }

  /// Called after a POST elsewhere (payment, bill pay, savings deposit...)
  /// returns the resulting Transaction — no need to refetch page 0.
  ///
  /// A contact that already appears in the list must NOT be inserted again
  /// (the Recent Payments strip derives straight from these items), so the
  /// incoming transaction is matched against existing entries by normalized
  /// identifier first, then by display name; empty/null fields never match.
  void prepend(AppTransaction transaction) {
    final exists = _items.any((item) => _sameContact(item, transaction));
    if (!exists) {
      _items.insert(0, transaction);
      notifyListeners();
    }
  }

  /// True when [a] and [b] refer to the same counterparty. Comparison is
  /// trimmed + case-insensitive; identifier wins over name, and two records
  /// without any usable field are treated as different contacts.
  static bool _sameContact(AppTransaction a, AppTransaction b) {
    final aId = a.receiverId.trim().toLowerCase();
    final bId = b.receiverId.trim().toLowerCase();
    if (aId.isNotEmpty && bId.isNotEmpty) return aId == bId;

    final aName = a.receiverName.trim().toLowerCase();
    final bName = b.receiverName.trim().toLowerCase();
    if (aName.isNotEmpty && bName.isNotEmpty) return aName == bName;

    return false;
  }
}

/// Backs the home screen's notification-bell overlay — `GET/PATCH
/// /api/notifications`. "Load once, apply deltas": mark-as-read patches the
/// cached item in place instead of re-fetching the whole list.
class NotificationsRepository extends ChangeNotifier {
  NotificationsRepository._();
  static final NotificationsRepository instance = NotificationsRepository._();

  final Dio _dio = ApiClient().dio;

  List<AppNotification>? _data;
  bool _loading = false;
  Object? _error;

  List<AppNotification>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// Count of unread notifications — drives the bell's badge dot.
  int get unreadCount => (data ?? []).where((n) => !n.isRead).length;

  /// The actual network call.
  Future<List<AppNotification>> fetch() async {
    final response = await _dio.get('/api/notifications');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<AppNotification>?> ensureLoaded({
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
    List<AppNotification> Function(List<AppNotification> current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<AppNotification> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(AppNotification item) =>
      applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(AppNotification item) matches,
    AppNotification replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(AppNotification item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  Future<void> markRead(String notificationId) async {
    // Comment: optimistic — flip it locally first so the tap feels instant,
    // then fire the request. A failure here is low-stakes (a read flag)
    // and self-heals on the next refresh, so no revert-on-failure needed.
    applyDelta(
      (current) => [
        for (final n in current)
          n.notificationId == notificationId ? n.copyWith(isRead: true) : n,
      ],
    );
    try {
      await _dio.patch('/api/notifications/$notificationId/read');
    } catch (_) {
      // Comment: swallow — see note above.
    }
  }
}

/// Bill-payment history (`GET /api/bill-providers/history`). Read-only list
/// cache.
class BillPaymentHistoryRepository extends ChangeNotifier {
  BillPaymentHistoryRepository._();
  static final BillPaymentHistoryRepository instance =
      BillPaymentHistoryRepository._();

  final Dio _dio = ApiClient().dio;

  List<BillPaymentRecord>? _data;
  bool _loading = false;
  Object? _error;

  List<BillPaymentRecord>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<BillPaymentRecord>> fetch() async {
    final response = await _dio.get('/api/bill-providers/history');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => BillPaymentRecord.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<BillPaymentRecord>?> ensureLoaded({
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
    List<BillPaymentRecord> Function(List<BillPaymentRecord> current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<BillPaymentRecord> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(BillPaymentRecord item) =>
      applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(BillPaymentRecord item) matches,
    BillPaymentRecord replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(BillPaymentRecord item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}

/// Service-provider directory (`GET /api/service-providers`) — backs the
/// Home wallet main "services" strip.
class ServiceProvidersRepository extends ChangeNotifier {
  ServiceProvidersRepository._();
  static final ServiceProvidersRepository instance =
      ServiceProvidersRepository._();

  final Dio _dio = ApiClient().dio;

  List<ServiceProvider>? _data;
  bool _loading = false;
  Object? _error;

  List<ServiceProvider>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<ServiceProvider>> fetch() async {
    final response = await _dio.get('/api/service-providers');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => ServiceProvider.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<ServiceProvider>?> ensureLoaded({
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
    List<ServiceProvider> Function(List<ServiceProvider> current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<ServiceProvider> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(ServiceProvider item) =>
      applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(ServiceProvider item) matches,
    ServiceProvider replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(ServiceProvider item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}

/// Bill-payment provider directory (`GET /api/bill-providers`) — backs the
/// Home services grid, quick actions and the provider picker sheet. The
/// validate/pay calls are deliberate user actions, not cached resources,
/// but they flow through here so the Home surfaces share one client.
class BillProvidersRepository extends ChangeNotifier {
  BillProvidersRepository._();
  static final BillProvidersRepository instance = BillProvidersRepository._();

  final Dio _dio = ApiClient().dio;

  List<BillProvider>? _data;
  bool _loading = false;
  Object? _error;

  List<BillProvider>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<BillProvider>> fetch() async {
    final response = await _dio.get('/api/bill-providers');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => BillProvider.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<BillProvider>?> ensureLoaded({bool forceRefresh = false}) async {
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
    List<BillProvider> Function(List<BillProvider> current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<BillProvider> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(BillProvider item) =>
      applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(BillProvider item) matches,
    BillProvider replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(BillProvider item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> validate({
    required String providerId,
    required String customerReference,
  }) async {
    final response = await _dio.post(
      '/api/bill-providers/validate',
      data: {'providerId': providerId, 'customerReference': customerReference},
    );
    return response.data['data'] ?? {};
  }

  Future<Map<String, dynamic>> pay({
    required String pin,
    required String providerId,
    required String customerReference,
    required String amount,
    required String currencyCode,
  }) async {
    final response = await _dio.post(
      '/api/bill-providers/pay',
      data: {
        'pin': pin,
        'providerId': providerId,
        'customerReference': customerReference,
        'amount': amount,
        'currencyCode': currencyCode,
      },
    );
    return response.data['data'] ?? {};
  }
}

/// Countries/currencies/categories never change during a session (and
/// barely change at all) — this is the purest case of "load once and keep
/// forever." Every dropdown/picker across signup, wallet creation, and bill
/// payment reads from these three singletons instead of hitting the network
/// each time a picker opens.
class CountriesRepository extends ChangeNotifier {
  CountriesRepository._();
  static final CountriesRepository instance = CountriesRepository._();

  final Dio _dio = ApiClient().dio;

  List<AppCountry>? _data;
  bool _loading = false;
  Object? _error;

  List<AppCountry>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<AppCountry>> fetch() async {
    final response = await _dio.get('/api/reference/countries');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => AppCountry.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<AppCountry>?> ensureLoaded({bool forceRefresh = false}) async {
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
    List<AppCountry> Function(List<AppCountry> current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<AppCountry> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(AppCountry item) => applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(AppCountry item) matches,
    AppCountry replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(AppCountry item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}

/// Supported platform currencies (`GET /api/reference/currencies`).
class CurrenciesRepository extends ChangeNotifier {
  CurrenciesRepository._();
  static final CurrenciesRepository instance = CurrenciesRepository._();

  final Dio _dio = ApiClient().dio;

  List<AppCurrency>? _data;
  bool _loading = false;
  Object? _error;

  List<AppCurrency>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<AppCurrency>> fetch() async {
    final response = await _dio.get('/api/reference/currencies');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => AppCurrency.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<AppCurrency>?> ensureLoaded({bool forceRefresh = false}) async {
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
    List<AppCurrency> Function(List<AppCurrency> current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<AppCurrency> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(AppCurrency item) =>
      applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(AppCurrency item) matches,
    AppCurrency replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(AppCurrency item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}

/// Bill-provider categories (`GET /api/reference/provider-categories`).
class ProviderCategoriesRepository extends ChangeNotifier {
  ProviderCategoriesRepository._();
  static final ProviderCategoriesRepository instance =
      ProviderCategoriesRepository._();

  final Dio _dio = ApiClient().dio;

  List<ProviderCategory>? _data;
  bool _loading = false;
  Object? _error;

  List<ProviderCategory>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<ProviderCategory>> fetch() async {
    final response = await _dio.get('/api/reference/provider-categories');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => ProviderCategory.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<ProviderCategory>?> ensureLoaded({
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
    List<ProviderCategory> Function(List<ProviderCategory> current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<ProviderCategory> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(ProviderCategory item) =>
      applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(ProviderCategory item) matches,
    ProviderCategory replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(ProviderCategory item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}

/// Bank/mobile-money directory — cached per (countryCode, type) combination
/// since that's how the bank-select UI queries it (a fresh country/type
/// selection is a deliberate refetch, not a cache miss).
class PaymentChannelsRepository {
  PaymentChannelsRepository._();
  static final PaymentChannelsRepository instance =
      PaymentChannelsRepository._();

  final Dio _dio = ApiClient().dio;
  final Map<String, List<PaymentChannel>> _cache = {};

  Future<List<PaymentChannel>> load({
    required String countryCode,
    String? type,
  }) async {
    final key = '$countryCode:${type ?? ''}';
    final cached = _cache[key];
    if (cached != null) return cached;

    final response = await _dio.get(
      '/api/payment-channels',
      queryParameters: {
        'countryCode': countryCode,
        'type': ?type,
      },
    );
    final channels = ((response.data['data'] as List?) ?? [])
        .map((e) => PaymentChannel.fromJson(e))
        .toList();
    _cache[key] = channels;
    return channels;
  }

  Future<String?> resolveAccountName({
    required String channelCode,
    required String accountNumber,
  }) async {
    final response = await _dio.get(
      '/api/payment-channels/resolve',
      queryParameters: {
        'channelCode': channelCode,
        'accountNumber': accountNumber,
      },
    );
    return response.data['data']?['accountName'];
  }
}

/// Search-by-query is inherently not a "load once" resource (a new query is
/// a new request by definition) — this just centralizes the endpoint call
/// so every screen that searches contacts (Pay, Remit, transfer picker)
/// shares one implementation instead of three copies.
class SearchRepository {
  static final Dio _dio = ApiClient().dio;

  static Future<ContactSearchResult> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return ContactSearchResult.empty();
    // The query is part of the path (GET /api/search-contacts/{query}), so it
    // must be a single path segment. Search terms frequently contain spaces or
    // reserved characters (full names like "John Doe", formatted phone numbers,
    // zentags with dots, etc.) — interpolating them raw produces an invalid URL
    // and Dio throws a FormatException, so the search silently returns nothing.
    // Encode as a path segment; the backend's @PathVariable decodes it back.
    final encodedQuery = Uri.encodeComponent(trimmed);
    final response = await _dio.get(
      '/api/search/search-contacts/$encodedQuery',
    );
    return ContactSearchResult.fromJson(response.data['data']);
  }

  static Future<Map<String, dynamic>> targetSearch(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final response = await _dio.get('/api/search/search-contact/$encodedQuery');
    if (!response.data['success']) {
      return Map<String, dynamic>.from({});
    }
    return Map<String, dynamic>.from(response.data['data']['contact']);
  }
}









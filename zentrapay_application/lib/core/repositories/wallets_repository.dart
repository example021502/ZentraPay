import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/models/wallet.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

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

import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/models/wallet.dart';
import 'package:zentrapay_application/core/repositories/cached_resource.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

/// Backs every screen that shows wallet balances (Home, Profile, Pay/Send,
/// Milestones' "add to goal" source picker, ...). Loaded once per app
/// session; wallet-affecting operations elsewhere (creating a wallet,
/// making a transfer that changes the sender's balance) call
/// [applyDelta]/[upsertFiatWallet] instead of forcing every listener to
/// refetch.
class WalletsRepository extends CachedResource<WalletsAccountsSnapshot> {
  WalletsRepository._();
  static final WalletsRepository instance = WalletsRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<WalletsAccountsSnapshot> fetch() async {
    final response = await _dio.get('/api/wallet/balances');
    return WalletsAccountsSnapshot.fromJson(response.data['data']);
  }

  void upsertFiatWallet(FiatAccount account) {
    applyDelta((current) => current.withUpsertedFiatWallet(account));
  }

  Future<FiatAccount> createFiatAccount({
    required String accountName,
    required String currencyCode,
    String? countryCode,
  }) async {
    final response = await _dio.post(
      '/api/wallet/newFiat',
      data: {
        // Comment: matches CreateFiatAccountRequest on the backend
        // ({accountName, currencyCode, countryCode}).
        'accountName': accountName,
        'currencyCode': currencyCode,
        'countryCode': ?countryCode,
      },
    );
    final account = FiatAccount.fromJson(response.data['data']);
    upsertFiatWallet(account);
    return account;
  }

  FiatAccount? get defaultWallet {
    final accounts = data?.fiatAccounts ?? [];
    if (accounts.isEmpty) return null;
    return accounts.firstWhere(
      (a) => a.isDefault,
      orElse: () => accounts.first,
    );
  }

  // GETTING ALL THE SUPPORTED CURRENCIES
  Future<List<SupportedCurrencies>> getSupportedCurrencies() async {
    // Execute the POST request to fetch all supported currency options
    final response = await _dio.post('/api/wallet/supportedCurrencies');

    // Safely extract the list from the response payload and map each element
    final List<dynamic> rawList = (response.data['data']) ?? [];
    final currencies = rawList
        .map((e) => SupportedCurrencies.fromJson(e as Map<String, dynamic>))
        .toList();

    return currencies;
  }
}

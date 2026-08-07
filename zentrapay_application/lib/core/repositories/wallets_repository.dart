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
class WalletsRepository extends CachedResource<WalletsSnapshot> {
  WalletsRepository._();
  static final WalletsRepository instance = WalletsRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<WalletsSnapshot> fetch() async {
    final response = await _dio.get('/api/wallets');
    return WalletsSnapshot.fromJson(response.data['data']);
  }

  void upsertFiatWallet(FiatWallet wallet) {
    applyDelta((current) => current.withUpsertedFiatWallet(wallet));
  }

  Future<FiatWallet> createFiatWallet({
    required String walletName,
    required String currencyCode,
    String? countryCode,
  }) async {
    final response = await _dio.post(
      '/api/wallets/fiat',
      data: {
        'walletName': walletName,
        'currencyCode': currencyCode,
        'countryCode': ?countryCode,
      },
    );
    final wallet = FiatWallet.fromJson(response.data['data']);
    upsertFiatWallet(wallet);
    return wallet;
  }

  FiatWallet? get defaultWallet {
    final wallets = data?.fiatWallets ?? [];
    if (wallets.isEmpty) return null;
    return wallets.firstWhere((w) => w.isDefault, orElse: () => wallets.first);
  }

  // GETTING ALL THE SUPPORTED CURRENCIES
  Future<List<SupportedCurrencies>> getSupportedCurrencies() async {
    // Execute the POST request to fetch all supported currency options
    final response = await _dio.post('/api/wallets/supportedCurrencies');

    // Safely extract the list from the response payload and map each element
    final List<dynamic> rawList = (response.data['data']) ?? [];
    final currencies = rawList
        .map((e) => SupportedCurrencies.fromJson(e as Map<String, dynamic>))
        .toList();

    print("CURRENCIES RESPONSE IS:: $response");
    return currencies;
  }
}

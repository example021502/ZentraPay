class FiatWallet {
  final String walletId;
  final String walletName;
  final String currencyCode;
  final String? countryCode;
  final String balance;
  final bool isDefault;
  final String status;
  final int decimalDigits;

  FiatWallet({
    required this.walletId,
    required this.walletName,
    required this.currencyCode,
    this.countryCode,
    required this.balance,
    required this.isDefault,
    required this.status,
    required this.decimalDigits,
  });

  factory FiatWallet.fromJson(Map<String, dynamic> json) => FiatWallet(
    walletId: json['walletId'] ?? '',
    walletName: json['walletName'] ?? '',
    currencyCode: json['currencyCode'] ?? '',
    countryCode: json['countryCode'],
    balance: (json['balance'] ?? '0').toString(),
    isDefault: json['isDefault'] ?? false,
    status: json['status'] ?? 'ACTIVE',
    decimalDigits: json['decimalDigits'] ?? 2,
  );
}

/// Represents a single supported currency configuration item.
class SupportedCurrencies {
  final String currencyId;
  final String currencyCode;
  final String? currencyName;
  final String countryIsoCode;
  final int decimalDigits;

  SupportedCurrencies({
    required this.currencyId,
    required this.currencyCode,
    required this.currencyName,
    required this.countryIsoCode,
    required this.decimalDigits,
  });

  /// Factory constructor to parse a single JSON map into a SupportedCurrencies instance.
  factory SupportedCurrencies.fromJson(Map<String, dynamic> json) =>
      SupportedCurrencies(
        currencyId: json['currencyId'] ?? '',
        currencyCode: json['currencyCode'] ?? '',
        currencyName: json['currencyName'],
        countryIsoCode: json['countryIsoCode'] ?? '',
        decimalDigits: json['decimalDigits'] ?? 2,
      );
}

class CryptoWalletSummary {
  final String cryptoWalletId;
  final String currencyCode;
  final String? network;
  final String walletAddress;
  final String balance;
  final String status;
  final int decimalDigits;

  CryptoWalletSummary({
    required this.cryptoWalletId,
    required this.currencyCode,
    this.network,
    required this.walletAddress,
    required this.balance,
    required this.status,
    required this.decimalDigits,
  });

  factory CryptoWalletSummary.fromJson(Map<String, dynamic> json) =>
      CryptoWalletSummary(
        cryptoWalletId: json['cryptoWalletId'] ?? '',
        currencyCode: json['currencyCode'] ?? '',
        network: json['network'],
        walletAddress: json['walletAddress'] ?? '',
        balance: (json['balance'] ?? '0').toString(),
        status: json['status'] ?? 'ACTIVE',
        decimalDigits: json['decimalDigits'] ?? 8,
      );
}

class WalletsSnapshot {
  final List<FiatWallet> fiatWallets;
  final List<CryptoWalletSummary> cryptoWallets;

  WalletsSnapshot({required this.fiatWallets, required this.cryptoWallets});

  factory WalletsSnapshot.fromJson(Map<String, dynamic> json) =>
      WalletsSnapshot(
        fiatWallets: ((json['fiatWallets'] as List?) ?? [])
            .map((e) => FiatWallet.fromJson(e))
            .toList(),
        cryptoWallets: ((json['cryptoWallets'] as List?) ?? [])
            .map((e) => CryptoWalletSummary.fromJson(e))
            .toList(),
      );

  WalletsSnapshot copyWith({
    List<FiatWallet>? fiatWallets,
    List<CryptoWalletSummary>? cryptoWallets,
  }) => WalletsSnapshot(
    fiatWallets: fiatWallets ?? this.fiatWallets,
    cryptoWallets: cryptoWallets ?? this.cryptoWallets,
  );

  /// Replaces (by id) or appends a fiat wallet — used to apply a POST
  /// response into the cached snapshot without a full refetch.
  WalletsSnapshot withUpsertedFiatWallet(FiatWallet wallet) {
    final next =
        fiatWallets.where((w) => w.walletId != wallet.walletId).toList()
          ..add(wallet);
    return copyWith(fiatWallets: next);
  }
}

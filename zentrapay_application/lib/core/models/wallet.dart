class FiatAccount {
  final String accountId; // Comment: Stored as String for UUID in Dart
  final String accountName;
  final String currencyCode;
  final String zentag;

  // Comment: BigDecimal in Java maps to double or num in Dart
  final double balance;
  final bool isDefault;
  final String status;
  final DateTime createdAt;

  FiatAccount({
    required this.accountId,
    required this.accountName,
    required this.currencyCode,
    required this.zentag,
    required this.balance,
    required this.isDefault,
    required this.status,
    required this.createdAt,
  });

  // Comment: Factory constructor to parse JSON response from the Spring Boot API
  factory FiatAccount.fromJson(Map<String, dynamic> json) {
    return FiatAccount(
      accountId: json['accountId'] ?? '',
      accountName: json['accountName'] ?? '',
      currencyCode: json['currencyCode'] ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      isDefault: json['isDefault'] ?? false,
      status: json['status'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      zentag: json["zentag"] ?? '',
    );
  }
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
  // Comment: backend's SupportedCurrencyDTO has no separate currencyId — the
  // currency code doubles as the id — and its flag-country field is named
  // "countryCode", not "countryIsoCode".
  factory SupportedCurrencies.fromJson(Map<String, dynamic> json) =>
      SupportedCurrencies(
        currencyId: json['currencyId'] ?? json['currencyCode'] ?? '',
        currencyCode: json['currencyCode'] ?? '',
        currencyName: json['currencyName'],
        countryIsoCode: json['countryCode'] ?? json['countryIsoCode'] ?? '',
        decimalDigits: json['decimalDigits'] ?? 2,
      );
}

class CryptoAccount {
  final String cryptoAccountId; // Comment: Stored as String for UUID in Dart
  final String currencyCode;
  final String network;
  final String walletAddress;
  final bool isDefault;
  final String
  balance; // Comment: Maintained as String to preserve high-precision crypto decimals
  final String status;
  final DateTime createdAt;

  CryptoAccount({
    required this.cryptoAccountId,
    required this.currencyCode,
    required this.network,
    required this.walletAddress,
    required this.isDefault,
    required this.balance,
    required this.status,
    required this.createdAt,
  });

  // Comment: Factory constructor to parse JSON response from the Spring Boot API
  factory CryptoAccount.fromJson(Map<String, dynamic> json) {
    return CryptoAccount(
      cryptoAccountId: json['cryptoAccountId'] ?? '',
      currencyCode: json['currencyCode'] ?? '',
      network: json['network'] ?? '',
      walletAddress: json['walletAddress'] ?? '',
      isDefault: json['isDefault'] ?? false,
      balance: json['balance']?.toString() ?? '0',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class WalletsAccountsSnapshot {
  final List<FiatAccount> fiatAccounts;
  final List<CryptoAccount> cryptoAccounts;

  WalletsAccountsSnapshot({
    required this.fiatAccounts,
    required this.cryptoAccounts,
  });

  // Comment: matches AccountsBalancesResponseDTO on the backend
  // ({fiatBalances, cryptoBalances}) — a user now has one wallet with many
  // currency accounts inside it, so this is a flat list of accounts, not a
  // list of wallets.
  factory WalletsAccountsSnapshot.fromJson(Map<String, dynamic> json) =>
      WalletsAccountsSnapshot(
        fiatAccounts: ((json['fiatBalances'] as List?) ?? [])
            .map((e) => FiatAccount.fromJson(e))
            .toList(),
        cryptoAccounts: ((json['cryptoBalances'] as List?) ?? [])
            .map((e) => CryptoAccount.fromJson(e))
            .toList(),
      );

  WalletsAccountsSnapshot copyWith({
    List<FiatAccount>? fiatAccounts,
    List<CryptoAccount>? cryptoAccounts,
  }) => WalletsAccountsSnapshot(
    fiatAccounts: fiatAccounts ?? this.fiatAccounts,
    cryptoAccounts: cryptoAccounts ?? this.cryptoAccounts,
  );

  /// Replaces (by id) or appends a fiat wallet — used to apply a POST
  /// response into the cached snapshot without a full refetch.
  WalletsAccountsSnapshot withUpsertedFiatWallet(FiatAccount account) {
    final next =
        fiatAccounts.where((a) => a.accountId != account.accountId).toList()
          ..add(account);
    return copyWith(fiatAccounts: next);
  }
}

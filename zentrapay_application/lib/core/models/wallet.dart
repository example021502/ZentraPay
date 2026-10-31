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

  void clearWallets() {
    fiatAccounts.clear();
    cryptoAccounts.clear();
  }

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

// MINI USER INFORMATION TO CREATE THE QR CODE FOR EACH WALLET ACCOUNT
class UserQRInfo {
  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String countryCode;
  final String zentag;
  final String userType;

  UserQRInfo({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.countryCode,
    required this.zentag,
    required this.userType,
  });

  // CREATING AND LOCALLY SAVING THE USER INFORMATION
  factory UserQRInfo.fromJson(Map<String, dynamic> json) => UserQRInfo(
    userId: json['userId']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    firstName: json['firstName']?.toString() ?? '',
    lastName: json['lastName']?.toString() ?? '',
    phoneNumber: json['phoneNumber']?.toString() ?? '',
    countryCode: json['countryCode']?.toString() ?? '',
    // The backend resolves this from the default fiat account; tolerate its
    // absence so an older cached/error response can't break QR generation.
    zentag: json['zentag']?.toString() ?? "",
    userType: json['userType']?.toString() ?? '',
  );
  // COPYING THE USER QR INFORMATION
  UserQRInfo copyWith({
    String? userId,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? countryCode,
    String? zentag,
    String? userType,
  }) => UserQRInfo(
    userId: userId ?? this.userId,
    email: email ?? this.email,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    countryCode: countryCode ?? this.countryCode,
    zentag: zentag ?? this.zentag,
    userType: userType ?? this.userType,
  );
}

class FundingSource {
  String sourceId;
  String name;
  String method;

  FundingSource({
    required this.sourceId,
    required this.name,
    required this.method,
  });

  /// Factory constructor to parse a single JSON map into a SupportedCurrencies instance.
  // Comment: backend's SupportedCurrencyDTO has no separate currencyId — the
  // currency code doubles as the id — and its flag-country field is named
  // "countryCode", not "countryIsoCode".
  factory FundingSource.fromJson(Map<String, dynamic> json) => FundingSource(
    sourceId: json['sourceId'] ?? '',
    name: json['name'] ?? '',
    method: json['method'] ?? 2,
  );
}

// Comment: Corrected FundingSources model class with proper field declarations, state getters, and JSON parsing.
class FundingSources {
  // Comment: List of available funding sources
  final List<FundingSource> sources;

  // Comment: Private backing fields for state management
  bool _isLoading;
  Object? _error;

  // Comment: Constructor for the FundingSources collection
  FundingSources({required this.sources, bool isLoading = false, Object? error})
    : _isLoading = isLoading,
      _error = error;

  // Comment: Getter for the source data list
  List<FundingSource> get data => sources;

  // Comment: Getter for any error object
  Object? get error => _error;

  // Comment: Getter for loading status flag
  bool get isLoading => _isLoading;

  // Comment: Getter checking if data is loaded and available
  bool get isLoaded => sources.isNotEmpty;

  // Comment: Factory constructor to safely parse a JSON list into a FundingSources instance
  factory FundingSources.fromJson(List<dynamic> jsonList) {
    return FundingSources(
      sources: jsonList
          .map((json) => FundingSource.fromJson(json as Map<String, dynamic>))
          .toList(),
    );
  }

  // Comment: Method to clear all sources from the list
  void clearSources() {
    sources.clear();
  }
}

/// One of a user's fiat currency accounts as surfaced by search — matches the
/// backend's AccountZentagDTO. zentag now lives per-account (each currency a
/// user holds gets its own), not on the user as a whole.
class AccountZentagOption {
  final String accountId;
  final String accountName;
  final String currencyCode;
  final String zentag;
  final bool isDefault;

  AccountZentagOption({
    required this.accountId,
    required this.accountName,
    required this.currencyCode,
    required this.zentag,
    required this.isDefault,
  });

  factory AccountZentagOption.fromJson(Map<String, dynamic> json) =>
      AccountZentagOption(
        accountId: json['accountId'] ?? '',
        accountName: json['accountName'] ?? '',
        currencyCode: json['currencyCode'] ?? '',
        zentag: json['zentag'] ?? '',
        isDefault: json['isDefault'] ?? false,
      );

  Map<String, dynamic> toJson() => {
    'accountId': accountId,
    'accountName': accountName,
    'currencyCode': currencyCode,
    'zentag': zentag,
    'isDefault': isDefault,
  };
}

List<AccountZentagOption> _parseFiatAccounts(Map<String, dynamic> json) =>
    ((json['fiatAccounts'] as List?) ?? [])
        .map((e) => AccountZentagOption.fromJson(e))
        .toList();

/// Picks the account to default to when a caller just wants "the" zentag/
/// currency for this person — their default account, or their first one if
/// none is flagged default, or null if they have no accounts yet.
AccountZentagOption? _defaultAccount(List<AccountZentagOption> accounts) {
  if (accounts.isEmpty) return null;
  return accounts.firstWhere((a) => a.isDefault, orElse: () => accounts.first);
}

class SenderDetails {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String countryCode;
  final String userType;
  final List<AccountZentagOption> fiatAccounts;

  SenderDetails({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.countryCode,
    required this.userType,
    required this.fiatAccounts,
  });

  /// The account this sender's money would come from when no specific
  /// currency has been picked yet.
  AccountZentagOption? get defaultAccount => _defaultAccount(fiatAccounts);
  String get zentag => defaultAccount?.zentag ?? '';
  String get currency => defaultAccount?.currencyCode ?? '';

  factory SenderDetails.fromJson(Map<String, dynamic> json) => SenderDetails(
    userId: json['userId'] ?? '',
    firstName: json['firstName'] ?? '',
    lastName: json['lastName'] ?? '',
    email: json['email'] ?? '',
    phoneNumber: json['phoneNumber'] ?? '',
    countryCode: json['countryCode'] ?? '',
    userType: json['userType'] ?? '',
    fiatAccounts: _parseFiatAccounts(json),
  );

  /// The searched sender's info as sent to the payments endpoint's
  /// `sender` field — informational only (the backend always takes
  /// the sender's real identity from the JWT, never from this payload).
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phoneNumber': phoneNumber,
    'countryCode': countryCode,
    'userType': userType,
    'fiatAccounts': fiatAccounts.map((a) => a.toJson()).toList(),
  };

  static SenderDetails empty() => SenderDetails(
    userId: '',
    firstName: '',
    lastName: '',
    email: '',
    phoneNumber: '',
    countryCode: '',
    userType: '',
    fiatAccounts: [],
  );
}

class SearchAppUser {
  final String userId;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final String countryCode;
  final String userType;
  final List<AccountZentagOption> fiatAccounts;

  SearchAppUser({
    required this.userId,
    required this.phoneNumber,
    required this.email,
    required this.userType,
    required this.countryCode,
    required this.firstName,
    required this.lastName,
    required this.fiatAccounts,
  });

  factory SearchAppUser.fromJson(Map<String, dynamic> json) => SearchAppUser(
    userId: json['userId'] ?? '',
    phoneNumber: json['phoneNumber'] ?? '',
    email: json['email'] ?? '',
    userType: json['userType'] ?? '',
    countryCode: json['countryCode'] ?? '',
    firstName: json['firstName'] ?? '',
    lastName: json['lastName'] ?? '',
    fiatAccounts: _parseFiatAccounts(json),
  );

  String get fullName => "$firstName $lastName";

  /// zentag now lives per currency account, not on the user — this is the
  /// account a plain tap-to-pay falls back to (their default, or first).
  AccountZentagOption? get defaultAccount => _defaultAccount(fiatAccounts);
  String get zentag => defaultAccount?.zentag ?? '';

  /// The raw selected-user object/map sent to the payments endpoint's
  /// `recipient` field, exactly as this contact was surfaced by search.
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phoneNumber': phoneNumber,
    'countryCode': countryCode,
    'userType': userType,
    'fiatAccounts': fiatAccounts.map((a) => a.toJson()).toList(),
  };
}

class SearchBillProvider {
  final String providerId;
  final String billerCode;
  final String billerName;
  final String categoryCode;
  final String countryCode;
  final List<Map<String, dynamic>> fetchRequirement;
  final String customerParamsSchema;
  final String channelCode;
  final bool isCrossBorderAllowed;
  final String logoUrl;
  final bool active;
  final String userType = "bill-provider";

  SearchBillProvider({
    required this.providerId,
    required this.billerName,
    required this.categoryCode,
    required this.logoUrl,
    required this.countryCode,
    required this.active,
    required this.billerCode,
    required this.channelCode,
    required this.customerParamsSchema,
    required this.fetchRequirement,
    required this.isCrossBorderAllowed,
  });

  factory SearchBillProvider.fromJson(Map<String, dynamic> json) =>
      SearchBillProvider(
        providerId: json['providerId'] ?? '',
        billerName: json['billerName'] ?? '',
        categoryCode: json['categoryCode'] ?? '',
        logoUrl: json['logoUrl'] ?? '',
        countryCode: json['countryCode'] ?? '',
        active: json['active'] ?? false,
        billerCode: json['billerCode'] ?? '',
        channelCode: json['channelCode'] ?? '',
        customerParamsSchema: json['customerParamsSchema'] ?? '',
        fetchRequirement: List<Map<String, dynamic>>.from(
          json['fetchRequirement'] ?? [],
        ),
        isCrossBorderAllowed: json['isCrossBorderAllowed'] ?? false,
      );
}

class SearchFundingSource {
  final String sourceId;
  final String accountIdentifier;
  final String channelCode;
  final String countryCode;
  final bool isVerified;
  final String sourceName;
  final String sourceType;
  final String accountName;
  final String fundingSourceCode;
  final String currency;
  final String fundingType;
  final bool isPrimary;
  final String userType = "funding-source";

  SearchFundingSource({
    required this.sourceId,
    required this.sourceName,
    required this.accountIdentifier,
    required this.channelCode,
    required this.countryCode,
    required this.isVerified,
    required this.sourceType,
    required this.accountName,
    required this.fundingSourceCode,
    required this.currency,
    required this.fundingType,
    required this.isPrimary,
  });

  factory SearchFundingSource.fromJson(Map<String, dynamic> json) =>
      SearchFundingSource(
        sourceId: json['sourceId'] ?? '',
        sourceName: json['sourceName'] ?? '',
        accountIdentifier: json['accountIdentifier'] ?? '',
        channelCode: json['channelCode'] ?? '',
        countryCode: json['countryCode'] ?? '',
        isVerified: json['isVerified'] ?? false,
        sourceType: json['sourceType'] ?? '',
        accountName: json['accountName'] ?? '',
        fundingSourceCode: json['fundingSourceCode'] ?? '',
        currency: json['currency'] ?? '',
        fundingType: json['fundingType'] ?? '',
        isPrimary: json['isPrimary'] ?? false,
      );
}

class ContactSearchResult {
  final SenderDetails senderDetails;
  final List<SearchAppUser> appUsers;
  final List<SearchBillProvider> billProviders;
  final List<SearchFundingSource> fundingSources;

  ContactSearchResult({
    required this.senderDetails,
    required this.appUsers,
    required this.billProviders,
    required this.fundingSources,
  });

  factory ContactSearchResult.fromJson(Map<String, dynamic> json) =>
      ContactSearchResult(
        // Comment: backend's SearchResponseDTO field is "sender", not "senderDetails".
        senderDetails: SenderDetails.fromJson(json['sender'] ?? {}),
        appUsers: ((json['appUsers'] as List?) ?? [])
            .map((e) => SearchAppUser.fromJson(e))
            .toList(),
        billProviders: ((json['billProviders'] as List?) ?? [])
            .map((e) => SearchBillProvider.fromJson(e))
            .toList(),
        fundingSources: ((json['fundingSources'] as List?) ?? [])
            .map((e) => SearchFundingSource.fromJson(e))
            .toList(),
      );

  static ContactSearchResult empty() => ContactSearchResult(
    senderDetails: SenderDetails.empty(),
    appUsers: [],
    billProviders: [],
    fundingSources: [],
  );
}

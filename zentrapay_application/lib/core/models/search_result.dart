class SearchAppUser {
  final String userId;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String zentag;
  final String countryCode;
  final String userType;

  SearchAppUser({
    required this.userId,
    required this.phoneNumber,
    required this.zentag,
    required this.userType,
    required this.countryCode,
    required this.firstName,
    required this.lastName,
  });

  factory SearchAppUser.fromJson(Map<String, dynamic> json) => SearchAppUser(
    userId: json['userId']?.toString() ?? '',
    phoneNumber: json['phoneNumber']?.toString() ?? '',
    zentag: json['zentag']?.toString() ?? '',
    // Backend UserSearchDTO serializes the discriminator as `type`
    // (Datatypes.UserType); older payloads / recent-contact re-search may
    // surface it as `userType` — accept either so INTERNAL routing never
    // silently drops to the fallback path.
    userType:
        json['type']?.toString() ?? json['userType']?.toString() ?? '',
    countryCode: json['countryCode']?.toString() ?? '',
    firstName: json['firstName']?.toString() ?? '',
    lastName: json['lastName']?.toString() ?? '',
  );

  String get fullName => "$firstName $lastName".trim();

  /// The raw selected-user object/map sent to the payments endpoint's
  /// `recipient` field, exactly as this contact was surfaced by search.
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'firstName': firstName,
    'lastName': lastName,
    'zentag': zentag,
    'phoneNumber': phoneNumber,
    'countryCode': countryCode,
    'userType': userType,
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
        // Backend BillProviderSearchDTO declares the record component
        // "CategoryCode" (capital C) — parse the backend's key first, keeping
        // the camelCase variant as a fallback.
        categoryCode: json['CategoryCode'] ?? json['categoryCode'] ?? '',
        // Backend exposes the logo under "logo", not "logoUrl".
        logoUrl: json['logo'] ?? json['logoUrl'] ?? '',
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

/// A bank surfaced as a funding source by search-contacts. The backend's
/// banks list is served from the `payment_channels`/`banks` directory
/// as {@code BankSearchDTO {bankId, bankName, bankCode, countryCode}} — the
/// frontend model reads exactly those keys.
class Banks {
  final String bankId;
  final String bankName;
  final String bankCode;
  final String countryCode;
  final String userType = "bank";

  Banks({
    required this.bankId,
    required this.bankName,
    required this.bankCode,
    required this.countryCode,
  });

  factory Banks.fromJson(Map<String, dynamic> json) => Banks(
    bankId: json['bankId'] ?? '',
    bankName: json['bankName'] ?? '',
    bankCode: json['bankCode'] ?? '',
    countryCode: json['countryCode'] ?? '',
  );
}

class ContactSearchResult {
  final List<SearchAppUser> appUsers;
  final List<SearchBillProvider> billProviders;
  final List<Banks> banks;

  ContactSearchResult({
    required this.appUsers,
    required this.billProviders,
    required this.banks,
  });

  factory ContactSearchResult.fromJson(
    Map<String, dynamic> json,
  ) => ContactSearchResult(
    // Comment: backend's SearchResponseDTO field is "sender", not "senderDetails".
    appUsers: ((json['appUsers'] as List?) ?? [])
        .map((e) => SearchAppUser.fromJson(e))
        .toList(),
    billProviders: ((json['billProviders'] as List?) ?? [])
        .map((e) => SearchBillProvider.fromJson(e))
        .toList(),
    banks: ((json['banks'] as List?) ?? [])
        .map((e) => Banks.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  static ContactSearchResult empty() =>
      ContactSearchResult(appUsers: [], billProviders: [], banks: []);
}

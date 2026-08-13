class SenderDetails {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String countryCode;
  final String currency;
  final String userType;
  final String zentag;

  SenderDetails({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.countryCode,
    required this.currency,
    required this.userType,
    required this.zentag,
  });

  factory SenderDetails.fromJson(Map<String, dynamic> json) => SenderDetails(
    userId: json['userId'] ?? '',
    firstName: json['firstName'] ?? '',
    lastName: json['lastName'] ?? '',
    email: json['email'] ?? '',
    phoneNumber: json['phoneNumber'] ?? '',
    countryCode: json['countryCode'] ?? '',
    currency: json['currency'] ?? '',
    userType: json['userType'],
    zentag: json['zentag'],
  );

  static SenderDetails empty() => SenderDetails(
    userId: '',
    firstName: '',
    lastName: '',
    email: '',
    phoneNumber: '',
    countryCode: '',
    currency: '',
    userType: '',
    zentag: '',
  );
}

class SearchAppUser {
  final String userId;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String zentag;
  final String email;
  final String countryCode;
  final String userType;

  SearchAppUser({
    required this.userId,
    required this.phoneNumber,
    required this.zentag,
    required this.email,
    required this.userType,
    required this.countryCode,
    required this.firstName,
    required this.lastName,
  });

  factory SearchAppUser.fromJson(Map<String, dynamic> json) => SearchAppUser(
    userId: json['userId'] ?? '',
    phoneNumber: json['phoneNumber'] ?? '',
    zentag: json['zentag'] ?? '',
    email: json['email'] ?? '',
    userType: json['usertype'] ?? '',
    countryCode: json['countryCode'] ?? '',
    firstName: json['firstName'] ?? '',
    lastName: json['lastName'] ?? '',
  );

  String get fullName => "$firstName $lastName";
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
        senderDetails: SenderDetails.fromJson(json['senderDetails'] ?? {}),
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

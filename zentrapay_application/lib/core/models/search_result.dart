class SearchAppUser {
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String zentag;
  final String email;

  SearchAppUser({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.zentag,
    required this.email,
  });

  factory SearchAppUser.fromJson(Map<String, dynamic> json) => SearchAppUser(
    userId: json['userId'] ?? '',
    fullName: json['fullName'] ?? '',
    phoneNumber: json['phoneNumber'] ?? '',
    zentag: json['zentag'] ?? '',
    email: json['email'] ?? '',
  );
}

class SearchBillProvider {
  final String providerId;
  final String billerName;
  final String categoryCode;
  final String billerCode;
  final String countryCode;
  final String fetchRequirement;
  final String customerParamsSchema;
  final String logoUrl;
  final String channel;
  final String isCrossBorderAllowed;

  SearchBillProvider({
    required this.providerId,
    required this.billerName,
    required this.categoryCode,
    required this.billerCode,
    required this.channel,
    required this.countryCode,
    required this.customerParamsSchema,
    required this.fetchRequirement,
    required this.isCrossBorderAllowed,
    required this.logoUrl,
  });

  factory SearchBillProvider.fromJson(Map<String, dynamic> json) =>
      SearchBillProvider(
        providerId: json['providerId'] ?? '',
        billerName: json['billerName'] ?? '',
        billerCode: json['billerCode'] ?? '',
        countryCode: json['countryCode'] ?? '',
        fetchRequirement: json['fetchRequirement'] ?? '',
        customerParamsSchema: json['customerParamsSchema'] ?? '',
        logoUrl: json['logoUrl'] ?? '',
        channel: json['channel'] ?? 'Paystack',
        categoryCode: json['categoryCode'] ?? '',
        isCrossBorderAllowed: json["isCrossBorderAllowed"],
      );
}

class SearchFundingSource {
  final String sourceId;
  final String sourceName;
  final String accountIdentifier;

  SearchFundingSource({
    required this.sourceId,
    required this.sourceName,
    required this.accountIdentifier,
  });

  factory SearchFundingSource.fromJson(Map<String, dynamic> json) =>
      SearchFundingSource(
        sourceId: json['sourceId'] ?? '',
        sourceName: json['sourceName'] ?? '',
        accountIdentifier: json['accountIdentifier'] ?? '',
      );
}

class ContactSearchResult {
  final List<SearchAppUser> appUsers;
  final List<SearchBillProvider> billProviders;
  final List<SearchFundingSource> fundingSources;

  ContactSearchResult({
    required this.appUsers,
    required this.billProviders,
    required this.fundingSources,
  });

  factory ContactSearchResult.fromJson(Map<String, dynamic> json) =>
      ContactSearchResult(
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

  static ContactSearchResult empty() =>
      ContactSearchResult(appUsers: [], billProviders: [], fundingSources: []);
}

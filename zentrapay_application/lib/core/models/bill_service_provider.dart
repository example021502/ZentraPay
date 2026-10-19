class BillProvider {
  final String providerId;
  final String billerName;
  final String categoryCode;
  final String? logoUrl;
  final String? fetchRequirement;
  /// ISO country code of the corridor this biller serves — used by the home
  /// grid to render the country flag when the biller has no logo.
  final String? countryCode;

  BillProvider({
    required this.providerId,
    required this.billerName,
    required this.categoryCode,
    this.logoUrl,
    this.fetchRequirement,
    this.countryCode,
  });

  factory BillProvider.fromJson(Map<String, dynamic> json) => BillProvider(
    providerId: json['providerId'] ?? '',
    billerName: json['billerName'] ?? '',
    categoryCode: json['categoryCode'] ?? '',
    logoUrl: json['logoUrl'],
    fetchRequirement: json['fetchRequirement'],
    countryCode: json['countryCode'],
  );
}

class ServiceProvider {
  final String providerId;
  final String providerName;
  final String categoryCode;
  final String? logoUrl;
  final String? minAmount;
  final String? maxAmount;
  /// ISO country code of the corridor this provider serves — used by the
  /// home grid to render the country flag when the provider has no logo.
  final String? countryCode;

  ServiceProvider({
    required this.providerId,
    required this.providerName,
    required this.categoryCode,
    this.logoUrl,
    this.minAmount,
    this.maxAmount,
    this.countryCode,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) =>
      ServiceProvider(
        providerId: json['providerId'] ?? '',
        providerName: json['providerName'] ?? '',
        categoryCode: json['categoryCode'] ?? '',
        logoUrl: json['logoUrl'],
        minAmount: json['minAmount']?.toString(),
        maxAmount: json['maxAmount']?.toString(),
        countryCode: json['countryCode']?.toString(),
      );
}

class BillPaymentRecord {
  final String paymentId;
  final String providerName;
  final String customerReference;
  final String amount;
  final String currencyCode;
  final String status;
  final String createdAt;

  BillPaymentRecord({
    required this.paymentId,
    required this.providerName,
    required this.customerReference,
    required this.amount,
    required this.currencyCode,
    required this.status,
    required this.createdAt,
  });

  factory BillPaymentRecord.fromJson(Map<String, dynamic> json) =>
      BillPaymentRecord(
        paymentId: json['paymentId'] ?? '',
        providerName: json['providerName'] ?? '',
        customerReference: json['customerReference'] ?? '',
        amount: (json['amount'] ?? '0').toString(),
        currencyCode: json['currencyCode'] ?? '',
        status: json['status'] ?? '',
        createdAt: json['createdAt'] ?? '',
      );
}

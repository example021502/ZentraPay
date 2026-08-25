class AppCard {
  final String cardId;
  final String brand;
  final String cardType;
  final String last4;
  final int expiryMonth;
  final int expiryYear;
  final bool nfcEnabled;
  final bool qrEnabled;
  final String status;
  final String balance;
  final String currencyCode;
  final String createdAt;

  AppCard({
    required this.cardId,
    required this.brand,
    required this.cardType,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    required this.nfcEnabled,
    required this.qrEnabled,
    required this.status,
    required this.balance,
    required this.currencyCode,
    required this.createdAt,
  });

  factory AppCard.fromJson(Map<String, dynamic> json) => AppCard(
    cardId: json['cardId'] ?? '',
    brand: json['brand'] ?? '',
    cardType: json['cardType'] ?? 'VIRTUAL',
    last4: json['last4'] ?? '0000',
    expiryMonth: json['expiryMonth'] ?? 1,
    expiryYear: json['expiryYear'] ?? 0,
    nfcEnabled: json['nfcEnabled'] ?? false,
    qrEnabled: json['qrEnabled'] ?? false,
    status: json['status'] ?? 'active',
    balance: json['balance'] ?? '0.0000',
    currencyCode: json['currencyCode'] ?? "unknown",
    createdAt: json['createdAt'],
  );

  AppCard copyWith({bool? nfcEnabled, bool? qrEnabled}) => AppCard(
    cardId: cardId,
    brand: brand,
    cardType: cardType,
    last4: last4,
    expiryMonth: expiryMonth,
    expiryYear: expiryYear,
    nfcEnabled: nfcEnabled ?? this.nfcEnabled,
    qrEnabled: qrEnabled ?? this.qrEnabled,
    status: status,
    balance: balance,
    currencyCode: currencyCode,
    createdAt: createdAt,
  );
}

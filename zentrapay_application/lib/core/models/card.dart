class AppCard {
  final String cardId;
  final String name;
  final String brand;
  final String cardType;
  final String description;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppCard({
    required this.cardId,
    required this.name,
    required this.brand,
    required this.cardType,
    required this.description,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppCard.fromJson(Map<String, dynamic> json) => AppCard(
    cardId: json['cardId'] ?? '',
    name: json['name'] ?? '',
    brand: json['brand'] ?? '',
    cardType: json['cardType'] ?? 'VIRTUAL',
    description: json['description'] ?? '',
    active: json['active'] ?? true,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'])
        : DateTime.now(),
  );

  AppCard copyWith({bool? nfcEnabled, bool? qrEnabled}) => AppCard(
    cardId: cardId,
    name: name,
    brand: brand,
    cardType: cardType,
    description: description,
    active: active,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

class UserCard {
  final String id;
  final String userId;
  final String cardId;
  final String walletId;
  final String providerId;
  final String name;
  final String brand;
  final String last4;
  final double balance;
  final String currencyCode;
  final int expiryMonth;
  final int expiryYear;
  final bool nfcEnabled;
  final bool qrEnabled;
  final String status;
  final String issuedAt;
  final String updatedAt;

  UserCard({
    required this.id,
    required this.userId,
    required this.cardId,
    required this.walletId,
    required this.providerId,
    required this.name,
    required this.brand,
    required this.last4,
    required this.balance,
    required this.currencyCode,
    required this.expiryMonth,
    required this.expiryYear,
    required this.nfcEnabled,
    required this.qrEnabled,
    required this.status,
    required this.issuedAt,
    required this.updatedAt,
  });

  factory UserCard.fromJson(Map<String, dynamic> json) => UserCard(
    id: json['id'] ?? '',
    userId: json['userId'] ?? '',
    cardId: json['cardId'] ?? '',
    walletId: json['walletId'] ?? '',
    providerId: json['providerId'] ?? '',
    name: json['name'] ?? '',
    brand: json['brand'] ?? '',
    last4: json['last4'] ?? '0000',
    balance: json['balance'] ?? 0.0,
    currencyCode: json['currencyCode'] ?? 'USD',
    expiryMonth: json['expiryMonth'] ?? 1,
    expiryYear: json['expiryYear'] ?? 0,
    nfcEnabled: json['nfcEnabled'] ?? false,
    qrEnabled: json['qrEnabled'] ?? false,
    status: json['status'] ?? 'active',
    issuedAt: json['issuedAt'] ?? "",
    updatedAt: json['updatedAt'] ?? "",
  );

  UserCard copyWith({bool? nfcEnabled, bool? qrEnabled}) => UserCard(
    id: id,
    userId: userId,
    cardId: cardId,
    walletId: walletId,
    providerId: providerId,
    name: name,
    brand: brand,
    last4: last4,
    balance: balance,
    currencyCode: currencyCode,
    expiryMonth: expiryMonth,
    expiryYear: expiryYear,
    nfcEnabled: nfcEnabled ?? this.nfcEnabled,
    qrEnabled: qrEnabled ?? this.qrEnabled,
    status: status,
    issuedAt: issuedAt,
    updatedAt: updatedAt,
  );
}

/// A bill provider or service provider the user added to their Home screen
/// (`/api/user-services`, backed by the `user_services` table).
class UserService {
  /// BILL (a bill provider, payable) or SERVICE (a service provider).
  final String kind;
  final String providerId;
  final String name;
  final String logoUrl;
  final String categoryCode;
  final String countryCode;

  const UserService({
    required this.kind,
    required this.providerId,
    required this.name,
    this.logoUrl = '',
    this.categoryCode = '',
    this.countryCode = '',
  });

  static const String bill = 'BILL';
  static const String service = 'SERVICE';

  bool get isBill => kind == bill;

  factory UserService.fromJson(Map<String, dynamic> json) => UserService(
    kind: (json['kind'] ?? '').toString().toUpperCase(),
    providerId: (json['providerId'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    logoUrl: (json['logoUrl'] ?? '').toString(),
    categoryCode: (json['categoryCode'] ?? '').toString(),
    countryCode: (json['countryCode'] ?? '').toString(),
  );
}

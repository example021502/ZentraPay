class AppUser {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String countryCode;
  final String createdAt;
  final String status;
  final String userType;

  AppUser({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.countryCode,
    required this.userType,
    required this.status,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    userId: json['userId'] ?? '',
    firstName: json['firstName'] ?? '',
    lastName: json['lastName'] ?? '',
    email: json['email'] ?? '',
    phoneNumber: json['phoneNumber'] ?? '',
    countryCode: json['countryCode'] ?? '',
    createdAt: json['createdAt'] ?? '',
    userType: json['userType'] ?? 'INDIVIDUAL',
    status: json['status'] ?? '',
  );
}

class UserProfile {
  DateTime? dateOfBirth;
  String nationalityCountryCode;
  String identityDocumentType;
  String identityDocumentNumber;
  String identityDocumentIssuingCountryCode;
  DateTime? identityDocumentExpirationDate;
  String addressLine1;
  String addressLine2;
  String cityName;
  String stateOrRegion;
  String postalCode;
  String occupationTitle;
  String antiMoneyLaunderingStatus;
  bool isPoliticallyExposedPerson;
  String riskScoreLevel;
  String KYCStatus;
  DateTime? createdAt;
  DateTime? updatedAt;

  UserProfile({
    required this.dateOfBirth,
    required this.nationalityCountryCode,
    required this.identityDocumentType,
    required this.identityDocumentNumber,
    required this.identityDocumentIssuingCountryCode,
    required this.identityDocumentExpirationDate,
    required this.addressLine1,
    required this.addressLine2,
    required this.cityName,
    required this.stateOrRegion,
    required this.postalCode,
    required this.occupationTitle,
    required this.antiMoneyLaunderingStatus,
    required this.isPoliticallyExposedPerson,
    required this.riskScoreLevel,
    required this.KYCStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    dateOfBirth: _parseDate(json['dateOfBirth']),
    nationalityCountryCode: json['nationalityCountryCode'] ?? '',
    identityDocumentType: json['identityDocumentType'] ?? '',
    identityDocumentNumber: json['identityDocumentNumber'] ?? '',
    identityDocumentIssuingCountryCode:
        json['identityDocumentIssuingCountryCode'] ?? '',
    identityDocumentExpirationDate: _parseDate(
      json['identityDocumentExpirationDate'],
    ),
    addressLine1: json['addressLine1'] ?? '',
    addressLine2: json['addressLine2'] ?? '',
    cityName: json['cityName'] ?? '',
    stateOrRegion: json['stateOrRegion'] ?? '',
    postalCode: json['postalCode'] ?? '',
    occupationTitle: json['occupationTitle'] ?? '',
    antiMoneyLaunderingStatus: json['antiMoneyLaunderingStatus'] ?? 'unknown',
    isPoliticallyExposedPerson: json['isPoliticallyExposedPerson'] ?? false,
    riskScoreLevel: json['riskScoreLevel'] ?? '',
    KYCStatus: json['KYCStatus'] ?? '',
    createdAt: _parseDate(json['createdAt']),
    updatedAt: _parseDate(json['updatedAt']),
  );

  // Dates arrive as ISO-8601 strings over the wire (and may be absent while
  // the KYC profile is still incomplete), so parse defensively.
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  /// Convenience getter: street, city, region and postal code joined the way
  /// it's displayed on the profile screen.
  String get registeredAddress => [
    addressLine1,
    addressLine2,
    cityName,
    stateOrRegion,
    postalCode,
  ].where((part) => part.isNotEmpty).join(', ');
}

/// Combined payload of `GET /api/users/me`: the backend returns the account
/// record under `user` and the KYC profile record under `profile`. The
/// profile is null until the user has submitted their KYC details.
class UserProfileSnapshot {
  final AppUser user;
  final UserProfile? profile;

  UserProfileSnapshot({required this.user, this.profile});

  factory UserProfileSnapshot.fromJson(Map<String, dynamic> json) =>
      UserProfileSnapshot(
        user: AppUser.fromJson(
          (json['user'] as Map<String, dynamic>?) ?? const {},
        ),
        profile: json['profile'] == null
            ? null
            : UserProfile.fromJson(
                Map<String, dynamic>.from(json['profile'] as Map),
              ),
      );
}

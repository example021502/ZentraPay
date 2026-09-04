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
  final int kycTier;

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
    this.kycTier = 0,
  });

  String get fullName => '$firstName $lastName';

  /// Tier 2 is the bar for sending/receiving money (see backend
  /// PaymentsService) — complete profile + uploaded ID documents.
  bool get canTransact => kycTier >= 2;

  AppUser copyWith({String? firstName, String? lastName, int? kycTier}) =>
      AppUser(
        userId: userId,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email,
        phoneNumber: phoneNumber,
        countryCode: countryCode,
        userType: userType,
        status: status,
        createdAt: createdAt,
        kycTier: kycTier ?? this.kycTier,
      );

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
    kycTier: (json['kycTier'] as num?)?.toInt() ?? 0,
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
  // Tier-2 document upload status — presence only, never the storage path
  // (the backend keeps that server-side; see DocumentsRepository).
  bool hasIdDocumentFront;
  bool hasIdDocumentBack;
  bool hasSelfie;
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
    this.hasIdDocumentFront = false,
    this.hasIdDocumentBack = false,
    this.hasSelfie = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True once the profile carries every field the backend requires for
  /// Tier 2 (see UsersService#recomputeKycTier) — used to drive the
  /// "what's left" checklist on the edit/upload screen.
  bool get isComplete =>
      dateOfBirth != null &&
      addressLine1.isNotEmpty &&
      cityName.isNotEmpty &&
      occupationTitle.isNotEmpty &&
      identityDocumentType.isNotEmpty &&
      identityDocumentNumber.isNotEmpty &&
      hasIdDocumentFront &&
      hasIdDocumentBack &&
      hasSelfie;

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
    hasIdDocumentFront: json['hasIdDocumentFront'] ?? false,
    hasIdDocumentBack: json['hasIdDocumentBack'] ?? false,
    hasSelfie: json['hasSelfie'] ?? false,
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

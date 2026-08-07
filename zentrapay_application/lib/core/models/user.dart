class AppUser {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String countryCode;
  final String zentag;
  final String userType;
  final String status;
  final int kycTier;

  AppUser({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.countryCode,
    required this.zentag,
    required this.userType,
    required this.status,
    required this.kycTier,
  });

  String get fullName => '$firstName $lastName';

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    userId: json['userId'] ?? '',
    firstName: json['firstName'] ?? '',
    lastName: json['lastName'] ?? '',
    email: json['email'] ?? '',
    phoneNumber: json['phoneNumber'] ?? '',
    countryCode: json['countryCode'] ?? '',
    zentag: json['zentag'] ?? '',
    userType: json['userType'] ?? 'INDIVIDUAL',
    status: json['status'] ?? '',
    kycTier: json['kycTier'] ?? 0,
  );
}

class UserProfileDetails {
  final String? dateOfBirth;
  final String? idDocumentType;
  final String? idDocumentNumber;
  final String? idDocumentCountryCode;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? regionState;
  final String? postalCode;
  final String? occupation;
  final String amlStatus;
  final bool isPep;

  UserProfileDetails({
    this.dateOfBirth,
    this.idDocumentType,
    this.idDocumentNumber,
    this.idDocumentCountryCode,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.regionState,
    this.postalCode,
    this.occupation,
    this.amlStatus = 'CLEAR',
    this.isPep = false,
  });

  factory UserProfileDetails.fromJson(Map<String, dynamic> json) =>
      UserProfileDetails(
        dateOfBirth: json['dateOfBirth'],
        idDocumentType: json['idDocumentType'],
        idDocumentNumber: json['idDocumentNumber'],
        idDocumentCountryCode: json['idDocumentCountryCode'],
        addressLine1: json['addressLine1'],
        addressLine2: json['addressLine2'],
        city: json['city'],
        regionState: json['regionState'],
        postalCode: json['postalCode'],
        occupation: json['occupation'],
        amlStatus: json['amlStatus'] ?? 'CLEAR',
        isPep: json['isPep'] ?? false,
      );

  Map<String, dynamic> toJson() => {
    'dateOfBirth': dateOfBirth,
    'idDocumentType': idDocumentType,
    'idDocumentNumber': idDocumentNumber,
    'idDocumentCountryCode': idDocumentCountryCode,
    'addressLine1': addressLine1,
    'addressLine2': addressLine2,
    'city': city,
    'regionState': regionState,
    'postalCode': postalCode,
    'occupation': occupation,
  };
}

class MerchantProfileDetails {
  final String businessName;
  final String? businessRegistrationNumber;
  final String? taxIdentificationNumber;
  final String? businessCategoryCode;
  final String businessCountryCode;
  final String? businessAddress;

  MerchantProfileDetails({
    required this.businessName,
    this.businessRegistrationNumber,
    this.taxIdentificationNumber,
    this.businessCategoryCode,
    required this.businessCountryCode,
    this.businessAddress,
  });

  factory MerchantProfileDetails.fromJson(Map<String, dynamic> json) =>
      MerchantProfileDetails(
        businessName: json['businessName'] ?? '',
        businessRegistrationNumber: json['businessRegistrationNumber'],
        taxIdentificationNumber: json['taxIdentificationNumber'],
        businessCategoryCode: json['businessCategoryCode'],
        businessCountryCode: json['businessCountryCode'] ?? '',
        businessAddress: json['businessAddress'],
      );

  Map<String, dynamic> toJson() => {
    'businessName': businessName,
    'businessRegistrationNumber': businessRegistrationNumber,
    'taxIdentificationNumber': taxIdentificationNumber,
    'businessCategoryCode': businessCategoryCode,
    'businessCountryCode': businessCountryCode,
    'businessAddress': businessAddress,
  };
}

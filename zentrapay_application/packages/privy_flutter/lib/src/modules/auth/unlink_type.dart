/// Defines the different types of account unlink operations supported by Privy.
///
/// This sealed class ensures type-safe handling of unlink operations across
/// different authentication methods (email, SMS, wallets, passkeys, etc.).
sealed class UnlinkType {
  const UnlinkType();

  /// The method channel method name to invoke
  String get methodName;

  /// The parameters to pass to the native platform
  Map<String, dynamic> get params;
}

/// Represents a SIWE (Sign-In With Ethereum) wallet unlink operation.
class SiweUnlink extends UnlinkType {
  final String address;

  const SiweUnlink({required this.address});

  @override
  String get methodName => 'siweUnlink';

  @override
  Map<String, dynamic> get params => {'address': address};
}

/// Represents a SIWS (Sign-In With Solana) wallet unlink operation.
class SiwsUnlink extends UnlinkType {
  final String address;

  const SiwsUnlink({required this.address});

  @override
  String get methodName => 'siwsUnlink';

  @override
  Map<String, dynamic> get params => {'address': address};
}

/// Represents a passkey unlink operation.
class PasskeyUnlink extends UnlinkType {
  final String credentialId;

  const PasskeyUnlink({required this.credentialId});

  @override
  String get methodName => 'passkeyUnlink';

  @override
  Map<String, dynamic> get params => {'credentialId': credentialId};
}

/// Represents an email unlink operation.
class EmailUnlink extends UnlinkType {
  final String email;

  const EmailUnlink({required this.email});

  @override
  String get methodName => 'emailUnlink';

  @override
  Map<String, dynamic> get params => {'email': email};
}

/// Represents an SMS unlink operation.
class SmsUnlink extends UnlinkType {
  final String phoneNumber;

  const SmsUnlink({required this.phoneNumber});

  @override
  String get methodName => 'smsUnlink';

  @override
  Map<String, dynamic> get params => {'phoneNumber': phoneNumber};
}

/// Represents an OAuth provider unlink operation.
class OAuthUnlink extends UnlinkType {
  final String provider;
  final String subject;

  const OAuthUnlink({required this.provider, required this.subject});

  @override
  String get methodName => 'oauthUnlink';

  @override
  Map<String, dynamic> get params => {'provider': provider, 'subject': subject};
}

/// Sealed class representing different types of account linking operations.
///
/// Each subclass encapsulates its parameters and method channel name.
sealed class LinkType {
  const LinkType();

  /// The method channel name for this link operation.
  String get methodName;

  /// The parameters to pass to the method channel.
  Map<String, dynamic> get params;
}

/// Links an email address to the user's account.
class EmailLink extends LinkType {
  final String email;
  final String code;

  const EmailLink({required this.email, required this.code});

  @override
  String get methodName => 'emailLinkWithCode';

  @override
  Map<String, dynamic> get params => {
        'email': email,
        'code': code,
      };
}

/// Links a phone number to the user's account.
class SmsLink extends LinkType {
  final String phoneNumber;
  final String code;

  const SmsLink({required this.phoneNumber, required this.code});

  @override
  String get methodName => 'smsLinkWithCode';

  @override
  Map<String, dynamic> get params => {
        'phoneNumber': phoneNumber,
        'code': code,
      };
}

/// Links a Solana wallet to the user's account via SIWS.
class SiwsLink extends LinkType {
  final String message;
  final String signature;
  final Map<String, dynamic> siwsParams;
  final Map<String, dynamic>? metadata;

  const SiwsLink({
    required this.message,
    required this.signature,
    required this.siwsParams,
    this.metadata,
  });

  @override
  String get methodName => 'siwsLink';

  @override
  Map<String, dynamic> get params => {
        'message': message,
        'signature': signature,
        ...siwsParams,
        if (metadata != null) ...metadata!,
      };
}

/// Links an Ethereum wallet to the user's account via SIWE.
class SiweLink extends LinkType {
  final String message;
  final String signature;
  final Map<String, dynamic> siweParams;
  final Map<String, dynamic>? metadata;

  const SiweLink({
    required this.message,
    required this.signature,
    required this.siweParams,
    this.metadata,
  });

  @override
  String get methodName => 'siweLink';

  @override
  Map<String, dynamic> get params => {
        'message': message,
        'signature': signature,
        ...siweParams,
        if (metadata != null) ...metadata!,
      };
}

/// Links a passkey to the user's account.
class PasskeyLink extends LinkType {
  final String relyingParty;
  final String? displayName;

  const PasskeyLink({
    required this.relyingParty,
    this.displayName,
  });

  @override
  String get methodName => 'passkeyLink';

  @override
  Map<String, dynamic> get params => {
        'relyingParty': relyingParty,
        if (displayName != null) 'displayName': displayName,
      };
}

/// Links an OAuth provider to the user's account.
class OAuthLink extends LinkType {
  final String provider;
  final String appUrlScheme;

  const OAuthLink({
    required this.provider,
    required this.appUrlScheme,
  });

  @override
  String get methodName => 'oauthLink';

  @override
  Map<String, dynamic> get params => {
        'provider': provider,
        'appUrlScheme': appUrlScheme,
      };
}

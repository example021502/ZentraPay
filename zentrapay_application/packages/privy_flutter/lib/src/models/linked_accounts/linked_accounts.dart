import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/enums/chain_type.dart';

/// A sealed class representing different types of linked accounts.
/// This serves as a base class for specific account types.
sealed class LinkedAccounts {
  final String type;

  const LinkedAccounts(this.type);

  /// Converts the linked account object to a JSON representation.
  Map<String, dynamic> toJson();

  /// Factory constructor to create the appropriate subclass of [LinkedAccounts] from JSON.
  factory LinkedAccounts.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'email':
        return EmailAccount.fromJson(json);
      case 'phoneNumber':
        return PhoneNumberAccount.fromJson(json);
      case 'customAuth':
        return CustomAuthAccount.fromJson(json);
      case 'ethereumWallet':
        return EmbeddedEthereumWalletAccount.fromJson(json);
      case 'solanaWallet':
        return EmbeddedSolanaWalletAccount.fromJson(json);
      case 'google_oauth':
        return GoogleOAuthAccount.fromJson(json);
      case 'twitter_oauth':
        return TwitterOAuthAccount.fromJson(json);
      case 'discord_oauth':
        return DiscordOAuthAccount.fromJson(json);
      case 'apple_oauth':
        return AppleOAuthAccount.fromJson(json);
      case 'telegram':
        return TelegramAccount.fromJson(json);
      case 'passkey':
        return PasskeyAccount.fromJson(json);
      case 'wallet':
        return ExternalWalletAccount.fromJson(json);
      default:
        LoggerService.error('Unknown LinkedAccounts type: ${json['type']}');
        return UnknownAccount(json); // Unknown account type handling
    }
  }
}

/// Represents a Google OAuth-based linked account.
class GoogleOAuthAccount extends LinkedAccounts {
  /// Subject identifier from Google
  final String subject;

  /// Email address associated with the Google account
  final String email;

  /// User's name from Google profile, if available
  final String? name;

  /// Timestamp of first verification (in seconds since epoch)
  final int? firstVerifiedAt;

  /// Timestamp of latest verification (in seconds since epoch)
  final int? latestVerifiedAt;

  /// Constructor for GoogleOAuthAccount
  GoogleOAuthAccount({
    required this.subject,
    required this.email,
    this.name,
    this.firstVerifiedAt,
    this.latestVerifiedAt,
  }) : super('googleOAuth');

  /// Creates a GoogleOAuthAccount from JSON
  factory GoogleOAuthAccount.fromJson(Map<String, dynamic> json) {
    return GoogleOAuthAccount(
      subject: json['subject'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      firstVerifiedAt: json['first_verified_at'] as int?,
      latestVerifiedAt: json['latest_verified_at'] as int?,
    );
  }

  /// Converts this account to JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'google_oauth',
      'subject': subject,
      'email': email,
      if (name != null) 'name': name,
      if (firstVerifiedAt != null) 'first_verified_at': firstVerifiedAt,
      if (latestVerifiedAt != null) 'latest_verified_at': latestVerifiedAt,
    };
  }
}

/// Represents a Twitter OAuth-based linked account.
class TwitterOAuthAccount extends LinkedAccounts {
  /// Subject identifier from Twitter
  final String subject;

  /// Username associated with the Twitter account
  final String? username;

  /// User's name from Twitter profile, if available
  final String? name;

  /// URL of profile picture associated with the Twitter user
  final String? profilePictureUrl;

  /// Timestamp of first verification (in seconds since epoch)
  final int? firstVerifiedAt;

  /// Timestamp of latest verification (in seconds since epoch)
  final int? latestVerifiedAt;

  /// Constructor for TwitterOAuthAccount
  TwitterOAuthAccount({
    required this.subject,
    this.username,
    this.name,
    this.profilePictureUrl,
    this.firstVerifiedAt,
    this.latestVerifiedAt,
  }) : super('twitterOAuth');

  /// Creates a TwitterOAuthAccount from JSON
  factory TwitterOAuthAccount.fromJson(Map<String, dynamic> json) {
    return TwitterOAuthAccount(
      subject: json['subject'] as String,
      username: json['username'] as String?,
      name: json['name'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
      firstVerifiedAt: json['first_verified_at'] as int?,
      latestVerifiedAt: json['latest_verified_at'] as int?,
    );
  }

  /// Converts this account to JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'twitter_oauth',
      'subject': subject,
      if (username != null) 'username': username,
      if (name != null) 'name': name,
      if (profilePictureUrl != null) 'profile_picture_url': profilePictureUrl,
      if (firstVerifiedAt != null) 'first_verified_at': firstVerifiedAt,
      if (latestVerifiedAt != null) 'latest_verified_at': latestVerifiedAt,
    };
  }
}

/// Represents a Discord OAuth-based linked account.
class DiscordOAuthAccount extends LinkedAccounts {
  /// Subject identifier from Discord
  final String subject;

  /// Username associated with the Discord account
  final String? username;

  /// Email address associated with the Discord account
  final String? email;

  /// Timestamp of first verification (in seconds since epoch)
  final int? firstVerifiedAt;

  /// Timestamp of latest verification (in seconds since epoch)
  final int? latestVerifiedAt;

  /// Constructor for DiscordOAuthAccount
  DiscordOAuthAccount({
    required this.subject,
    this.username,
    this.email,
    this.firstVerifiedAt,
    this.latestVerifiedAt,
  }) : super('discordOAuth');

  /// Creates a DiscordOAuthAccount from JSON
  factory DiscordOAuthAccount.fromJson(Map<String, dynamic> json) {
    return DiscordOAuthAccount(
      subject: json['subject'] as String,
      username: json['username'] as String?,
      email: json['email'] as String?,
      firstVerifiedAt: json['first_verified_at'] as int?,
      latestVerifiedAt: json['latest_verified_at'] as int?,
    );
  }

  /// Converts this account to JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'discord_oauth',
      'subject': subject,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (firstVerifiedAt != null) 'first_verified_at': firstVerifiedAt,
      if (latestVerifiedAt != null) 'latest_verified_at': latestVerifiedAt,
    };
  }
}

/// Represents an Apple OAuth-based linked account.
class AppleOAuthAccount extends LinkedAccounts {
  /// Subject identifier from Apple
  final String subject;

  /// Email address associated with the Apple account
  final String email;

  /// Timestamp of first verification (in seconds since epoch)
  final int? firstVerifiedAt;

  /// Timestamp of latest verification (in seconds since epoch)
  final int? latestVerifiedAt;

  /// Constructor for AppleOAuthAccount
  AppleOAuthAccount({
    required this.subject,
    required this.email,
    this.firstVerifiedAt,
    this.latestVerifiedAt,
  }) : super('appleOAuth');

  /// Creates an AppleOAuthAccount from JSON
  factory AppleOAuthAccount.fromJson(Map<String, dynamic> json) {
    return AppleOAuthAccount(
      subject: json['subject'] as String,
      email: json['email'] as String,
      firstVerifiedAt: json['first_verified_at'] as int?,
      latestVerifiedAt: json['latest_verified_at'] as int?,
    );
  }

  /// Converts this account to JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'apple_oauth',
      'subject': subject,
      'email': email,
      if (firstVerifiedAt != null) 'first_verified_at': firstVerifiedAt,
      if (latestVerifiedAt != null) 'latest_verified_at': latestVerifiedAt,
    };
  }
}

/// Represents a Telegram-based linked account.
class TelegramAccount extends LinkedAccounts {
  /// Telegram user ID
  final String telegramUserId;

  /// User's first name from Telegram
  final String? firstName;

  /// User's last name from Telegram
  final String? lastName;

  /// Username associated with the Telegram account
  final String? username;

  /// URL of profile photo
  final String? photoUrl;

  /// Timestamp of first verification (in seconds since epoch)
  final int? firstVerifiedAt;

  /// Timestamp of latest verification (in seconds since epoch)
  final int? latestVerifiedAt;

  TelegramAccount({
    required this.telegramUserId,
    this.firstName,
    this.lastName,
    this.username,
    this.photoUrl,
    this.firstVerifiedAt,
    this.latestVerifiedAt,
  }) : super('telegram');

  /// Creates a TelegramAccount from JSON
  factory TelegramAccount.fromJson(Map<String, dynamic> json) {
    return TelegramAccount(
      telegramUserId: json['telegram_user_id'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      username: json['username'] as String?,
      photoUrl: json['photo_url'] as String?,
      firstVerifiedAt: json['first_verified_at'] as int?,
      latestVerifiedAt: json['latest_verified_at'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'telegram',
      'telegram_user_id': telegramUserId,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (username != null) 'username': username,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (firstVerifiedAt != null) 'first_verified_at': firstVerifiedAt,
      if (latestVerifiedAt != null) 'latest_verified_at': latestVerifiedAt,
    };
  }
}

/// Represents a passkey-based linked account using FIDO2/WebAuthn.
class PasskeyAccount extends LinkedAccounts {
  /// The credential ID for this passkey
  final String credentialId;

  /// The name of the authenticator used
  final String? authenticatorName;

  /// The browser used to create this passkey
  final String? createdWithBrowser;

  /// The operating system used to create this passkey
  final String? createdWithOs;

  /// The device used to create this passkey
  final String? createdWithDevice;

  /// The public key associated with this passkey
  final String? publicKey;

  /// Whether this passkey is enrolled in MFA
  final bool enrolledInMfa;

  /// Timestamp when this passkey was verified (in seconds since epoch)
  final int verifiedAt;

  /// Timestamp of first verification (in seconds since epoch)
  final int? firstVerifiedAt;

  /// Timestamp of latest verification (in seconds since epoch)
  final int? latestVerifiedAt;

  /// Constructor for PasskeyAccount
  PasskeyAccount({
    required this.credentialId,
    this.authenticatorName,
    this.createdWithBrowser,
    this.createdWithOs,
    this.createdWithDevice,
    this.publicKey,
    required this.enrolledInMfa,
    required this.verifiedAt,
    this.firstVerifiedAt,
    this.latestVerifiedAt,
  }) : super('passkey');

  /// Creates a PasskeyAccount from JSON
  factory PasskeyAccount.fromJson(Map<String, dynamic> json) {
    return PasskeyAccount(
      credentialId: json['credentialId'] as String,
      authenticatorName: json['authenticatorName'] as String?,
      createdWithBrowser: json['createdWithBrowser'] as String?,
      createdWithOs: json['createdWithOs'] as String?,
      createdWithDevice: json['createdWithDevice'] as String?,
      publicKey: json['publicKey'] as String?,
      enrolledInMfa: json['enrolledInMfa'] as bool? ?? false,
      verifiedAt: json['verifiedAt'] as int,
      firstVerifiedAt: json['firstVerifiedAt'] as int?,
      latestVerifiedAt: json['latestVerifiedAt'] as int?,
    );
  }

  /// Converts this account to JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'passkey',
      'credentialId': credentialId,
      if (authenticatorName != null) 'authenticatorName': authenticatorName,
      if (createdWithBrowser != null) 'createdWithBrowser': createdWithBrowser,
      if (createdWithOs != null) 'createdWithOs': createdWithOs,
      if (createdWithDevice != null) 'createdWithDevice': createdWithDevice,
      if (publicKey != null) 'publicKey': publicKey,
      'enrolledInMfa': enrolledInMfa,
      'verifiedAt': verifiedAt,
      if (firstVerifiedAt != null) 'firstVerifiedAt': firstVerifiedAt,
      if (latestVerifiedAt != null) 'latestVerifiedAt': latestVerifiedAt,
    };
  }
}

/// Represents an email-based linked account.
class EmailAccount extends LinkedAccounts {
  final String emailAddress;

  EmailAccount({required this.emailAddress}) : super('email');

  /// Factory constructor to create an [EmailAccount] from JSON.
  factory EmailAccount.fromJson(Map<String, dynamic> json) {
    return EmailAccount(emailAddress: json['emailAddress']);
  }

  /// Converts the [EmailAccount] object to a JSON representation.
  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'emailAddress': emailAddress,
    };
  }
}

/// Represents a phone number-based linked account.
class PhoneNumberAccount extends LinkedAccounts {
  final String phoneNumber;

  PhoneNumberAccount({required this.phoneNumber}) : super('sms');

  /// Factory constructor to create a [PhoneNumberAccount] from JSON.
  factory PhoneNumberAccount.fromJson(Map<String, dynamic> json) {
    return PhoneNumberAccount(phoneNumber: json['phoneNumber']);
  }

  /// Converts the [PhoneNumberAccount] object to a JSON representation.
  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'phoneNumber': phoneNumber,
    };
  }
}

/// Represents a custom authentication-linked account.
class CustomAuthAccount extends LinkedAccounts {
  final String customUserId;

  CustomAuthAccount({
    required this.customUserId,
  }) : super('customAuth');

  /// Factory constructor to create a [CustomAuthAccount] from JSON.
  factory CustomAuthAccount.fromJson(Map<String, dynamic> json) {
    return CustomAuthAccount(
      customUserId: json['customUserId'],
    );
  }

  /// Converts the [CustomAuthAccount] object to a JSON representation.
  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'customUserId': customUserId,
    };
  }
}

/// Represents an Ethereum embedded wallet linked account.
class EmbeddedEthereumWalletAccount extends LinkedAccounts {
  final String? id;
  final String address;
  final String? chainId;
  final String? recoveryMethod;
  final int hdWalletIndex;

  EmbeddedEthereumWalletAccount({
    this.id,
    required this.address,
    this.chainId,
    this.recoveryMethod,
    required this.hdWalletIndex,
  }) : super('ethereumWallet');

  /// Factory constructor to create an `EmbeddedEthereumWalletAccount` from JSON.
  factory EmbeddedEthereumWalletAccount.fromJson(Map<String, dynamic> json) {
    return EmbeddedEthereumWalletAccount(
      id: json['id'],
      address: json['address'],
      chainId: json['chainId'],
      recoveryMethod: json['recoveryMethod'],
      hdWalletIndex: json['hdWalletIndex'],
    );
  }

  /// Converts the `EmbeddedEthereumWalletAccount` object to a JSON representation.
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'address': address,
      'chainId': chainId,
      'recoveryMethod': recoveryMethod,
      'hdWalletIndex': hdWalletIndex,
    };
  }
}

class UnknownAccount extends LinkedAccounts {
  final Map<String, dynamic> json;

  UnknownAccount(this.json) : super(json['type'] ?? 'unknown');

  @override
  Map<String, dynamic> toJson() => json;
}

/// Represents an Solana embedded wallet linked account.
class EmbeddedSolanaWalletAccount extends LinkedAccounts {
  final String? id;
  final String address;
  final String? chainId;
  final String? recoveryMethod;
  final int hdWalletIndex;

  EmbeddedSolanaWalletAccount({
    required this.address,
    this.id,
    this.chainId,
    this.recoveryMethod,
    required this.hdWalletIndex,
  }) : super('solanaWallet');

  /// Factory constructor to create an `EmbeddedSolanaWalletAccount` from JSON.
  factory EmbeddedSolanaWalletAccount.fromJson(Map<String, dynamic> json) {
    return EmbeddedSolanaWalletAccount(
      id: json['id'],
      address: json['address'],
      chainId: json['chainId'],
      recoveryMethod: json['recoveryMethod'],
      hdWalletIndex: json['hdWalletIndex'],
    );
  }

  /// Converts the `EmbeddedSolanaWalletAccount` object to a JSON representation.
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'address': address,
      'chainId': chainId,
      'recoveryMethod': recoveryMethod,
      'hdWalletIndex': hdWalletIndex,
    };
  }
}

/// Represents an external wallet account linked through SIWE authentication.
class ExternalWalletAccount extends LinkedAccounts {
  /// The wallet address
  final String address;

  /// The blockchain type (Ethereum or Solana)
  final ChainType chainType;

  /// The specific chain ID (e.g., "1" for Ethereum mainnet)
  final String? chainId;

  /// The wallet client type as string (e.g., "metamask", "trust")
  final String? walletClientType;

  /// The connector type used (e.g., "wallet_connect")
  final String? connectorType;

  /// Timestamp of first verification (in seconds since epoch)
  final int? firstVerifiedAt;

  /// Timestamp of latest verification (in seconds since epoch)
  final int? latestVerifiedAt;

  ExternalWalletAccount({
    required this.address,
    required this.chainType,
    this.chainId,
    this.walletClientType,
    this.connectorType,
    this.firstVerifiedAt,
    this.latestVerifiedAt,
  }) : super('wallet');

  /// Factory constructor to create an `ExternalWalletAccount` from JSON.
  factory ExternalWalletAccount.fromJson(Map<String, dynamic> json) {
    return ExternalWalletAccount(
      address: json['address'] as String,
      chainType: ChainType.fromJson(json['chainType'] as String),
      chainId: json['chainId'] as String?,
      walletClientType: json['walletClientType'] as String?,
      connectorType: json['connectorType'] as String?,
      firstVerifiedAt: json['firstVerifiedAt'] as int?,
      latestVerifiedAt: json['latestVerifiedAt'] as int?,
    );
  }

  /// Converts the `ExternalWalletAccount` object to a JSON representation.
  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'address': address,
      'chainType': chainType.toJson(),
      if (chainId != null) 'chainId': chainId,
      if (walletClientType != null) 'walletClientType': walletClientType,
      if (connectorType != null) 'connectorType': connectorType,
      if (firstVerifiedAt != null) 'firstVerifiedAt': firstVerifiedAt,
      if (latestVerifiedAt != null) 'latestVerifiedAt': latestVerifiedAt,
    };
  }
}

import Flutter
import Foundation
import PrivySDK

/// Extension to serialize `LinkedAccount` for Flutter communication.
extension LinkedAccount {
  /// Converts a `LinkedAccount` into a dictionary format.
  ///
  /// Supports email, phone, and customAuth accounts.
  func serialized() -> [String: Any]? {
    switch self {
    case .email(let emailAccount):
      return [
        "type": "email",
        "emailAddress": emailAccount.email,
      ]
    case .phone(let phoneNumberAccount):
      return [
        "type": "phoneNumber",
        "phoneNumber": phoneNumberAccount.phoneNumber,
      ]
    case .customAuth(let customAuthAccount):
      return [
        "type": "customAuth",
        "customUserId": customAuthAccount.userId,
      ]
    case .embeddedEthereumWallet(let ethereumWallet):
      return [
        "type": "ethereumWallet",
        "address": ethereumWallet.address,
        "id": ethereumWallet.id as Any,
        "chainType": ethereumWallet.chainType.asString,
        "recoveryMethod": ethereumWallet.recoveryMethod ?? "",
        "hdWalletIndex": ethereumWallet.hdWalletIndex as Any,
      ]
    case .embeddedSolanaWallet(let solanaWallet):
      return [
        "type": "solanaWallet",
        "address": solanaWallet.address,
        "id": solanaWallet.id as Any,
        "chainType": solanaWallet.chainType.asString,
        "recoveryMethod": solanaWallet.recoveryMethod ?? "",
        "hdWalletIndex": solanaWallet.hdWalletIndex as Any,
      ]
    case .google(let googleAccount):
      var result: [String: Any] = [
        "type": "google_oauth",
        "subject": googleAccount.subject,
        "email": googleAccount.email,
      ]
      
      if let name = googleAccount.name {
        result["name"] = name
      }
      
      if let firstVerifiedAt = googleAccount.firstVerifiedAt {
        result["first_verified_at"] = Int(firstVerifiedAt.timeIntervalSince1970)
      }
      
      if let latestVerifiedAt = googleAccount.latestVerifiedAt {
        result["latest_verified_at"] = Int(latestVerifiedAt.timeIntervalSince1970)
      }
      
      return result
    case .twitter(let twitterAccount):
      var result: [String: Any] = [
        "type": "twitter_oauth",
        "subject": twitterAccount.subject,
      ]
      
      if let username = twitterAccount.username {
        result["username"] = username
      }
      
      if let name = twitterAccount.name {
        result["name"] = name
      }
      
      if let profilePictureUrl = twitterAccount.profilePictureUrl {
        result["profile_picture_url"] = profilePictureUrl
      }
      
      if let firstVerifiedAt = twitterAccount.firstVerifiedAt {
        result["first_verified_at"] = Int(firstVerifiedAt.timeIntervalSince1970)
      }
      
      if let latestVerifiedAt = twitterAccount.latestVerifiedAt {
        result["latest_verified_at"] = Int(latestVerifiedAt.timeIntervalSince1970)
      }
      
      return result
    case .discord(let discordAccount):
      var result: [String: Any] = [
        "type": "discord_oauth",
        "subject": discordAccount.subject,
      ]
      
      if let username = discordAccount.username {
        result["username"] = username
      }
      
      if let email = discordAccount.email {
        result["email"] = email
      }
      
      if let firstVerifiedAt = discordAccount.firstVerifiedAt {
        result["first_verified_at"] = Int(firstVerifiedAt.timeIntervalSince1970)
      }
      
      if let latestVerifiedAt = discordAccount.latestVerifiedAt {
        result["latest_verified_at"] = Int(latestVerifiedAt.timeIntervalSince1970)
      }
      
      return result
    case .apple(let appleAccount):
      var result: [String: Any] = [
        "type": "apple_oauth",
        "subject": appleAccount.subject,
        "email": appleAccount.email,
      ]
      
      if let firstVerifiedAt = appleAccount.firstVerifiedAt {
        result["first_verified_at"] = Int(firstVerifiedAt.timeIntervalSince1970)
      }
      
      if let latestVerifiedAt = appleAccount.latestVerifiedAt {
        result["latest_verified_at"] = Int(latestVerifiedAt.timeIntervalSince1970)
      }
      
      return result
    case .externalWallet(let walletAccount):
      var result: [String: Any] = [
        "type": "wallet",
        "address": walletAccount.address,
        "chainType": walletAccount.chainType.asString,
      ]
      
      if let chainId = walletAccount.chainId {
        result["chainId"] = chainId
      }
      
      if let walletClientType = walletAccount.walletClientType {
        result["walletClientType"] = walletClientType
      }
      
      if let connectorType = walletAccount.connectorType {
        result["connectorType"] = connectorType
      }
      
      if let firstVerifiedAt = walletAccount.firstVerifiedAt {
        result["firstVerifiedAt"] = Int(firstVerifiedAt.timeIntervalSince1970)
      }
      
      if let latestVerifiedAt = walletAccount.latestVerifiedAt {
        result["latestVerifiedAt"] = Int(latestVerifiedAt.timeIntervalSince1970)
      }
      
      return result
    case .telegram(let telegramAccount):
      var result: [String: Any] = [
        "type": "telegram",
        "telegram_user_id": telegramAccount.telegramUserId,
      ]

      if let firstName = telegramAccount.firstName {
        result["first_name"] = firstName
      }

      if let lastName = telegramAccount.lastName {
        result["last_name"] = lastName
      }

      if let username = telegramAccount.username {
        result["username"] = username
      }

      if let photoUrl = telegramAccount.photoUrl {
        result["photo_url"] = photoUrl
      }

      if let firstVerifiedAt = telegramAccount.firstVerifiedAt {
        result["first_verified_at"] = Int(firstVerifiedAt.timeIntervalSince1970)
      }

      if let latestVerifiedAt = telegramAccount.latestVerifiedAt {
        result["latest_verified_at"] = Int(latestVerifiedAt.timeIntervalSince1970)
      }

      return result
    case .passkey(let passkeyAccount):
      var result: [String: Any] = [
        "type": "passkey",
        "credentialId": passkeyAccount.credentialId,
        "enrolledInMfa": passkeyAccount.enrolledInMfa,
      ]

      if let authenticatorName = passkeyAccount.authenticatorName {
        result["authenticatorName"] = authenticatorName
      }

      if let createdWithBrowser = passkeyAccount.createdWithBrowser {
        result["createdWithBrowser"] = createdWithBrowser
      }

      if let createdWithOs = passkeyAccount.createdWithOs {
        result["createdWithOs"] = createdWithOs
      }

      if let createdWithDevice = passkeyAccount.createdWithDevice {
        result["createdWithDevice"] = createdWithDevice
      }

      if let publicKey = passkeyAccount.publicKey {
        result["publicKey"] = publicKey
      }

      if let firstVerifiedAt = passkeyAccount.firstVerifiedAt {
        result["firstVerifiedAt"] = Int(firstVerifiedAt.timeIntervalSince1970)
        result["verifiedAt"] = Int(firstVerifiedAt.timeIntervalSince1970)
      }

      if let latestVerifiedAt = passkeyAccount.latestVerifiedAt {
        result["latestVerifiedAt"] = Int(latestVerifiedAt.timeIntervalSince1970)
      }

      return result
    default:
      return nil  // Other account types are ignored
    }
  }
}

/// Extension to serialize `PrivyUser` for Flutter communication.
extension PrivyUser {
  /// Converts a `PrivyUser` into a dictionary format.
  ///
  /// Includes the user ID and serialized linked accounts.
  func serialized() -> [String: Any] {
    return [
      "id": id,
      "linkedAccounts": linkedAccounts.compactMap { $0.serialized() },
      "mfaMethods": mfaMethods.map { $0.serialized() },
      "identityToken": identityToken as Any
    ]
  }
}

/// Extension to serialize `MfaMethod` for Flutter communication.
extension MfaMethod {
  func serialized() -> [String: Any] {
    switch self {
    case .sms(let method):
      return [
        "type": "sms",
        "verifiedAt": Int(method.verifiedAt.timeIntervalSince1970),
      ]
    case .totp(let method):
      return [
        "type": "totp",
        "verifiedAt": Int(method.verifiedAt.timeIntervalSince1970),
      ]
    case .passkey(let method):
      return [
        "type": "passkey",
        "verifiedAt": Int(method.verifiedAt.timeIntervalSince1970),
      ]
    }
  }
}

/// Maps a native error to a typed MFA FlutterError when possible, falling back
/// to `fallbackCode` with `error.localizedDescription` for unrecognised errors.
func mfaFlutterError(from error: Error, fallbackCode: String) -> FlutterError {
  if let privyError = error as? PrivyError,
     case .embeddedWalletFailure(let reason) = privyError.errorCode {
    let code: String = switch reason {
    case .missingOrInvalidMfa: ErrorConstants.mfaMissingOrInvalid
    case .mfaChallengeExpired: ErrorConstants.mfaChallengeExpired
    case .mfaVerificationMaxAttemptsReached: ErrorConstants.mfaMaxAttemptsReached
    case .timeoutOnMfa: ErrorConstants.mfaSdkTimeout
    default: fallbackCode
    }
    return FlutterError(code: code, message: error.localizedDescription, details: nil)
  }
  return FlutterError(
    code: fallbackCode,
    message: error.localizedDescription,
    details: nil
  )
}

/// Wrapper to allow `FlutterError` to be thrown as a Swift `Error`
struct FlutterErrorWrapper: Error {
  let flutterError: FlutterError
}

extension ChainType {
  /// Provides a string representation of `ChainType` without modifying the original enum
  var asString: String {
    switch self {
    case .ethereum: return "ethereum"
    case .solana: return "solana"
    @unknown default: return "unknown"
    }
  }
}

/// Extension to serialize `EmbeddedEthereumWallet` for Flutter communication.
///
/// This allows the `EmbeddedEthereumWallet` type to be converted into a dictionary
/// format so that it can be easily passed through platform channels.
extension EmbeddedEthereumWallet {
  func serialized() -> [String: Any] {
    return [
      "type": "ethereumWallet",
      "address": address,
      "id": id as Any,
      "chainType": chainType.asString,
      "recoveryMethod": recoveryMethod ?? "",
      "hdWalletIndex": hdWalletIndex as Any,
    ]
  }
}

/// Extension to serialize `EmbeddedSolanaWallet` for Flutter communication.
///
/// This allows the `EmbeddedSolanaWallet` type to be converted into a dictionary
/// format so that it can be easily passed through platform channels.
extension EmbeddedSolanaWallet {
  func serialized() -> [String: Any] {
    return [
      "type": "solanaWallet",
      "address": address,
      "id": id as Any,
      "chainType": chainType.asString,
      "recoveryMethod": recoveryMethod ?? "",
      "hdWalletIndex": hdWalletIndex as Any,
    ]
  }
}

/// Extension to serialize `AuthState` for Flutter communication.
extension AuthState {
  /// Converts `AuthState` to a dictionary format expected by Flutter.
  func serialized() -> [String: Any] {
    switch self {
    case .notReady:
      return ["type": "NotReady"]
    case .unauthenticated:
      return ["type": "Unauthenticated"]
    case .authenticatedUnverified:
        return ["type": "AuthenticatedUnverified"]
    case .authenticated(let user):
      return [
        "type": "Authenticated",
        "user": user.serialized(),
      ]
    @unknown default: return ["type": "Unknown"]
    }
  }
}

/// Converts a string representation of log levels into a `PrivyLogLevel` enum.
///
/// This function is used to map a log level string (typically coming from Flutter or external sources)
/// into the corresponding `PrivyLogLevel` enum. If the input is unrecognized, it defaults to `.none`.
///
/// - Parameter logLevelString: A string representing the log level.
/// - Returns: The corresponding `PrivyLogLevel` enum value.
func privyLogLevel(from logLevelString: String?) -> PrivyLogLevel {
  switch logLevelString {
  case "NONE": return .none
  case "ERROR": return .error
  case "WARNING": return .warning
  case "INFO": return .info
  case "DEBUG": return .debug
  case "VERBOSE": return .verbose
  default:
    return .none  // Default log level if input is unrecognized
  }
}

/// Converts a cluster string from Flutter to SolanaCluster enum.
///
/// - Parameter clusterString: A string representing the Solana cluster ("mainnet", "devnet", "testnet").
/// - Returns: The corresponding `SolanaCluster` enum value, or nil if unrecognized.
func convertToSolanaCluster(_ clusterString: String?) -> SolanaCluster? {
  guard let clusterString = clusterString else { return nil }

  switch clusterString.lowercased() {
  case "mainnet": return .mainnet
  case "devnet": return .devnet
  case "testnet": return .testnet
  default: return nil
  }
}

/// Converts a sendOptions dictionary from Flutter to SolanaSendOptions struct.
///
/// - Parameter sendOptionsDict: A dictionary containing optional send options.
/// - Returns: A `SolanaSendOptions` struct if the dictionary is not nil, otherwise nil.
func convertToSendOptions(_ sendOptionsDict: [String: Any]?) -> SolanaSendOptions? {
  guard let dict = sendOptionsDict else { return nil }

  // Convert preflightCommitment string to SolanaSendOptions.Commitment enum if provided
  var commitment: SolanaSendOptions.Commitment? = nil
  if let commitmentString = dict["preflightCommitment"] as? String {
    commitment = SolanaSendOptions.Commitment(rawValue: commitmentString.lowercased())
  }

  return SolanaSendOptions(
    skipPreflight: dict["skipPreflight"] as? Bool,
    preflightCommitment: commitment,
    maxRetries: dict["maxRetries"] as? Int,
    minContextSlot: dict["minContextSlot"] as? Int
  )
}

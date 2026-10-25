enum ErrorConstants {
  // General Errors
  static let loginError = "LOGIN_ERROR"
  static let linkError = "LINK_ERROR"
  static let unlinkError = "UNLINK_ERROR"
  static let invalidArgument = "INVALID_ARGUMENT"
  static let initializationError = "INITIALIZATION_ERROR"
  static let methodChannelNotInitialized = "METHOD_CHANNEL_NOT_INITIALIZED"
  static let unexpectedError = "UNEXPECTED_ERROR"
  // OTP Errors
  static let otpSendFailed = "OTP_SEND_FAILED"
  static let sendOtpError = "SEND_OTP_ERROR"
  static let invalidPhoneFormat = "INVALID_PHONE_FORMAT"

  // Wallet Errors
  static let walletCreationError = "WALLET_CREATION_ERROR"
  static let walletNotFound = "WALLET_NOT_FOUND"
  static let walletNotConnected = "WALLET_NOT_CONNECTED"
  static let solanaSignMessageError = "SOLANA_SIGN_MESSAGE_ERROR"
  static let solanaSignTransactionError = "SOLANA_SIGN_TRANSACTION_ERROR"
  static let solanaSignAndSendTransactionError = "SOLANA_SIGN_AND_SEND_TRANSACTION_ERROR"
  static let walletConnectionError = "WALLET_CONNECTION_ERROR"
  // RPC Request Errors
  static let rpcRequestFailed = "RPC_REQUEST_FAILED"
  static let ethRpcRequestError = "ETH_RPC_REQUEST_ERROR"

  // SDK Errors
  static let sdkNotInitialized = "SDK_NOT_INITIALIZED"
  static let awaitReadyError = "AWAIT_READY_ERROR"

  // Logout Errors
  static let logoutError = "LOGOUT_ERROR"
  static let getUserError = "GET_USER_ERROR"
  static let refreshUserError = "REFRESH_USER_ERROR"

  // Auth Errors
  static let userNotAuthenticated = "USER_NOT_AUTHENTICATED"
  static let userNotFound = "USER_NOT_FOUND"
  static let getAccessTokenError = "ACCESS_TOKEN_ERROR"
  
  // SIWE Errors
  static let siweGenerateMessageError = "SIWE_GENERATE_MESSAGE_ERROR"
  static let siweLoginError = "SIWE_LOGIN_ERROR"
  static let siweLinkError = "SIWE_LINK_ERROR"

  // SIWS Errors
  static let siwsGenerateMessageError = "SIWS_GENERATE_MESSAGE_ERROR"
  static let siwsLoginError = "SIWS_LOGIN_ERROR"

  // Authorization Signature Errors
  static let generateAuthorizationSignatureError = "GENERATE_AUTHORIZATION_SIGNATURE_ERROR"

  // Update Errors
  static let emailUpdateError = "EMAIL_UPDATE_ERROR"
  static let smsUpdateError = "SMS_UPDATE_ERROR"

  // Signer Errors
  static let addSignersError = "ADD_SIGNERS_ERROR"
  static let removeSignerError = "REMOVE_SIGNER_ERROR"
  static let removeAllSignersError = "REMOVE_ALL_SIGNERS_ERROR"

  // Migration Errors
  static let walletMigrationError = "WALLET_MIGRATION_ERROR"

  // MFA Errors
  static let mfaError = "MFA_ERROR"
  static let mfaSmsError = "MFA_SMS_ERROR"
  static let mfaTotpError = "MFA_TOTP_ERROR"
  static let mfaPasskeyError = "MFA_PASSKEY_ERROR"
  static let mfaMissingOrInvalid = "MFA_MISSING_OR_INVALID"
  static let mfaChallengeExpired = "MFA_CHALLENGE_EXPIRED"
  static let mfaMaxAttemptsReached = "MFA_MAX_ATTEMPTS_REACHED"
  static let mfaSdkTimeout = "MFA_SDK_TIMEOUT"
}

import Combine
import Flutter
import Foundation
import PrivySDK

/// Singleton class to manage the Privy instance.
class PrivyManager {
  static let shared = PrivyManager()

  var privy: Privy!
  private(set) var isInitialized = false

  private var flutterMethodChannel: FlutterMethodChannel?  // Reference to the Flutter MethodChannel

  private init() {}  // Prevent external instantiation

  /// Initializes the Privy instance.
  func initialize(
    appId: String,
    appClientId: String,
    methodChannel: FlutterMethodChannel? = nil,
    tokenProvider: (() async throws -> String)?,
    privyLogLevel: PrivyLogLevel,
    mfaConfig: PrivyMFAConfig? = nil,
    disableAutomaticMigration: Bool = false
  ) {
    guard !isInitialized else { return }  // Prevent reinitialization
    self.flutterMethodChannel = methodChannel

    // Assign customAuthConfig only if tokenProvider is not nil
    let customAuthConfig: PrivyLoginWithCustomAuthConfig? =
      if let tknProvider = tokenProvider {
        PrivyLoginWithCustomAuthConfig(tokenProvider: tknProvider)
      } else {
        nil
      }

    let embeddedWalletConfig: PrivyEmbeddedWalletConfig? =
      disableAutomaticMigration
      ? PrivyEmbeddedWalletConfig(disableAutomaticMigration: true)
      : nil

    let config = PrivyConfig(
      appId: appId,
      appClientId: appClientId,
      loggingConfig: .init(logLevel: privyLogLevel),
      customAuthConfig: customAuthConfig,
      mfaConfig: mfaConfig,
      embeddedWalletConfig: embeddedWalletConfig
    )
    privy = PrivySdk.initialize(config: config)
    isInitialized = true

  }
}

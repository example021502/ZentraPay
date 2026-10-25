import Flutter
import PrivySDK

/// Handles Privy SDK initialization from Flutter.
class InitializationHandler: MethodHandler {
  private let methodChannel: FlutterMethodChannel

  /// Define supported methods directly
  private let initializePrivy = "initializePrivy"

  /// Define supported methods directly
  var supportedMethods: Set<String> {
    [initializePrivy]
  }

  /// Initializes the handler with the Flutter MethodChannel.
  init(methodChannel: FlutterMethodChannel) {
    self.methodChannel = methodChannel
  }

  /// Handles method calls related to initialization.
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case initializePrivy:
      initializePrivy(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Extracts parameters from the method call and initializes Privy.
  private func initializePrivy(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let appId = args["appId"] as? String,
      let shouldInitializeCustomAuth = args["shouldInitializeCustomAuth"] as? Bool,
      let appClientId = args["appClientId"] as? String,
      let logLevelString = args["logLevel"] as? String

    else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument, message: "Missing appId or appClientId",
          details: nil))
      return
    }

    let privyLogLevel = privyLogLevel(from: logLevelString)

    let tokenProvider: (() async throws -> String)? =
      shouldInitializeCustomAuth
      ? { try await self.fetchTokenFromFlutter() }
      : nil

    let shouldInitializeMfa = args["shouldInitializeMfa"] as? Bool ?? false
    let mfaTimeoutMs = args["mfaTimeoutMs"] as? Int

    let mfaConfig: PrivyMFAConfig? = if shouldInitializeMfa {
        if let mfaTimeoutMs = mfaTimeoutMs {
            PrivyMFAConfig(
                delegate: FlutterInitMfaDelegate(methodChannel: methodChannel),
                mfaTimeout: .milliseconds(mfaTimeoutMs)
            )
        } else {
            PrivyMFAConfig(
                delegate: FlutterInitMfaDelegate(methodChannel: methodChannel)
            )
        }
    } else {
        nil
    }

    let disableAutomaticMigration = args["disableAutomaticMigration"] as? Bool ?? false

    PrivyManager.shared.initialize(
      appId: appId,
      appClientId: appClientId,
      methodChannel: methodChannel,
      tokenProvider: tokenProvider,
      privyLogLevel: privyLogLevel,
      mfaConfig: mfaConfig,
      disableAutomaticMigration: disableAutomaticMigration
    )
    MainThreadHelper.postSuccess(result, true)
  }

  private func fetchTokenFromFlutter() async throws -> String {

    return try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.main.async {

        self.methodChannel.invokeMethod("getCustomAuthToken", arguments: nil) { result in
          switch result {
          case let token as String
          where !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty:
            continuation.resume(returning: token)
          case let error as FlutterError:
            continuation.resume(throwing: FlutterErrorWrapper(flutterError: error))
          default:
            continuation.resume(
              throwing: FlutterErrorWrapper(
                flutterError: FlutterError(
                  code: ErrorConstants.unexpectedError,
                  message: "Unexpected or empty token result from Flutter MethodChannel",
                  details: nil
                )
              )
            )
          }
        }
      }
    }
  }
}

/// MFA delegate used when MFA is configured at initialization time.
private class FlutterInitMfaDelegate: PrivyMfaPromptDelegate {
    private let methodChannel: FlutterMethodChannel

    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
    }

    @MainActor
    func onMfaRequired(for user: any PrivyUser) {
        methodChannel.invokeMethod("onMfaRequired", arguments: user.serialized())
    }
}

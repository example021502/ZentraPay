import Flutter
import PrivySDK

/// Handles passkey authentication in the Privy SDK for Flutter.
class PasskeyHandler: MethodHandler {
  private let methodChannel: FlutterMethodChannel

  /// Private method constants
  private let passkeySignup = "passkeySignup"
  private let passkeyLogin = "passkeyLogin"
  private let passkeyLink = "passkeyLink"
  private let passkeyUnlink = "passkeyUnlink"

  /// Define supported methods directly
  var supportedMethods: Set<String> {
    [passkeySignup, passkeyLogin, passkeyLink, passkeyUnlink]
  }

  /// Initializes the handler with the Flutter MethodChannel.
  init(methodChannel: FlutterMethodChannel) {
    self.methodChannel = methodChannel
  }

  /// Handles incoming method calls from Flutter.
  /// - Parameters:
  ///   - call: The Flutter method call containing the method name and arguments.
  ///   - result: The callback to send a response back to Flutter.
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case passkeySignup:
      signup(call, result: result)
    case passkeyLogin:
      login(call, result: result)
    case passkeyLink:
      link(call, result: result)
    case passkeyUnlink:
      unlink(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Signs up a new user with a passkey.
  private func signup(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let relyingParty = args["relyingParty"] as? String
    else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Relying party is required",
          details: nil
        )
      )
      return
    }

    let displayName = args["displayName"] as? String

    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

    Task {
      do {
        let privyUser = try await PrivyManager.shared.privy.passkey.signup(
          relyingParty: relyingParty,
          displayName: displayName
        )

        MainThreadHelper.postSuccess(result, privyUser.serialized())
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: "PASSKEY_SIGNUP_ERROR",
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    }
  }

  /// Logs in an existing user with their passkey.
  private func login(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let relyingParty = args["relyingParty"] as? String
    else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Relying party is required",
          details: nil
        )
      )
      return
    }

    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

    Task {
      do {
        let privyUser = try await PrivyManager.shared.privy.passkey.login(
          relyingParty: relyingParty
        )

        MainThreadHelper.postSuccess(result, privyUser.serialized())
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: "PASSKEY_LOGIN_ERROR",
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    }
  }

  /// Links a passkey to the currently authenticated user's account.
  private func link(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let relyingParty = args["relyingParty"] as? String
    else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Relying party is required",
          details: nil
        )
      )
      return
    }

    let displayName = args["displayName"] as? String

    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

    Task {
      do {
        let privyUser = try await PrivyManager.shared.privy.passkey.link(
          relyingParty: relyingParty,
          displayName: displayName
        )

        MainThreadHelper.postSuccess(result, privyUser.serialized())
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.linkError,
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    }
  }

  /// Unlinks a passkey from the currently authenticated user's account.
  private func unlink(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let credentialId = args["credentialId"] as? String
    else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Credential ID is required",
          details: nil
        )
      )
      return
    }

    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

    Task {
      do {
        let privyUser = try await PrivyManager.shared.privy.passkey.unlink(
          credentialId: credentialId
        )

        MainThreadHelper.postSuccess(result, privyUser.serialized())
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.unlinkError,
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    }
  }
}

import Flutter
import PrivySDK

/// Handles email authentication in the Privy SDK for Flutter.
class EmailHandler: MethodHandler {
  private let methodChannel: FlutterMethodChannel

  /// Private method constants
  private let emailSendCode = "emailSendCode"
  private let emailLoginWithCode = "emailLoginWithCode"
  private let emailLinkWithCode = "emailLinkWithCode"
  private let emailUpdateWithCode = "emailUpdateWithCode"
  private let emailUnlink = "emailUnlink"

  /// Define supported methods directly
  var supportedMethods: Set<String> {
    [emailSendCode, emailLoginWithCode, emailLinkWithCode, emailUpdateWithCode, emailUnlink]
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
    case emailSendCode:
      sendCode(call, result: result)
    case emailLoginWithCode:
      loginWithEmail(call, result: result)
    case emailLinkWithCode:
      linkWithCode(call, result: result)
    case emailUpdateWithCode:
      updateWithCode(call, result: result)
    case emailUnlink:
      unlink(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Sends a one-time password (OTP) to the user's email.
  private func sendCode(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any], let email = args["email"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument, message: "Email address is required", details: nil))
      return
    }

    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

    Task {
      do {

        try await PrivyManager.shared.privy.email.sendCode(to: email)

        MainThreadHelper.postSuccess(result, true)
      } catch {

        MainThreadHelper.postError(
          result,
          FlutterError(code: "SEND_OTP_ERROR", message: error.localizedDescription, details: nil))
      }
    }
  }

  /// Logs in a user using an OTP code sent to their email.
  /// **After successful login, it updates `PrivyManager.shared` so authentication updates are handled properly.**
  private func loginWithEmail(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any], let code = args["code"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument, message: "OTP code is required", details: nil))
      return
    }

    guard let email = args["email"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Email is required",
          details: nil
        )
      )
      return
    }

    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

    Task {
      do {
        let privyUser = try await PrivyManager.shared.privy.email.loginWithCode(code, sentTo: email)

        MainThreadHelper.postSuccess(result, privyUser.serialized())

      } catch {

        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.loginError, message: error.localizedDescription, details: nil))

      }
    }
  }
  
  /// Links an email account to the current user using an OTP code.
  /// This allows adding email authentication to an existing user account.
  private func linkWithCode(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any], let code = args["code"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument, message: "OTP code is required", details: nil))
      return
    }
    
    guard let email = args["email"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Email is required",
          details: nil
        )
      )
      return
    }
    
    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }
    
    Task {
      do {
        let privyUser = try await PrivyManager.shared.privy.email.linkWithCode(code, sentTo: email)
        MainThreadHelper.postSuccess(result, privyUser.serialized())
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.linkError, message: error.localizedDescription, details: nil))
      }
    }
  }
  
  /// Updates the user's email using an OTP code.
  /// This allows changing the email address associated with the current user.
  private func updateWithCode(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any], let code = args["code"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument, message: "OTP code is required", details: nil))
      return
    }
    
    guard let email = args["email"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Email is required",
          details: nil
        )
      )
      return
    }
    
    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }
    
    Task {
      do {
        // Update the email for the current user
        try await PrivyManager.shared.privy.email.updateWithCode(code, sentTo: email)

        // Return success since the updateWithCode method doesn't return anything
        MainThreadHelper.postSuccess(result, true)

      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.emailUpdateError, message: error.localizedDescription, details: nil))
      }
    }
  }

  /// Unlinks an email from the current user.
  /// Returns the updated PrivyUser on success.
  private func unlink(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let email = args["email"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Email is required",
          details: nil))
      return
    }

    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

    Task {
      do {
        let privyUser = try await PrivyManager.shared.privy.email.unlink(email: email)
        MainThreadHelper.postSuccess(result, privyUser.serialized())
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.unlinkError,
            message: error.localizedDescription,
            details: nil))
      }
    }
  }
}

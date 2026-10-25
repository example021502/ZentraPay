import Flutter
import PrivySDK

/// Handles SMS authentication in the Privy SDK for Flutter.
class SmsHandler: MethodHandler {
  private let methodChannel: FlutterMethodChannel

  /// Initializes the handler with the Flutter MethodChannel.
  init(methodChannel: FlutterMethodChannel) {
    self.methodChannel = methodChannel
  }

  //Private method constants
  private let smsSendCode = "smsSendCode"
  private let smsLoginWithCode = "smsLoginWithCode"
  private let smsLinkWithCode = "smsLinkWithCode"
  private let smsUpdateWithCode = "smsUpdateWithCode"
  private let smsUnlink = "smsUnlink"

  /// Define supported methods directly
  var supportedMethods: Set<String> {
    [smsSendCode, smsLoginWithCode, smsLinkWithCode, smsUpdateWithCode, smsUnlink]
  }

  /// Handles method calls for SMS authentication.
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case smsSendCode:
      sendOtp(call, result: result)
    case smsLoginWithCode:
      loginWithCode(call, result: result)
    case smsLinkWithCode:
      linkWithCode(call, result: result)
    case smsUpdateWithCode:
      updateWithCode(call, result: result)
    case smsUnlink:
      unlink(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Sends a one-time password (OTP) to the user's phone number using PrivyManager.
  private func sendOtp(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let phoneNumber = args["phoneNumber"] as? String
    else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument, message: "Phone number is required", details: nil))
      return
    }

    // Validate Privy SDK initialization
    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

    // Validate phone number format (E.164)
    guard isValidPhoneNumber(phoneNumber) else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidPhoneFormat, message: "Phone number must be in E.164 format",
          details: nil))
      return
    }

    // Asynchronous task to send OTP
    Task {
      do {

        try await PrivyManager.shared.privy.sms.sendCode(to: phoneNumber)

        MainThreadHelper.postSuccess(result, true)

      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.sendOtpError, message: error.localizedDescription, details: nil))
      }
    }
  }

  /// Logs in a user using an OTP code sent to their phone number.
  ///
  /// **After successful login, it updates `PrivyManager.shared` so authentication updates are handled properly.**
  private func loginWithCode(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let code = args["code"] as? String
    else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument, message: "OTP code is required", details: nil))
      return
    }

    guard let phoneNumber = args["phoneNumber"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: "INVALID_ARGUMENT",
          message: "Phone Number is required",
          details: nil
        )
      )
      return
    }

    // Validate Privy SDK initialization
    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

    // Perform authentication with OTP
    Task {
      do {
        // Perform login and get the auth state
        let privyUser = try await PrivyManager.shared.privy.sms.loginWithCode(
          code, sentTo: phoneNumber)

        MainThreadHelper.postSuccess(result, privyUser.serialized())
      } catch {
        // Handle any login error
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.loginError,
            message:
              error.localizedDescription,
            details: nil))
      }
    }
  }

  /// Links a phone number to the current user using an OTP code.
  /// This allows adding SMS authentication to an existing user account.
  private func linkWithCode(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any], let code = args["code"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument, message: "OTP code is required", details: nil))
      return
    }
    
    guard let phoneNumber = args["phoneNumber"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Phone number is required",
          details: nil
        )
      )
      return
    }
    
    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }
    
    // Validate phone number format (E.164)
    guard isValidPhoneNumber(phoneNumber) else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidPhoneFormat, message: "Phone number must be in E.164 format",
          details: nil))
      return
    }
    
    Task {
      do {
        let privyUser = try await PrivyManager.shared.privy.sms.linkWithCode(code, sentTo: phoneNumber)
        MainThreadHelper.postSuccess(result, privyUser.serialized())
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.linkError, message: error.localizedDescription, details: nil))
      }
    }
  }

  /// Updates the user's phone number using an OTP code.
  /// This allows changing the phone number associated with the current user.
  private func updateWithCode(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any], let code = args["code"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument, message: "OTP code is required", details: nil))
      return
    }
    
    guard let phoneNumber = args["phoneNumber"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Phone number is required",
          details: nil
        )
      )
      return
    }
    
    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }
    
    // Validate phone number format (E.164)
    guard isValidPhoneNumber(phoneNumber) else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidPhoneFormat, message: "Phone number must be in E.164 format",
          details: nil))
      return
    }
    
    Task {
      do {
        // Update the phone number for the current user
        try await PrivyManager.shared.privy.sms.updateWithCode(code, sentTo: phoneNumber)
        
        // Return success since the updateWithCode method doesn't return anything
        MainThreadHelper.postSuccess(result, true)
        
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.smsUpdateError, message: error.localizedDescription, details: nil))
      }
    }
  }

  /// Validates phone number format (E.164: `+[country code][number]` with 10-15 digits).
  private func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
    let regex = "^\\+\\d{10,15}$"
    return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: phoneNumber)
  }

  /// Unlinks a phone number from the current user.
  /// Returns the updated PrivyUser on success.
  private func unlink(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let phoneNumber = args["phoneNumber"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Phone number is required",
          details: nil))
      return
    }

    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

    Task {
      do {
        let privyUser = try await PrivyManager.shared.privy.sms.unlink(phoneNumber: phoneNumber)
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

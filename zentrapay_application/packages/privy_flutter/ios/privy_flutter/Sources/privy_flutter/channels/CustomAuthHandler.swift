import Flutter
import Foundation
import PrivySDK

/// Handles custom authentication via Flutter's MethodChannel.
class CustomAuthHandler: MethodHandler {
  private let methodChannel: FlutterMethodChannel

  /// Private method constants
  private let loginWithCustomAccessToken = "loginWithCustomAccessToken"

  /// Define supported methods directly
  var supportedMethods: Set<String> {
    [loginWithCustomAccessToken]
  }

  /// Initializes the handler with the Flutter MethodChannel.
  init(methodChannel: FlutterMethodChannel) {
    self.methodChannel = methodChannel
  }

  /// Handles incoming method calls related to custom authentication.
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case loginWithCustomAccessToken:
      loginWithCustomAccessToken(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Performs login using a custom access token.
  private func loginWithCustomAccessToken(result: @escaping FlutterResult) {
    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

    Task {
      do {
        let privyUser = try await PrivyManager.shared.privy.customJwt.loginWithCustomAccessToken()

        MainThreadHelper.postSuccess(result, privyUser.serialized())

      } catch {

        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.loginError,
            message: "Login with custom access token failed",
            details: error.localizedDescription
          ))

      }
    }
  }
}

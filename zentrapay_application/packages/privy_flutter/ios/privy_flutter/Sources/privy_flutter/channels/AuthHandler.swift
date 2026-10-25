import Flutter
import PrivySDK

/// Handles authentication-related methods in the Privy SDK for Flutter.
class AuthHandler: MethodHandler {
  private let methodChannel: FlutterMethodChannel

  /// Private method constants
  private let logout = "logout"
  private let awaitReady = "awaitReady"
  private let getUser = "getUser"
  private let refreshUser = "refreshUser"
  private let getAccessToken = "getAccessToken"
  private let getAuthState = "getAuthState"
  /// Define supported methods directly
  var supportedMethods: Set<String> {
    [logout, awaitReady, getAccessToken, getAuthState, getUser, refreshUser]
  }

  /// Initializes the handler with the Flutter MethodChannel.
  init(methodChannel: FlutterMethodChannel) {
    self.methodChannel = methodChannel
  }

  /// Handles method calls for authentication.
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case logout:
      logout(result: result)
    case awaitReady:
      awaitReady(result: result)
    case getUser:
      getUser(result: result)
    case refreshUser:
      refreshUser(result: result)
    case getAccessToken:
      getAccessToken(result: result)
    case getAuthState:
      getAuthState(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Calls Privy SDK to ensure it's fully initialized before proceeding.
  private func awaitReady(result: @escaping FlutterResult) {
    guard let privy = PrivyManager.shared.privy else {
      return
    }
    Task {
      await privy.awaitReady()
      MainThreadHelper.postSuccess(result, nil)
    }
  }

  /// Logs out the current user.
  /// If the user is already logged out on the native side, this succeeds silently.
  private func logout(result: @escaping FlutterResult) {
    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

    Task {
      if let user = await PrivyManager.shared.privy?.getUser() {
        await user.logout()
      }
      MainThreadHelper.postSuccess(result, true)
    }
  }

  /// **Fetches the latest access token by refreshing the session**
  private func getAccessToken(result: @escaping FlutterResult) {
    Task {
      guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

      do {
        // Get the access token (automatically refreshes session if needed)
        let accessToken = try await user.getAccessToken()

        // Return accessToken to Flutter
        MainThreadHelper.postSuccess(result, accessToken)

      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.getAccessTokenError,
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    }
  }

    /// Calls Privy SDK to ensure it's fully initialized before proceeding.
  private func getAuthState(result: @escaping FlutterResult) {
    guard let privy = PrivyManager.shared.privy else {
      return
    }
    Task {
      let authState = await privy.getAuthState()
      let serializedState = authState.serialized()
      MainThreadHelper.postSuccess(result, serializedState)
    }
  }

  /// Fetches the current Privy user.
  private func getUser(result: @escaping FlutterResult) {
    guard let privy = PrivyManager.shared.privy else {
      return
    }
    Task {
      if let user = await privy.getUser() {
        let serializedUser = user.serialized()
        MainThreadHelper.postSuccess(result, serializedUser)
      } else {
        MainThreadHelper.postSuccess(result, nil)
      }
    }
  }

  /// Refreshes the user data from the server, then returns the updated user.
  private func refreshUser(result: @escaping FlutterResult) {
    guard let privy = PrivyManager.shared.privy else {
      return
    }
    Task {
      do {
        guard let user = await privy.getUser() else {
          MainThreadHelper.postError(
            result,
            FlutterError(
              code: ErrorConstants.userNotFound,
              message: "User is not authenticated",
              details: nil
            )
          )
          return
        }
        try await user.refresh()
        let refreshedUser = await privy.getUser()
        let serializedUser = refreshedUser?.serialized()
        MainThreadHelper.postSuccess(result, serializedUser)
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.getUserError,
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    }
  }
}

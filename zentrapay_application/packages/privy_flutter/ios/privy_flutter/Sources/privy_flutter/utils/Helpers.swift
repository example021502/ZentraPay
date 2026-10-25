import Flutter
import Foundation
import PrivySDK

/// Helper functions for common Privy operations
class PrivyHelpers {
  /// Ensures the Privy SDK is initialized or posts an error
  ///
  /// - Parameter result: The Flutter result callback
  /// - Returns: true if initialized, false otherwise (error already posted)
  static func ensureInitializedOrPostError(_ result: @escaping FlutterResult) -> Bool {
    guard PrivyManager.shared.isInitialized else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.sdkNotInitialized,
          message: "Privy SDK is not initialized",
          details: nil
        )
      )
      return false
    }
    return true
  }

  /// Fetches the current authenticated user or posts an error
  ///
  /// - Parameter result: The Flutter result callback
  /// - Returns: The current PrivyUser if authenticated, nil otherwise (error already posted)
  static func getUserOrPostError(_ result: @escaping FlutterResult) async -> PrivyUser? {
    guard let privy = PrivyManager.shared.privy,
          let user = await privy.getUser() else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.userNotAuthenticated,
          message: "User not authenticated.",
          details: nil))
      return nil
    }
    return user
  }
}

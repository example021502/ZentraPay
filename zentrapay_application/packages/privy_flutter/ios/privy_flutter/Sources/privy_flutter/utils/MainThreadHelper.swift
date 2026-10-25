import Flutter
import Foundation

/// Helper functions to handle success and error responses on the main thread.
struct MainThreadHelper {

  /// Calls `success` on the main thread. Allows `response` to be `nil`.
  static func postSuccess(_ result: @escaping FlutterResult, _ response: Any? = nil) {
    DispatchQueue.main.async {
      result(response)
    }
  }

  /// Calls `error` on the main thread, requiring a `FlutterError` object.
  static func postError(_ result: @escaping FlutterResult, _ error: FlutterError) {
    DispatchQueue.main.async {
      result(error)
    }
  }
}

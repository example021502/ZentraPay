import Flutter
import PrivySDK

/// Handles setting the SDK version in the Privy Flutter plugin.
class VersionHandler: MethodHandler {
  private let methodChannel: FlutterMethodChannel

  /// Private method constants
  private let setPubDevVersion = "setPubDevVersion"

  /// Define supported methods directly
  var supportedMethods: Set<String> {
    [setPubDevVersion]
  }

  /// Initializes the handler with the Flutter MethodChannel.
  init(methodChannel: FlutterMethodChannel) {
    self.methodChannel = methodChannel
  }

  /// Handles method calls for setting the SDK version.
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case setPubDevVersion:
      handleSetPubDevVersion(result: result, call: call)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Processes the setPubDevVersion method call.
  private func handleSetPubDevVersion(result: @escaping FlutterResult, call: FlutterMethodCall) {
    // Define constant keys (since we can't access them from PrivyInternal)
    let KEY_PLATFORM = "platform"
    let KEY_VERSION = "version"
    let KEY_SECRET = "secret"
    let SECRET_KEY = "caba52bb-499e-4034-aaa6-bb4fbcdee175"  // Ensure this matches the expected secret

    guard let args = call.arguments as? [String: Any],
      let sdkVersion = args["sdkVersion"] as? String
    else {
      result(
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Missing sdkVersion",
          details: nil))
      return
    }

    let config: [String: String] = [
      KEY_PLATFORM: "flutter",
      KEY_VERSION: sdkVersion,
      KEY_SECRET: SECRET_KEY,
    ]

    PrivyInternal.setConfig(config: config)

    MainThreadHelper.postSuccess(result, nil)
  }
}

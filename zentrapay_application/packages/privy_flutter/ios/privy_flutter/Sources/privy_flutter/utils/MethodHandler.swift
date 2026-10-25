import Flutter

/// Protocol for method handlers that provides default implementation for canHandle.
protocol MethodHandler {
  var supportedMethods: Set<String> { get }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult)

  /// Default implementation for checking if the method can be handled.
  func canHandle(_ method: String) -> Bool
}

extension MethodHandler {
  func canHandle(_ method: String) -> Bool {
    return supportedMethods.contains(method)
  }
}

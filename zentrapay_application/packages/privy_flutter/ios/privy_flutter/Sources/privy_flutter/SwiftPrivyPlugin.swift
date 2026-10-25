import Flutter
import PrivySDK
import UIKit

/// Main entry point for the Flutter Privy plugin.
/// Registers method channels and event channels, and handles method calls.
public class SwiftPrivyPlugin: NSObject, FlutterPlugin {
  private let methodChannel: FlutterMethodChannel
  private let handlers: [MethodHandler]

  /// Registers the plugin with the Flutter framework.
  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(
      name: "privy_flutter",
      binaryMessenger: registrar.messenger()
    )

    let instance = SwiftPrivyPlugin(methodChannel: methodChannel)
    registrar.addMethodCallDelegate(instance, channel: methodChannel)

    // Register EventChannel for auth state changes
    let authStateEventChannel = FlutterEventChannel(
      name: "privy_flutter/authState",
      binaryMessenger: registrar.messenger()
    )
    authStateEventChannel.setStreamHandler(AuthStateEventChannelHandler())
  }

  /// Initializes the plugin and its method handlers.
  init(methodChannel: FlutterMethodChannel) {
    self.methodChannel = methodChannel
    self.handlers = [
      InitializationHandler(methodChannel: methodChannel),
      EmailHandler(methodChannel: methodChannel),
      SmsHandler(methodChannel: methodChannel),
      AuthHandler(methodChannel: methodChannel),
      CustomAuthHandler(methodChannel: methodChannel),
      WalletHandler(methodChannel: methodChannel),
      VersionHandler(methodChannel: methodChannel),
      OAuthHandler(methodChannel: methodChannel),
      SiweAuthHandler(methodChannel: methodChannel),
      SiwsAuthHandler(methodChannel: methodChannel),
      PasskeyHandler(methodChannel: methodChannel),
      AuthorizationSignatureHandler(methodChannel: methodChannel),
      MfaCoreHandler(methodChannel: methodChannel),
      MfaSmsHandler(methodChannel: methodChannel),
      MfaTotpHandler(methodChannel: methodChannel),
      MfaPasskeyHandler(methodChannel: methodChannel)
    ]
  }
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if let handler = handlers.first(where: { $0.canHandle(call.method) }) {
      handler.handle(call, result: result)
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
}

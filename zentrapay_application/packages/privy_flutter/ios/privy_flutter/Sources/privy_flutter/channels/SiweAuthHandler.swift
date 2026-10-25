import Flutter
import PrivySDK

/// Handles SIWE (Sign-In with Ethereum) authentication in the Privy SDK for Flutter.
class SiweAuthHandler: MethodHandler {
  private let methodChannel: FlutterMethodChannel

  /// Private method constants
  private let generateSiweMessage = "generateSiweMessage"
  private let siweLogin = "siweLogin"
  private let siweLink = "siweLink"
  private let siweUnlink = "siweUnlink"

  /// Define supported methods directly
  var supportedMethods: Set<String> {
    [generateSiweMessage, siweLogin, siweLink, siweUnlink]
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
    case generateSiweMessage:
      generateSiweMessage(call, result: result)
    case siweLogin:
      loginWithSiwe(call, result: result)
    case siweLink:
      linkWithSiwe(call, result: result)
    case siweUnlink:
      unlinkWithSiwe(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Generates a SIWE message for the user to sign.
  private func generateSiweMessage(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Arguments are required",
          details: nil
        )
      )
      return
    }

    guard let appDomain = args["appDomain"] as? String,
          let appUri = args["appUri"] as? String,
          let chainId = args["chainId"] as? String,
          let walletAddress = args["walletAddress"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "appDomain, appUri, chainId, and walletAddress are required",
          details: nil
        )
      )
      return
    }

    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

    Task {
      do {
        let siweParams = SiweMessageParams(
          appDomain: appDomain,
          appUri: appUri,
          chainId: chainId,
          walletAddress: walletAddress
        )

        // Use the new generateMessage() method from iOS SDK
        let message = try await PrivyManager.shared.privy.siwe.generateMessage(params: siweParams)

        MainThreadHelper.postSuccess(result, message)
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.siweGenerateMessageError,
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    }
  }

  /// Logs in a user using a SIWE signature.
  private func loginWithSiwe(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Arguments are required",
          details: nil
        )
      )
      return
    }

    guard let message = args["message"] as? String,
          let signature = args["signature"] as? String,
          let appDomain = args["appDomain"] as? String,
          let appUri = args["appUri"] as? String,
          let chainId = args["chainId"] as? String,
          let walletAddress = args["walletAddress"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "message, signature, appDomain, appUri, chainId, and walletAddress are required",
          details: nil
        )
      )
      return
    }

    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

    Task {
      do {
        let siweParams = SiweMessageParams(
          appDomain: appDomain,
          appUri: appUri,
          chainId: chainId,
          walletAddress: walletAddress
        )

        // Extract optional wallet metadata
        let walletClientTypeString = args["walletClientType"] as? String
        let connectorType = args["connectorType"] as? String
        
        var metadata: WalletLoginMetadata?
        if walletClientTypeString != nil || connectorType != nil {
          let walletClientType = walletClientTypeString != nil ? WalletClientType(rawValue: walletClientTypeString!) : nil
          metadata = WalletLoginMetadata(
            walletClientType: walletClientType,
            connectorType: connectorType
          )
        }

        // Use the new login() method from iOS SDK
        let privyUser = try await PrivyManager.shared.privy.siwe.login(
          message: message,
          signature: signature,
          params: siweParams,
          metadata: metadata
        )

        MainThreadHelper.postSuccess(result, privyUser.serialized())
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.siweLoginError,
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    }
  }

  /// Links a wallet to the current authenticated user using SIWE signature.
  private func linkWithSiwe(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Arguments are required",
          details: nil
        )
      )
      return
    }

    guard let message = args["message"] as? String,
          let signature = args["signature"] as? String,
          let appDomain = args["appDomain"] as? String,
          let appUri = args["appUri"] as? String,
          let chainId = args["chainId"] as? String,
          let walletAddress = args["walletAddress"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "message, signature, appDomain, appUri, chainId, and walletAddress are required",
          details: nil
        )
      )
      return
    }

    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

    Task {
      do {
        let siweParams = SiweMessageParams(
          appDomain: appDomain,
          appUri: appUri,
          chainId: chainId,
          walletAddress: walletAddress
        )

        // Extract optional wallet metadata
        let walletClientTypeString = args["walletClientType"] as? String
        let connectorType = args["connectorType"] as? String
        
        var metadata: WalletLoginMetadata?
        if walletClientTypeString != nil || connectorType != nil {
          let walletClientType = walletClientTypeString != nil ? WalletClientType(rawValue: walletClientTypeString!) : nil
          metadata = WalletLoginMetadata(
            walletClientType: walletClientType,
            connectorType: connectorType
          )
        }

        let privyUser = try await PrivyManager.shared.privy.siwe.link(
          message: message,
          signature: signature,
          params: siweParams,
          metadata: metadata
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

  /// Unlinks an Ethereum wallet from the currently authenticated user.
  /// Returns the updated PrivyUser on success.
  private func unlinkWithSiwe(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Arguments are required",
          details: nil
        )
      )
      return
    }

    guard let address = args["address"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "address is required",
          details: nil
        )
      )
      return
    }

    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

    Task {
      do {
        let privyUser = try await PrivyManager.shared.privy.siwe.unlink(address: address)

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
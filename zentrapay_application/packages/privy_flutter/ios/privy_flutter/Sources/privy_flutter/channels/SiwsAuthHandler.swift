import Flutter
import PrivySDK

/// Handles SIWS (Sign-In with Solana) authentication in the Privy SDK for Flutter.
class SiwsAuthHandler: MethodHandler {
  private let methodChannel: FlutterMethodChannel

  /// Private method constants
  private let generateSiwsMessage = "generateSiwsMessage"
  private let siwsLogin = "siwsLogin"
  private let siwsLink = "siwsLink"
  private let siwsUnlink = "siwsUnlink"

  /// Define supported methods directly
  var supportedMethods: Set<String> {
    [generateSiwsMessage, siwsLogin, siwsLink, siwsUnlink]
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
    case generateSiwsMessage:
      generateSiwsMessage(call, result: result)
    case siwsLogin:
      loginWithSiws(call, result: result)
    case siwsLink:
      linkWithSiws(call, result: result)
    case siwsUnlink:
      unlinkWithSiws(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Generates a SIWS message for the user to sign.
  private func generateSiwsMessage(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
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
          let walletAddress = args["walletAddress"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "appDomain, appUri, and walletAddress are required",
          details: nil
        )
      )
      return
    }

    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

    Task {
      do {
        let siwsParams = SiwsMessageParams(
          domain: appDomain,
          uri: appUri,
          address: walletAddress
        )

        let message = try await PrivyManager.shared.privy.siws.generateMessage(params: siwsParams)

        MainThreadHelper.postSuccess(result, message)
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.siwsGenerateMessageError,
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    }
  }

  /// Logs in a user using a SIWS signature.
  private func loginWithSiws(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
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
          let walletAddress = args["walletAddress"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "message, signature, appDomain, appUri, and walletAddress are required",
          details: nil
        )
      )
      return
    }

    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

    Task {
      do {
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

        let privyUser = try await PrivyManager.shared.privy.siws.login(
          message: message,
          signature: signature,
          metadata: metadata
        )

        MainThreadHelper.postSuccess(result, privyUser.serialized())
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.siwsLoginError,
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    }
  }

  /// Links a Solana wallet to the currently authenticated user using a SIWS signature.
  private func linkWithSiws(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
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
          let walletAddress = args["walletAddress"] as? String else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "message, signature, appDomain, appUri, and walletAddress are required",
          details: nil
        )
      )
      return
    }

    guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

    Task {
      do {
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

        let privyUser = try await PrivyManager.shared.privy.siws.link(
          message: message,
          signature: signature,
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

  /// Unlinks a Solana wallet from the currently authenticated user.
  private func unlinkWithSiws(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
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
        let privyUser = try await PrivyManager.shared.privy.siws.unlink(address: address)

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

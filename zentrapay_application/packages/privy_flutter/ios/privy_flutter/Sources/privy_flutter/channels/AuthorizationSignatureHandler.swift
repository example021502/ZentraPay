import Flutter
import PrivySDK

/// Handles authorization signature generation for the Privy SDK.
class AuthorizationSignatureHandler: MethodHandler {
  private let methodChannel: FlutterMethodChannel

  private let generateAuthorizationSignatureMethod = "generateAuthorizationSignature"
  private let generateAuthorizationSignatureFromBytesMethod = "generateAuthorizationSignatureFromBytes"

  var supportedMethods: Set<String> {
    [generateAuthorizationSignatureMethod, generateAuthorizationSignatureFromBytesMethod]
  }

  init(methodChannel: FlutterMethodChannel) {
    self.methodChannel = methodChannel
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case generateAuthorizationSignatureMethod:
      generateAuthorizationSignature(call, result: result)
    case generateAuthorizationSignatureFromBytesMethod:
      generateAuthorizationSignatureFromBytes(call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func generateAuthorizationSignature(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let version = args["version"] as? Int,
      let url = args["url"] as? String,
      let method = args["method"] as? String,
      let headers = args["headers"] as? [String: String],
      let bodyString = args["body"] as? String
    else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Missing or invalid parameters for authorization signature.",
          details: nil))
      return
    }

    // Parse the JSON body string into a dictionary
    guard let bodyData = bodyString.data(using: .utf8),
      let body = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
    else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Invalid body JSON string.",
          details: nil))
      return
    }

    Task {
      guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

      do {
        let payload = WalletApiPayload(
          version: version,
          url: url,
          method: method,
          headers: headers,
          body: AnyCodable(value: body)
        )

        let signature = try await user.generateAuthorizationSignature(payload: payload)

        MainThreadHelper.postSuccess(result, signature)
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.generateAuthorizationSignatureError,
            message: "Failed to sign message: \(error.localizedDescription)",
            details: nil))
      }
    }
  }

  private func generateAuthorizationSignatureFromBytes(
    _ call: FlutterMethodCall, result: @escaping FlutterResult
  ) {
    guard let byteArray = call.arguments as? [UInt8] else {
      MainThreadHelper.postError(
        result,
        FlutterError(
          code: ErrorConstants.invalidArgument,
          message: "Missing or invalid payload for binary authorization signature.",
          details: nil))
      return
    }
    let payloadData = Data(byteArray)

    Task {
      guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

      do {
        let signature = try await user.generateAuthorizationSignature(payload: payloadData)

        MainThreadHelper.postSuccess(result, signature)
      } catch {
        MainThreadHelper.postError(
          result,
          FlutterError(
            code: ErrorConstants.generateAuthorizationSignatureError,
            message: "Failed to sign binary payload: \(error.localizedDescription)",
            details: nil))
      }
    }
  }
}

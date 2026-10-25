import Flutter
import PrivySDK

/// Handles OAuth authentication in the Privy SDK for Flutter.
class OAuthHandler: MethodHandler {
    private let methodChannel: FlutterMethodChannel

    /// Private method constants
    private let oauthLogin = "oauthLogin"
    private let oauthLink = "oauthLink"
    private let oauthUnlink = "oauthUnlink"

    /// Define supported methods directly
    var supportedMethods: Set<String> {
        [oauthLogin, oauthLink, oauthUnlink]
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
        case oauthLogin:
            login(call, result: result)
        case oauthLink:
            link(call, result: result)
        case oauthUnlink:
            unlink(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Initiates the OAuth login flow with a specified provider.
    /// - Parameters:
    ///   - call: The Flutter method call containing the arguments.
    ///   - result: The callback to send a response back to Flutter.
    private func login(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let providerString = args["provider"] as? String,
              let provider = mapToOAuthProvider(providerString) else {
            MainThreadHelper.postError(
                result,
                FlutterError(
                    code: ErrorConstants.invalidArgument,
                    message: "Valid OAuth provider is required",
                    details: nil
                )
            )
            return
        }

        let appUrlScheme = args["appUrlScheme"] as? String

        guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

        Task {
            do {
                let privyUser = try await PrivyManager.shared.privy.oAuth.login(with: provider, appUrlScheme: appUrlScheme)
                let serializedUser = privyUser.serialized()
                MainThreadHelper.postSuccess(result, serializedUser)
            } catch {
                MainThreadHelper.postError(
                    result,
                    FlutterError(
                        code: ErrorConstants.loginError,
                        message: error.localizedDescription,
                        details: nil
                    )
                )
            }
        }
    }

    /// Links an OAuth provider to the currently authenticated user.
    /// - Parameters:
    ///   - call: The Flutter method call containing the arguments.
    ///   - result: The callback to send a response back to Flutter.
    private func link(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let providerString = args["provider"] as? String,
              let provider = mapToOAuthProvider(providerString) else {
            MainThreadHelper.postError(
                result,
                FlutterError(
                    code: ErrorConstants.invalidArgument,
                    message: "Valid OAuth provider is required",
                    details: nil
                )
            )
            return
        }

        let appUrlScheme = args["appUrlScheme"] as? String

        guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

        Task {
            do {
                let privyUser = try await PrivyManager.shared.privy.oAuth.link(with: provider, appUrlScheme: appUrlScheme)
                let serializedUser = privyUser.serialized()
                MainThreadHelper.postSuccess(result, serializedUser)
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

    /// Unlinks an OAuth provider from the currently authenticated user.
    /// - Parameters:
    ///   - call: The Flutter method call containing the arguments.
    ///   - result: The callback to send a response back to Flutter.
    private func unlink(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let providerString = args["provider"] as? String,
              let provider = mapToOAuthProvider(providerString),
              let subject = args["subject"] as? String else {
            MainThreadHelper.postError(
                result,
                FlutterError(
                    code: ErrorConstants.invalidArgument,
                    message: "Valid OAuth provider and subject are required",
                    details: nil
                )
            )
            return
        }

        guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

        Task {
            do {
                let privyUser = try await PrivyManager.shared.privy.oAuth.unlink(with: provider, subject: subject)
                let serializedUser = privyUser.serialized()
                MainThreadHelper.postSuccess(result, serializedUser)
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

    /// Maps a string provider name to the native OAuthProvider enum.
    /// - Parameter providerString: The string identifier of the provider.
    /// - Returns: The corresponding OAuthProvider enum value, or nil if no match.
    private func mapToOAuthProvider(_ providerString: String) -> OAuthProvider? {
        switch providerString.lowercased() {
        case "google":
            return .google
        case "twitter":
            return .twitter
        case "discord":
            return .discord
        case "apple":
            return .apple
        case "telegram":
            return .telegram
        default:
            return nil
        }
    }
}

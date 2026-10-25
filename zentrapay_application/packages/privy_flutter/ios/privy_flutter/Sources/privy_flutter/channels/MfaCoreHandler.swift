import Flutter
import PrivySDK

/// Handles MFA configuration and blocked action resumption for Flutter.
class MfaCoreHandler: MethodHandler {
    private let methodChannel: FlutterMethodChannel

    /// Private method constants
    private let mfaSetConfig = "mfaSetConfig"
    private let mfaResumeBlockedActions = "mfaResumeBlockedActions"

    /// Define supported methods directly
    var supportedMethods: Set<String> {
        [mfaSetConfig, mfaResumeBlockedActions]
    }

    /// Initializes the handler with the Flutter MethodChannel.
    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
    }

    /// Handles incoming method calls from Flutter.
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case mfaSetConfig:
            setConfig(call, result: result)
        case mfaResumeBlockedActions:
            resumeBlockedActions(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Configures MFA with a delegate and optional timeout.
    private func setConfig(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

        let args = call.arguments as? [String: Any]
        let timeoutMs = args?["timeoutMs"] as? Int

        let config: PrivyMFAConfig
        if let timeoutMs = timeoutMs {
            config = PrivyMFAConfig(
                delegate: FlutterMfaDelegate(methodChannel: methodChannel),
                mfaTimeout: .milliseconds(timeoutMs)
            )
        } else {
            config = PrivyMFAConfig(
                delegate: FlutterMfaDelegate(methodChannel: methodChannel)
            )
        }

        PrivyManager.shared.privy.mfa.setConfig(config)

        MainThreadHelper.postSuccess(result, nil)
    }

    /// Resumes blocked MFA actions, optionally throwing an error to cancel.
    private func resumeBlockedActions(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

        let args = call.arguments as? [String: Any]
        let errorMessage = args?["error"] as? String

        Task {
            if let errorMessage = errorMessage {
                await PrivyManager.shared.privy.mfa.resumeBlockedActions(
                    throwing: MfaError.cancelled(errorMessage)
                )
            } else {
                await PrivyManager.shared.privy.mfa.resumeBlockedActions()
            }
            MainThreadHelper.postSuccess(result, nil)
        }
    }
}

/// MFA delegate that forwards onMfaRequired calls back to Flutter via method channel.
private class FlutterMfaDelegate: PrivyMfaPromptDelegate {
    private let methodChannel: FlutterMethodChannel

    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
    }

    @MainActor
    func onMfaRequired(for user: any PrivyUser) {
        methodChannel.invokeMethod("onMfaRequired", arguments: user.serialized())
    }
}

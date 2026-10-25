import Flutter
import PrivySDK

/// Handles Passkey MFA enrollment, verification, and unenrollment for Flutter.
class MfaPasskeyHandler: MethodHandler {
    private let methodChannel: FlutterMethodChannel

    /// Private method constants
    private let mfaPasskeyEnroll = "mfaPasskeyEnroll"
    private let mfaPasskeyVerify = "mfaPasskeyVerify"
    private let mfaPasskeyUnenroll = "mfaPasskeyUnenroll"

    /// Define supported methods directly
    var supportedMethods: Set<String> {
        [mfaPasskeyEnroll, mfaPasskeyVerify, mfaPasskeyUnenroll]
    }

    /// Initializes the handler with the Flutter MethodChannel.
    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
    }

    /// Handles incoming method calls from Flutter.
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case mfaPasskeyEnroll:
            enroll(call, result: result)
        case mfaPasskeyVerify:
            verify(call, result: result)
        case mfaPasskeyUnenroll:
            unenroll(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Enrolls passkey credentials for MFA.
    private func enroll(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let credentialIds = args["credentialIds"] as? [String] else {
            MainThreadHelper.postError(result, FlutterError(
                code: ErrorConstants.invalidArgument,
                message: "credentialIds is required",
                details: nil
            ))
            return
        }

        guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

        Task {
            guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

            do {
                let updatedUser = try await user.mfa.passkeys.enroll.submit(credentialIds: credentialIds)
                MainThreadHelper.postSuccess(result, updatedUser.serialized())
            } catch {
                MainThreadHelper.postError(result, mfaFlutterError(from: error, fallbackCode: ErrorConstants.mfaPasskeyError))
            }
        }
    }

    /// Verifies passkey for MFA.
    private func verify(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let relyingParty = args["relyingParty"] as? String else {
            MainThreadHelper.postError(result, FlutterError(
                code: ErrorConstants.invalidArgument,
                message: "relyingParty is required",
                details: nil
            ))
            return
        }

        guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

        Task {
            guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

            do {
                try await user.mfa.passkeys.verify.submit(relyingParty: relyingParty)
                MainThreadHelper.postSuccess(result, true)
            } catch {
                MainThreadHelper.postError(result, mfaFlutterError(from: error, fallbackCode: ErrorConstants.mfaPasskeyError))
            }
        }
    }

    /// Unenrolls the user from Passkey MFA.
    private func unenroll(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let removeForLogin: Bool
        if let args = call.arguments as? [String: Any],
           let value = args["removeForLogin"] as? Bool {
            removeForLogin = value
        } else {
            removeForLogin = true
        }

        guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

        Task {
            guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

            do {
                let updatedUser = try await user.mfa.passkeys.unenroll(removeForLogin: removeForLogin)
                MainThreadHelper.postSuccess(result, updatedUser.serialized())
            } catch {
                MainThreadHelper.postError(result, mfaFlutterError(from: error, fallbackCode: ErrorConstants.mfaPasskeyError))
            }
        }
    }
}

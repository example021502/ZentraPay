import Flutter
import PrivySDK

/// Handles TOTP MFA enrollment, verification, and unenrollment for Flutter.
class MfaTotpHandler: MethodHandler {
    private let methodChannel: FlutterMethodChannel

    /// Private method constants
    private let mfaTotpGenerateSecret = "mfaTotpGenerateSecret"
    private let mfaTotpEnroll = "mfaTotpEnroll"
    private let mfaTotpVerify = "mfaTotpVerify"
    private let mfaTotpUnenroll = "mfaTotpUnenroll"

    /// Define supported methods directly
    var supportedMethods: Set<String> {
        [mfaTotpGenerateSecret, mfaTotpEnroll, mfaTotpVerify, mfaTotpUnenroll]
    }

    /// Initializes the handler with the Flutter MethodChannel.
    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
    }

    /// Handles incoming method calls from Flutter.
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case mfaTotpGenerateSecret:
            generateSecret(result: result)
        case mfaTotpEnroll:
            enroll(call, result: result)
        case mfaTotpVerify:
            verify(call, result: result)
        case mfaTotpUnenroll:
            unenroll(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Generates a TOTP secret for enrollment.
    private func generateSecret(result: @escaping FlutterResult) {
        guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

        Task {
            guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

            do {
                let totpSecret = try await user.mfa.totp.enroll.generateSecret()
                MainThreadHelper.postSuccess(result, [
                    "secret": totpSecret.secret,
                    "authUrl": totpSecret.authUrl
                ])
            } catch {
                MainThreadHelper.postError(result, mfaFlutterError(from: error, fallbackCode: ErrorConstants.mfaTotpError))
            }
        }
    }

    /// Completes TOTP MFA enrollment with a code from the authenticator app.
    private func enroll(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let code = args["code"] as? String else {
            MainThreadHelper.postError(result, FlutterError(
                code: ErrorConstants.invalidArgument,
                message: "Code is required",
                details: nil
            ))
            return
        }

        guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

        Task {
            guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

            do {
                let updatedUser = try await user.mfa.totp.enroll.submit(code: code)
                MainThreadHelper.postSuccess(result, updatedUser.serialized())
            } catch {
                MainThreadHelper.postError(result, mfaFlutterError(from: error, fallbackCode: ErrorConstants.mfaTotpError))
            }
        }
    }

    /// Verifies a TOTP code for MFA.
    private func verify(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let code = args["code"] as? String else {
            MainThreadHelper.postError(result, FlutterError(
                code: ErrorConstants.invalidArgument,
                message: "Code is required",
                details: nil
            ))
            return
        }

        guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

        Task {
            guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

            do {
                try await user.mfa.totp.verify.submit(code: code)
                MainThreadHelper.postSuccess(result, true)
            } catch {
                MainThreadHelper.postError(result, mfaFlutterError(from: error, fallbackCode: ErrorConstants.mfaTotpError))
            }
        }
    }

    /// Unenrolls the user from TOTP MFA.
    private func unenroll(result: @escaping FlutterResult) {
        guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

        Task {
            guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

            do {
                let updatedUser = try await user.mfa.totp.unenroll()
                MainThreadHelper.postSuccess(result, updatedUser.serialized())
            } catch {
                MainThreadHelper.postError(result, mfaFlutterError(from: error, fallbackCode: ErrorConstants.mfaTotpError))
            }
        }
    }
}

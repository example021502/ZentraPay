import Flutter
import PrivySDK

/// Handles SMS MFA enrollment, verification, and unenrollment for Flutter.
class MfaSmsHandler: MethodHandler {
    private let methodChannel: FlutterMethodChannel

    /// Private method constants
    private let mfaSmsSendCodeEnroll = "mfaSmsSendCodeEnroll"
    private let mfaSmsEnroll = "mfaSmsEnroll"
    private let mfaSmsSendCodeVerify = "mfaSmsSendCodeVerify"
    private let mfaSmsVerify = "mfaSmsVerify"
    private let mfaSmsUnenroll = "mfaSmsUnenroll"

    /// Define supported methods directly
    var supportedMethods: Set<String> {
        [mfaSmsSendCodeEnroll, mfaSmsEnroll, mfaSmsSendCodeVerify, mfaSmsVerify, mfaSmsUnenroll]
    }

    /// Initializes the handler with the Flutter MethodChannel.
    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
    }

    /// Handles incoming method calls from Flutter.
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case mfaSmsSendCodeEnroll:
            sendCodeEnroll(call, result: result)
        case mfaSmsEnroll:
            enroll(call, result: result)
        case mfaSmsSendCodeVerify:
            sendCodeVerify(result: result)
        case mfaSmsVerify:
            verify(call, result: result)
        case mfaSmsUnenroll:
            unenroll(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Sends an SMS code for MFA enrollment to the specified phone number.
    private func sendCodeEnroll(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let phoneNumber = args["phoneNumber"] as? String else {
            MainThreadHelper.postError(result, FlutterError(
                code: ErrorConstants.invalidArgument,
                message: "Phone number is required",
                details: nil
            ))
            return
        }

        guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

        Task {
            guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

            do {
                try await user.mfa.sms.enroll.sendCode(to: phoneNumber)
                MainThreadHelper.postSuccess(result, true)
            } catch {
                MainThreadHelper.postError(result, mfaFlutterError(from: error, fallbackCode: ErrorConstants.mfaSmsError))
            }
        }
    }

    /// Completes SMS MFA enrollment with the code and phone number.
    private func enroll(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let code = args["code"] as? String,
              let phoneNumber = args["phoneNumber"] as? String else {
            MainThreadHelper.postError(result, FlutterError(
                code: ErrorConstants.invalidArgument,
                message: "Code and phone number are required",
                details: nil
            ))
            return
        }

        guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

        Task {
            guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

            do {
                let updatedUser = try await user.mfa.sms.enroll.submit(code: code, sentTo: phoneNumber)
                MainThreadHelper.postSuccess(result, updatedUser.serialized())
            } catch {
                MainThreadHelper.postError(result, mfaFlutterError(from: error, fallbackCode: ErrorConstants.mfaSmsError))
            }
        }
    }

    /// Sends an SMS code for MFA verification to the already-enrolled number.
    private func sendCodeVerify(result: @escaping FlutterResult) {
        guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

        Task {
            guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

            do {
                try await user.mfa.sms.verify.sendCode()
                MainThreadHelper.postSuccess(result, true)
            } catch {
                MainThreadHelper.postError(result, mfaFlutterError(from: error, fallbackCode: ErrorConstants.mfaSmsError))
            }
        }
    }

    /// Verifies the SMS code for MFA.
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
                try await user.mfa.sms.verify.submit(code: code)
                MainThreadHelper.postSuccess(result, true)
            } catch {
                MainThreadHelper.postError(result, mfaFlutterError(from: error, fallbackCode: ErrorConstants.mfaSmsError))
            }
        }
    }

    /// Unenrolls the user from SMS MFA.
    private func unenroll(result: @escaping FlutterResult) {
        guard PrivyHelpers.ensureInitializedOrPostError(result) else { return }

        Task {
            guard let user = await PrivyHelpers.getUserOrPostError(result) else { return }

            do {
                let updatedUser = try await user.mfa.sms.unenroll()
                MainThreadHelper.postSuccess(result, updatedUser.serialized())
            } catch {
                MainThreadHelper.postError(result, mfaFlutterError(from: error, fallbackCode: ErrorConstants.mfaSmsError))
            }
        }
    }
}

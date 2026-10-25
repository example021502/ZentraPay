package io.privy.privyflutter.channel

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.privy.privyflutter.PrivyManager
import io.privy.privyflutter.constants.ErrorConstants.INVALID_ARGUMENT
import io.privy.privyflutter.constants.ErrorConstants.MFA_SMS_ERROR
import io.privy.privyflutter.constants.ErrorConstants.USER_NOT_AUTHENTICATED
import io.privy.privyflutter.helpers.MethodHandler
import io.privy.privyflutter.helpers.mfaErrorCode
import io.privy.privyflutter.helpers.postError
import io.privy.privyflutter.helpers.postSuccess
import io.privy.privyflutter.helpers.serializeUser
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * Handles SMS MFA enrollment, verification, and unenrollment for Flutter.
 */
class MfaSmsHandler(private val coroutineScope: CoroutineScope) : MethodHandler(
    setOf(
        MFA_SMS_SEND_CODE_ENROLL,
        MFA_SMS_ENROLL,
        MFA_SMS_SEND_CODE_VERIFY,
        MFA_SMS_VERIFY,
        MFA_SMS_UNENROLL,
    ),
) {

    private companion object {
        private const val MFA_SMS_SEND_CODE_ENROLL = "mfaSmsSendCodeEnroll"
        private const val MFA_SMS_ENROLL = "mfaSmsEnroll"
        private const val MFA_SMS_SEND_CODE_VERIFY = "mfaSmsSendCodeVerify"
        private const val MFA_SMS_VERIFY = "mfaSmsVerify"
        private const val MFA_SMS_UNENROLL = "mfaSmsUnenroll"
    }

    /**
     * Handles method calls received from Flutter.
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            MFA_SMS_SEND_CODE_ENROLL -> handleSendCodeEnroll(call, result)
            MFA_SMS_ENROLL -> handleEnroll(call, result)
            MFA_SMS_SEND_CODE_VERIFY -> handleSendCodeVerify(result)
            MFA_SMS_VERIFY -> handleVerify(call, result)
            MFA_SMS_UNENROLL -> handleUnenroll(result)
            else -> result.notImplemented()
        }
    }

    /**
     * Sends an SMS code for MFA enrollment to the specified phone number.
     */
    private fun handleSendCodeEnroll(call: MethodCall, result: MethodChannel.Result) {
        val phoneNumber: String? = call.argument("phoneNumber")
        if (phoneNumber.isNullOrEmpty()) {
            result.error(INVALID_ARGUMENT, "Phone number is required", null)
            return
        }

        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user
                    ?: return@launch result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)
                val sendResult = user.mfa.sms.enroll.sendCode(phoneNumber)

                sendResult.fold(
                    onSuccess = {
                        result.postSuccess(true)
                    },
                    onFailure = { error ->
                        result.postError(mfaErrorCode(error) ?: MFA_SMS_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(mfaErrorCode(e) ?: MFA_SMS_ERROR, e.message, null)
            }
        }
    }

    /**
     * Completes SMS MFA enrollment with the code and phone number.
     */
    private fun handleEnroll(call: MethodCall, result: MethodChannel.Result) {
        val code: String? = call.argument("code")
        val phoneNumber: String? = call.argument("phoneNumber")
        if (code.isNullOrEmpty() || phoneNumber.isNullOrEmpty()) {
            result.error(INVALID_ARGUMENT, "Code and phone number are required", null)
            return
        }

        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user
                    ?: return@launch result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)
                val enrollResult = user.mfa.sms.enroll.submit(code, phoneNumber)

                enrollResult.fold(
                    onSuccess = { updatedUser ->
                        result.postSuccess(serializeUser(updatedUser))
                    },
                    onFailure = { error ->
                        result.postError(mfaErrorCode(error) ?: MFA_SMS_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(mfaErrorCode(e) ?: MFA_SMS_ERROR, e.message, null)
            }
        }
    }

    /**
     * Sends an SMS code for MFA verification to the already-enrolled number.
     */
    private fun handleSendCodeVerify(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user
                    ?: return@launch result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)
                val sendResult = user.mfa.sms.verify.sendCode()

                sendResult.fold(
                    onSuccess = {
                        result.postSuccess(true)
                    },
                    onFailure = { error ->
                        result.postError(mfaErrorCode(error) ?: MFA_SMS_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(mfaErrorCode(e) ?: MFA_SMS_ERROR, e.message, null)
            }
        }
    }

    /**
     * Verifies the SMS code for MFA.
     */
    private fun handleVerify(call: MethodCall, result: MethodChannel.Result) {
        val code: String? = call.argument("code")
        if (code.isNullOrEmpty()) {
            result.error(INVALID_ARGUMENT, "Code is required", null)
            return
        }

        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user
                    ?: return@launch result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)
                val verifyResult = user.mfa.sms.verify.submit(code)

                verifyResult.fold(
                    onSuccess = {
                        result.postSuccess(true)
                    },
                    onFailure = { error ->
                        result.postError(mfaErrorCode(error) ?: MFA_SMS_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(mfaErrorCode(e) ?: MFA_SMS_ERROR, e.message, null)
            }
        }
    }

    /**
     * Unenrolls the user from SMS MFA.
     */
    private fun handleUnenroll(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user
                    ?: return@launch result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)
                val unenrollResult = user.mfa.sms.unenroll()

                unenrollResult.fold(
                    onSuccess = { updatedUser ->
                        result.postSuccess(serializeUser(updatedUser))
                    },
                    onFailure = { error ->
                        result.postError(mfaErrorCode(error) ?: MFA_SMS_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(mfaErrorCode(e) ?: MFA_SMS_ERROR, e.message, null)
            }
        }
    }
}

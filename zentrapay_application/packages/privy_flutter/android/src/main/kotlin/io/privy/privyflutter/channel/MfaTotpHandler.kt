package io.privy.privyflutter.channel

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.privy.privyflutter.PrivyManager
import io.privy.privyflutter.constants.ErrorConstants.INVALID_ARGUMENT
import io.privy.privyflutter.constants.ErrorConstants.MFA_TOTP_ERROR
import io.privy.privyflutter.constants.ErrorConstants.USER_NOT_AUTHENTICATED
import io.privy.privyflutter.helpers.MethodHandler
import io.privy.privyflutter.helpers.mfaErrorCode
import io.privy.privyflutter.helpers.postError
import io.privy.privyflutter.helpers.postSuccess
import io.privy.privyflutter.helpers.serializeUser
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * Handles TOTP MFA enrollment, verification, and unenrollment for Flutter.
 */
class MfaTotpHandler(private val coroutineScope: CoroutineScope) : MethodHandler(
    setOf(
        MFA_TOTP_GENERATE_SECRET,
        MFA_TOTP_ENROLL,
        MFA_TOTP_VERIFY,
        MFA_TOTP_UNENROLL,
    ),
) {

    private companion object {
        private const val MFA_TOTP_GENERATE_SECRET = "mfaTotpGenerateSecret"
        private const val MFA_TOTP_ENROLL = "mfaTotpEnroll"
        private const val MFA_TOTP_VERIFY = "mfaTotpVerify"
        private const val MFA_TOTP_UNENROLL = "mfaTotpUnenroll"
    }

    /**
     * Handles method calls received from Flutter.
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            MFA_TOTP_GENERATE_SECRET -> handleGenerateSecret(result)
            MFA_TOTP_ENROLL -> handleEnroll(call, result)
            MFA_TOTP_VERIFY -> handleVerify(call, result)
            MFA_TOTP_UNENROLL -> handleUnenroll(result)
            else -> result.notImplemented()
        }
    }

    /**
     * Generates a TOTP secret for enrollment.
     */
    private fun handleGenerateSecret(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user
                    ?: return@launch result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)
                val generateResult = user.mfa.totp.enroll.generateSecret()

                generateResult.fold(
                    onSuccess = { totpSecret ->
                        result.postSuccess(
                            mapOf(
                                "secret" to totpSecret.secret,
                                "authUrl" to totpSecret.authUrl,
                            ),
                        )
                    },
                    onFailure = { error ->
                        result.postError(mfaErrorCode(error) ?: MFA_TOTP_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(mfaErrorCode(e) ?: MFA_TOTP_ERROR, e.message, null)
            }
        }
    }

    /**
     * Completes TOTP MFA enrollment with a code from the authenticator app.
     */
    private fun handleEnroll(call: MethodCall, result: MethodChannel.Result) {
        val code: String? = call.argument("code")
        if (code.isNullOrEmpty()) {
            result.error(INVALID_ARGUMENT, "Code is required", null)
            return
        }

        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user
                    ?: return@launch result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)
                val enrollResult = user.mfa.totp.enroll.submit(code)

                enrollResult.fold(
                    onSuccess = { updatedUser ->
                        result.postSuccess(serializeUser(updatedUser))
                    },
                    onFailure = { error ->
                        result.postError(mfaErrorCode(error) ?: MFA_TOTP_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(mfaErrorCode(e) ?: MFA_TOTP_ERROR, e.message, null)
            }
        }
    }

    /**
     * Verifies a TOTP code for MFA.
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
                val verifyResult = user.mfa.totp.verify.submit(code)

                verifyResult.fold(
                    onSuccess = {
                        result.postSuccess(true)
                    },
                    onFailure = { error ->
                        result.postError(mfaErrorCode(error) ?: MFA_TOTP_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(mfaErrorCode(e) ?: MFA_TOTP_ERROR, e.message, null)
            }
        }
    }

    /**
     * Unenrolls the user from TOTP MFA.
     */
    private fun handleUnenroll(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user
                    ?: return@launch result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)
                val unenrollResult = user.mfa.totp.unenroll()

                unenrollResult.fold(
                    onSuccess = { updatedUser ->
                        result.postSuccess(serializeUser(updatedUser))
                    },
                    onFailure = { error ->
                        result.postError(mfaErrorCode(error) ?: MFA_TOTP_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(mfaErrorCode(e) ?: MFA_TOTP_ERROR, e.message, null)
            }
        }
    }
}

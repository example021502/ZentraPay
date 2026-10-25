package io.privy.privyflutter.channel

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.privy.privyflutter.PrivyManager
import io.privy.privyflutter.constants.ErrorConstants.INVALID_ARGUMENT
import io.privy.privyflutter.constants.ErrorConstants.MFA_PASSKEY_ERROR
import io.privy.privyflutter.constants.ErrorConstants.USER_NOT_AUTHENTICATED
import io.privy.privyflutter.helpers.MethodHandler
import io.privy.privyflutter.helpers.mfaErrorCode
import io.privy.privyflutter.helpers.postError
import io.privy.privyflutter.helpers.postSuccess
import io.privy.privyflutter.helpers.serializeUser
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * Handles Passkey MFA enrollment, verification, and unenrollment for Flutter.
 */
class MfaPasskeyHandler(private val coroutineScope: CoroutineScope) : MethodHandler(
    setOf(
        MFA_PASSKEY_ENROLL,
        MFA_PASSKEY_VERIFY,
        MFA_PASSKEY_UNENROLL,
    ),
) {

    private companion object {
        private const val MFA_PASSKEY_ENROLL = "mfaPasskeyEnroll"
        private const val MFA_PASSKEY_VERIFY = "mfaPasskeyVerify"
        private const val MFA_PASSKEY_UNENROLL = "mfaPasskeyUnenroll"
    }

    /**
     * Handles method calls received from Flutter.
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            MFA_PASSKEY_ENROLL -> handleEnroll(call, result)
            MFA_PASSKEY_VERIFY -> handleVerify(call, result)
            MFA_PASSKEY_UNENROLL -> handleUnenroll(call, result)
            else -> result.notImplemented()
        }
    }

    /**
     * Enrolls passkey credentials for MFA.
     */
    private fun handleEnroll(call: MethodCall, result: MethodChannel.Result) {
        val credentialIds: List<String>? = call.argument("credentialIds")
        if (credentialIds.isNullOrEmpty()) {
            result.error(INVALID_ARGUMENT, "credentialIds is required", null)
            return
        }

        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user
                    ?: return@launch result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)
                val enrollResult = user.mfa.passkeys.enroll.submit(credentialIds)

                enrollResult.fold(
                    onSuccess = { updatedUser ->
                        result.postSuccess(serializeUser(updatedUser))
                    },
                    onFailure = { error ->
                        result.postError(mfaErrorCode(error) ?: MFA_PASSKEY_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(mfaErrorCode(e) ?: MFA_PASSKEY_ERROR, e.message, null)
            }
        }
    }

    /**
     * Verifies passkey for MFA.
     */
    private fun handleVerify(call: MethodCall, result: MethodChannel.Result) {
        val relyingParty: String? = call.argument("relyingParty")
        if (relyingParty.isNullOrEmpty()) {
            result.error(INVALID_ARGUMENT, "relyingParty is required", null)
            return
        }

        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user
                    ?: return@launch result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)
                val verifyResult = user.mfa.passkeys.verify.submit(relyingParty)

                verifyResult.fold(
                    onSuccess = {
                        result.postSuccess(true)
                    },
                    onFailure = { error ->
                        result.postError(mfaErrorCode(error) ?: MFA_PASSKEY_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(mfaErrorCode(e) ?: MFA_PASSKEY_ERROR, e.message, null)
            }
        }
    }

    /**
     * Unenrolls the user from Passkey MFA.
     */
    private fun handleUnenroll(call: MethodCall, result: MethodChannel.Result) {
        val removeForLogin = call.argument<Boolean>("removeForLogin") ?: true

        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user
                    ?: return@launch result.postError(USER_NOT_AUTHENTICATED, "User is not authenticated.", null)
                val unenrollResult = user.mfa.passkeys.unenroll(removeForLogin)

                unenrollResult.fold(
                    onSuccess = { updatedUser ->
                        result.postSuccess(serializeUser(updatedUser))
                    },
                    onFailure = { error ->
                        result.postError(mfaErrorCode(error) ?: MFA_PASSKEY_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(mfaErrorCode(e) ?: MFA_PASSKEY_ERROR, e.message, null)
            }
        }
    }
}

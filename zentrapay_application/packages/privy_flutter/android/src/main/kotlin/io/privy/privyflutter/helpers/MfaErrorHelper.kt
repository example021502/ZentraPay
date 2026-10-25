package io.privy.privyflutter.helpers

import io.privy.auth.AuthenticationException
import io.privy.auth.mfa.MfaRequiredOrInvalidException
import io.privy.network.PrivyApiException
import io.privy.privyflutter.constants.ErrorConstants.MFA_CHALLENGE_EXPIRED
import io.privy.privyflutter.constants.ErrorConstants.MFA_MISSING_OR_INVALID
import io.privy.privyflutter.constants.ErrorConstants.MFA_SDK_TIMEOUT

/**
 * Maps a throwable to a typed MFA error code, or returns null if the error
 * is not a recognised MFA error (caller should fall back to its own code).
 */
fun mfaErrorCode(error: Throwable): String? {
    // Prefer structured API error code from PrivyApiException.responseBody.code over
    // message-string matching. The exception message contains the human-readable error
    // field, not the machine-readable code field.
    if (error is PrivyApiException) {
        return when (error.responseBody?.code) {
            "missing_or_invalid_mfa" -> MFA_MISSING_OR_INVALID
            "expired_or_invalid_mfa_token" -> MFA_CHALLENGE_EXPIRED
            else -> null
        }
    }
    return when {
        // withMfaHandling raises this when an operation requires MFA (not a code submission error).
        error is MfaRequiredOrInvalidException -> MFA_MISSING_OR_INVALID
        // SDK-side listener timeout from RealMfaManager.kt.
        error is AuthenticationException &&
            error.message?.contains("MFA verification timed out") == true -> MFA_SDK_TIMEOUT
        else -> null
    }
}

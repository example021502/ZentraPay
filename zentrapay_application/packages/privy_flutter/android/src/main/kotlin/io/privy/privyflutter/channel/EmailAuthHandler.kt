package io.privy.privyflutter.channel

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.privy.auth.PrivyUser
import io.privy.privyflutter.PrivyManager
import io.privy.privyflutter.constants.ErrorConstants.EMAIL_UPDATE_ERROR
import io.privy.privyflutter.constants.ErrorConstants.INVALID_ARGUMENT
import io.privy.privyflutter.constants.ErrorConstants.LOGIN_ERROR
import io.privy.privyflutter.constants.ErrorConstants.SEND_OTP_ERROR
import io.privy.privyflutter.constants.ErrorConstants.UNLINK_ERROR
import io.privy.privyflutter.helpers.MethodHandler
import io.privy.privyflutter.helpers.postError
import io.privy.privyflutter.helpers.postSuccess
import io.privy.privyflutter.helpers.serializeUser
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * Handles email authentication methods for Flutter using Privy's SDK.
 * This class listens to method calls from Flutter and processes email-based authentication.
 */
class EmailAuthHandler(private val coroutineScope: CoroutineScope) : MethodHandler(
    setOf(
        EMAIL_SEND_CODE,
        EMAIL_LOGIN_WITH_CODE,
        EMAIL_LINK_WITH_CODE,
        EMAIL_UPDATE_WITH_CODE,
        EMAIL_UNLINK,
    ),
) {

    // Define private constants directly in the class
    private companion object {
        private const val EMAIL_SEND_CODE = "emailSendCode"
        private const val EMAIL_LOGIN_WITH_CODE = "emailLoginWithCode"
        private const val EMAIL_LINK_WITH_CODE = "emailLinkWithCode"
        private const val EMAIL_UPDATE_WITH_CODE = "emailUpdateWithCode"
        private const val EMAIL_UNLINK = "emailUnlink"
        private const val LINK_ERROR = "LINK_ERROR"
    }

    /**
     * Handles method calls received from Flutter.
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            EMAIL_SEND_CODE -> {
                val email: String? = call.argument("email")
                if (email.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "Email is required", null)
                    return
                }
                handleSendOtp(email, result)
            }

            EMAIL_LOGIN_WITH_CODE -> {
                val email: String? = call.argument("email")
                val code: String? = call.argument("code")
                if (code.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "OTP code is required", null)
                    return
                }
                handleLoginWithCode(email, code, result)
            }
            
            EMAIL_LINK_WITH_CODE -> {
                val email: String? = call.argument("email")
                val code: String? = call.argument("code")
                if (code.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "OTP code is required", null)
                    return
                }
                handleLinkWithCode(email, code, result)
            }

            EMAIL_UPDATE_WITH_CODE -> {
                val email: String? = call.argument("email")
                val code: String? = call.argument("code")
                if (code.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "OTP code is required", null)
                    return
                }
                if (email.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "Email is required", null)
                    return
                }
                handleUpdateWithCode(email, code, result)
            }

            EMAIL_UNLINK -> {
                val email: String? = call.argument("email")
                if (email.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "Email is required", null)
                    return
                }
                handleUnlink(email, result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Handles sending OTP to the provided email asynchronously using coroutines and Result handling.
     */
    private fun handleSendOtp(email: String, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val sendCodeResult: Result<Unit> = PrivyManager.privy.email.sendCode(email)

                sendCodeResult.fold(
                    onSuccess = {
                        result.postSuccess(true) // OTP successfully sent
                    },
                    onFailure = { error ->
                        result.postError(
                            SEND_OTP_ERROR,
                            error.message,
                            null,
                        ) // Send error with exception
                    },
                )
            } catch (e: Exception) {
                result.postError(
                    SEND_OTP_ERROR,
                    e.message,
                    null,
                ) // Preserve the exception details
            }
        }
    }

    /**
     * Handles login using the OTP code and returns the PrivyUser object to Flutter.
     */
    private fun handleLoginWithCode(email: String?, code: String, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val loginResult: Result<PrivyUser> =
                    PrivyManager.privy.email.loginWithCode(code, email)

                loginResult.fold(
                    onSuccess = { user ->
                        val serializedUser = serializeUser(user)

                        result.postSuccess(serializedUser)
                    },
                    onFailure = { error ->

                        result.postError(LOGIN_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(LOGIN_ERROR, e.message, null)
            }
        }
    }
    
    /**
     * Handles linking an email account to the existing authenticated user using an OTP code.
     * Returns the updated PrivyUser on success.
     */
    private fun handleLinkWithCode(email: String?, code: String, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val linkResult: Result<PrivyUser> =
                    PrivyManager.privy.email.linkWithCode(code, email)

                linkResult.fold(
                    onSuccess = { user ->
                        val serializedUser = serializeUser(user)
                        result.postSuccess(serializedUser)
                    },
                    onFailure = { error ->
                        result.postError(LINK_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(LINK_ERROR, e.message, null)
            }
        }
    }
    
    /**
     * Handles updating an email account using an OTP code.
     */
    private fun handleUpdateWithCode(email: String, code: String, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val updateResult: Result<Unit> =
                    PrivyManager.privy.email.updateWithCode(code, email)

                updateResult.fold(
                    onSuccess = {
                        // Successfully updated the email account
                        result.postSuccess(true)
                    },
                    onFailure = { error ->
                        result.postError(EMAIL_UPDATE_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(EMAIL_UPDATE_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles unlinking an email account from the currently authenticated user.
     * Returns the updated PrivyUser on success.
     */
    private fun handleUnlink(email: String, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val unlinkResult: Result<PrivyUser> =
                    PrivyManager.privy.email.unlink(email)

                unlinkResult.fold(
                    onSuccess = { user ->
                        val serializedUser = serializeUser(user)
                        result.postSuccess(serializedUser)
                    },
                    onFailure = { error ->
                        result.postError(UNLINK_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(UNLINK_ERROR, e.message, null)
            }
        }
    }
}

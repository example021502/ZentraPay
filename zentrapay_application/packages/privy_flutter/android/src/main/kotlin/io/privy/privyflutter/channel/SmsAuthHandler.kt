package io.privy.privyflutter.channel

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.privy.auth.PrivyUser
import io.privy.privyflutter.PrivyManager
import io.privy.privyflutter.constants.ErrorConstants.INVALID_ARGUMENT
import io.privy.privyflutter.constants.ErrorConstants.INVALID_PHONE_FORMAT
import io.privy.privyflutter.constants.ErrorConstants.LOGIN_ERROR
import io.privy.privyflutter.constants.ErrorConstants.SEND_OTP_ERROR
import io.privy.privyflutter.constants.ErrorConstants.SMS_LINK_ERROR
import io.privy.privyflutter.constants.ErrorConstants.SMS_UPDATE_ERROR
import io.privy.privyflutter.constants.ErrorConstants.UNLINK_ERROR
import io.privy.privyflutter.helpers.MethodHandler
import io.privy.privyflutter.helpers.postError
import io.privy.privyflutter.helpers.postSuccess
import io.privy.privyflutter.helpers.serializeUser
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * Handles SMS authentication methods for Flutter using Privy's SDK.
 * This class listens to method calls from Flutter and processes SMS-based authentication.
 */
class SmsAuthHandler(private val coroutineScope: CoroutineScope) : MethodHandler(
    setOf(
        SMS_SEND_CODE,
        SMS_LOGIN_WITH_CODE,
        SMS_LINK_WITH_CODE,
        SMS_UPDATE_WITH_CODE,
        SMS_UNLINK,
    ),
) {

    // Define private constants
    private companion object {
        private const val SMS_SEND_CODE = "smsSendCode"
        private const val SMS_LOGIN_WITH_CODE = "smsLoginWithCode"
        private const val SMS_LINK_WITH_CODE = "smsLinkWithCode"
        private const val SMS_UPDATE_WITH_CODE = "smsUpdateWithCode"
        private const val SMS_UNLINK = "smsUnlink"
    }

    /**
     * Handles method calls from Flutter.
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            SMS_SEND_CODE -> {
                // Extract phone number argument from Flutter
                val phoneNumber: String? = call.argument("phoneNumber")

                // Validate phone number presence
                if (phoneNumber.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "Phone number is required", null)
                    return
                }

                // Validate phone number format (E.164)
                val formattedPhoneNumber = formatPhoneNumber(phoneNumber)
                if (formattedPhoneNumber == null) {
                    result.error(INVALID_PHONE_FORMAT, "Phone number must be in E.164 format", null)
                    return
                }

                // Initiate OTP sending
                handleSendOtp(formattedPhoneNumber, result)
            }

            SMS_LOGIN_WITH_CODE -> {
                val phoneNumber: String? = call.argument("phoneNumber")
                val code: String? = call.argument("code")

                // Validate OTP presence
                if (code.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "OTP code is required", null)
                    return
                }

                // Initiate login process
                handleLoginWithCode(phoneNumber, code, result)
            }

            SMS_LINK_WITH_CODE -> {
                val phoneNumber: String? = call.argument("phoneNumber")
                val code: String? = call.argument("code")

                // Validate phone number presence
                if (phoneNumber.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "Phone number is required", null)
                    return
                }

                // Validate OTP presence
                if (code.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "OTP code is required", null)
                    return
                }

                // Initiate link process
                handleLinkWithCode(phoneNumber, code, result)
            }

            SMS_UPDATE_WITH_CODE -> {
                val phoneNumber: String? = call.argument("phoneNumber")
                val code: String? = call.argument("code")

                // Validate phone number presence
                if (phoneNumber.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "Phone number is required", null)
                    return
                }

                // Validate OTP presence
                if (code.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "OTP code is required", null)
                    return
                }

                // Validate phone number format (E.164)
                val formattedPhoneNumber = formatPhoneNumber(phoneNumber)
                if (formattedPhoneNumber == null) {
                    result.error(INVALID_PHONE_FORMAT, "Phone number must be in E.164 format", null)
                    return
                }

                // Initiate update process
                handleUpdateWithCode(formattedPhoneNumber, code, result)
            }

            SMS_UNLINK -> {
                val phoneNumber: String? = call.argument("phoneNumber")

                // Validate phone number presence
                if (phoneNumber.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "Phone number is required", null)
                    return
                }

                // Initiate unlink process
                handleUnlink(phoneNumber, result)
            }

            else -> {
                // Handle unimplemented method calls
                result.notImplemented()
            }
        }
    }

    /**
     * Sends an OTP to the given phone number asynchronously.
     */
    private fun handleSendOtp(phoneNumber: String, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                // Call Privy SDK to send OTP
                val sendCodeResult: Result<Unit> = PrivyManager.privy.sms.sendCode(phoneNumber)

                sendCodeResult.fold(
                    onSuccess = {
                        result.postSuccess(true) // OTP successfully sent
                    },
                    onFailure = { error ->
                        result.postError(SEND_OTP_ERROR, error.message, null) // Return error with exception
                    },
                )
            } catch (e: Exception) {
                result.postError(SEND_OTP_ERROR, e.message, e) // Preserve exception details
            }
        }
    }

    /**
     * Handles login using the OTP code and returns the PrivyUser object to Flutter.
     */
    private fun handleLoginWithCode(phoneNumber: String?, code: String, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                // Call Privy SDK to authenticate using OTP
                val loginResult: Result<PrivyUser> = PrivyManager.privy.sms.loginWithCode(code, phoneNumber)

                loginResult.fold(
                    onSuccess = { user ->
                        // Serialized the authenticated user into a map format
                        val serializedUser = serializeUser(user)
                        // Return the user object to Flutter
                        result.postSuccess(serializedUser)
                    },
                    onFailure = { error ->
                        // Return login failure error to Flutter
                        result.postError(LOGIN_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                // Handle unexpected errors and return error to Flutter
                result.postError(LOGIN_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles linking a phone number to the existing authenticated user using an OTP code.
     * Returns the updated PrivyUser on success.
     */
    private fun handleLinkWithCode(phoneNumber: String, code: String, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val linkResult: Result<PrivyUser> =
                    PrivyManager.privy.sms.linkWithCode(code, phoneNumber)

                linkResult.fold(
                    onSuccess = { user ->
                        val serializedUser = serializeUser(user)
                        result.postSuccess(serializedUser)
                    },
                    onFailure = { error ->
                        result.postError(SMS_LINK_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(SMS_LINK_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles updating a phone number using an OTP code.
     */
    private fun handleUpdateWithCode(phoneNumber: String, code: String, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val updateResult: Result<Unit> =
                    PrivyManager.privy.sms.updateWithCode(code, phoneNumber)

                updateResult.fold(
                    onSuccess = {
                        // Successfully updated the phone number
                        result.postSuccess(true)
                    },
                    onFailure = { error ->
                        result.postError(SMS_UPDATE_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(SMS_UPDATE_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles unlinking a phone number from the currently authenticated user.
     * Returns the updated PrivyUser on success.
     */
    private fun handleUnlink(phoneNumber: String, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val unlinkResult: Result<PrivyUser> =
                    PrivyManager.privy.sms.unlink(phoneNumber)

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

    /**
     * Validates and ensures the phone number follows E.164 format.
     * E.164 format requires: "+[country code][subscriber number]" (10-15 digits).
     *
     * @param phoneNumber The raw phone number provided by the user.
     * @return The formatted phone number if valid, otherwise null.
     */
    private fun formatPhoneNumber(phoneNumber: String): String? {
        val regex = Regex("^\\+\\d{10,15}\$") // Matches E.164 format
        return if (regex.matches(phoneNumber)) {
            phoneNumber
        } else {
            null
        }
    }
}

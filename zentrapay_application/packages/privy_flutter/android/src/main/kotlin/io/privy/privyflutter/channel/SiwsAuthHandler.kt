package io.privy.privyflutter.channel

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.privy.auth.PrivyUser
import io.privy.auth.siws.SiwsMessageParams
import io.privy.auth.siwe.WalletLoginMetadata
import io.privy.privyflutter.PrivyManager
import io.privy.privyflutter.constants.ErrorConstants.INVALID_ARGUMENT
import io.privy.privyflutter.constants.ErrorConstants.LINK_ERROR
import io.privy.privyflutter.constants.ErrorConstants.LOGIN_ERROR
import io.privy.privyflutter.constants.ErrorConstants.SIWS_GENERATE_MESSAGE_ERROR
import io.privy.privyflutter.constants.ErrorConstants.UNLINK_ERROR
import io.privy.privyflutter.helpers.MethodHandler
import io.privy.privyflutter.helpers.deserializeSiwsMessageParams
import io.privy.privyflutter.helpers.deserializeWalletLoginMetadata
import io.privy.privyflutter.helpers.postError
import io.privy.privyflutter.helpers.postSuccess
import io.privy.privyflutter.helpers.serializeUser
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * Handles SIWS (Sign-In with Solana) authentication methods for Flutter using Privy's SDK.
 * This class listens to method calls from Flutter and processes SIWS-based authentication.
 */
class SiwsAuthHandler(private val coroutineScope: CoroutineScope) : MethodHandler(
    setOf(
        SIWS_GENERATE_MESSAGE,
        SIWS_LOGIN,
        SIWS_LINK,
        SIWS_UNLINK,
    ),
) {

    // Define private constants
    private companion object {
        private const val SIWS_GENERATE_MESSAGE = "generateSiwsMessage"
        private const val SIWS_LOGIN = "siwsLogin"
        private const val SIWS_LINK = "siwsLink"
        private const val SIWS_UNLINK = "siwsUnlink"
    }

    /**
     * Handles method calls received from Flutter.
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            SIWS_GENERATE_MESSAGE -> {
                try {
                    val params = deserializeSiwsMessageParams(call.arguments as Map<String, Any?>)
                    handleGenerateMessage(params, result)
                } catch (e: Exception) {
                    result.error(INVALID_ARGUMENT, "Invalid SIWS message parameters: ${e.message}", null)
                }
            }

            SIWS_LOGIN -> {
                val message: String? = call.argument("message")
                val signature: String? = call.argument("signature")

                if (message.isNullOrEmpty() || signature.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "Message and signature are required", null)
                    return
                }

                try {
                    val params = deserializeSiwsMessageParams(call.arguments as Map<String, Any?>)
                    val metadata = deserializeWalletLoginMetadata(call.arguments as Map<String, Any?>)
                    handleLoginWithSiws(message, signature, params, metadata, result)
                } catch (e: Exception) {
                    result.error(INVALID_ARGUMENT, "Invalid SIWS login parameters: ${e.message}", null)
                }
            }

            SIWS_LINK -> {
                val message: String? = call.argument("message")
                val signature: String? = call.argument("signature")

                if (message.isNullOrEmpty() || signature.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "Message and signature are required", null)
                    return
                }

                try {
                    val params = deserializeSiwsMessageParams(call.arguments as Map<String, Any?>)
                    val metadata = deserializeWalletLoginMetadata(call.arguments as Map<String, Any?>)
                    handleLinkWithSiws(message, signature, params, metadata, result)
                } catch (e: Exception) {
                    result.error(INVALID_ARGUMENT, "Invalid SIWS link parameters: ${e.message}", null)
                }
            }

            SIWS_UNLINK -> {
                val address: String? = call.argument("address")

                if (address.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "Address is required", null)
                    return
                }

                handleUnlinkWithSiws(address, result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Handles generating a SIWS message for the user to sign.
     * Uses the new generateMessage() method from the Android SDK.
     */
    private fun handleGenerateMessage(
        params: SiwsMessageParams,
        result: MethodChannel.Result
    ) {
        coroutineScope.launch {
            try {
                // Use the new method name from Android SDK
                val generateResult: Result<String> = PrivyManager.privy.siws.generateMessage(params)

                generateResult.fold(
                    onSuccess = { message ->
                        result.postSuccess(message)
                    },
                    onFailure = { error ->
                        result.postError(SIWS_GENERATE_MESSAGE_ERROR, error.message, null)
                    }
                )
            } catch (e: Exception) {
                result.postError(SIWS_GENERATE_MESSAGE_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles login using SIWS signature and returns the PrivyUser object to Flutter.
     * Uses the new login() method from the Android SDK.
     */
    private fun handleLoginWithSiws(
        message: String,
        signature: String,
        params: SiwsMessageParams,
        metadata: WalletLoginMetadata?,
        result: MethodChannel.Result
    ) {
        coroutineScope.launch {
            try {
                // Use the new method name from Android SDK
                val loginResult: Result<PrivyUser> = PrivyManager.privy.siws.login(
                    message = message,
                    signature = signature,
                    params = params,
                    metadata = metadata
                )

                loginResult.fold(
                    onSuccess = { user ->
                        val serializedUser = serializeUser(user)
                        result.postSuccess(serializedUser)
                    },
                    onFailure = { error ->
                        result.postError(LOGIN_ERROR, error.message, null)
                    }
                )
            } catch (e: Exception) {
                result.postError(LOGIN_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles linking a Solana wallet to the currently authenticated user using SIWS signature.
     * Uses the new link() method from the Android SDK.
     */
    private fun handleLinkWithSiws(
        message: String,
        signature: String,
        params: SiwsMessageParams,
        metadata: WalletLoginMetadata?,
        result: MethodChannel.Result
    ) {
        coroutineScope.launch {
            try {
                // Use the new method name from Android SDK
                val linkResult: Result<PrivyUser> = PrivyManager.privy.siws.link(
                    message = message,
                    signature = signature,
                    params = params,
                    metadata = metadata
                )

                linkResult.fold(
                    onSuccess = { user ->
                        val serializedUser = serializeUser(user)
                        result.postSuccess(serializedUser)
                    },
                    onFailure = { error ->
                        result.postError(LINK_ERROR, error.message, null)
                    }
                )
            } catch (e: Exception) {
                result.postError(LINK_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles unlinking a Solana wallet from the currently authenticated user.
     * Uses the unlink() method from the Android SDK.
     */
    private fun handleUnlinkWithSiws(
        address: String,
        result: MethodChannel.Result
    ) {
        coroutineScope.launch {
            try {
                val unlinkResult: Result<PrivyUser> = PrivyManager.privy.siws.unlink(address)

                unlinkResult.fold(
                    onSuccess = { user ->
                        val serializedUser = serializeUser(user)
                        result.postSuccess(serializedUser)
                    },
                    onFailure = { error ->
                        result.postError(UNLINK_ERROR, error.message, null)
                    }
                )
            } catch (e: Exception) {
                result.postError(UNLINK_ERROR, e.message, null)
            }
        }
    }
}

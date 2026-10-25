package io.privy.privyflutter.channel

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.privy.auth.PrivyUser
import io.privy.auth.siwe.SiweMessageParams
import io.privy.auth.siwe.WalletLoginMetadata
import io.privy.privyflutter.PrivyManager
import io.privy.privyflutter.constants.ErrorConstants.INVALID_ARGUMENT
import io.privy.privyflutter.constants.ErrorConstants.LOGIN_ERROR
import io.privy.privyflutter.constants.ErrorConstants.SIWE_GENERATE_MESSAGE_ERROR
import io.privy.privyflutter.constants.ErrorConstants.SIWE_LINK_ERROR
import io.privy.privyflutter.constants.ErrorConstants.UNLINK_ERROR
import io.privy.privyflutter.helpers.MethodHandler
import io.privy.privyflutter.helpers.deserializeSiweMessageParams
import io.privy.privyflutter.helpers.deserializeWalletLoginMetadata
import io.privy.privyflutter.helpers.postError
import io.privy.privyflutter.helpers.postSuccess
import io.privy.privyflutter.helpers.serializeUser
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * Handles SIWE (Sign-In with Ethereum) authentication methods for Flutter using Privy's SDK.
 * This class listens to method calls from Flutter and processes SIWE-based authentication.
 */
class SiweAuthHandler(private val coroutineScope: CoroutineScope) : MethodHandler(
    setOf(
        SIWE_GENERATE_MESSAGE,
        SIWE_LOGIN,
        SIWE_LINK,
        SIWE_UNLINK,
    ),
) {

    // Define private constants
    private companion object {
        private const val SIWE_GENERATE_MESSAGE = "generateSiweMessage"
        private const val SIWE_LOGIN = "siweLogin"
        private const val SIWE_LINK = "siweLink"
        private const val SIWE_UNLINK = "siweUnlink"
    }

    /**
     * Handles method calls received from Flutter.
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            SIWE_GENERATE_MESSAGE -> {
                try {
                    val params = deserializeSiweMessageParams(call.arguments as Map<String, Any?>)
                    handleGenerateMessage(params, result)
                } catch (e: Exception) {
                    result.error(INVALID_ARGUMENT, "Invalid SIWE message parameters: ${e.message}", null)
                }
            }

            SIWE_LOGIN -> {
                val message: String? = call.argument("message")
                val signature: String? = call.argument("signature")

                if (message.isNullOrEmpty() || signature.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "Message and signature are required", null)
                    return
                }

                try {
                    val params = deserializeSiweMessageParams(call.arguments as Map<String, Any?>)
                    val metadata = deserializeWalletLoginMetadata(call.arguments as Map<String, Any?>)
                    handleLoginWithSiwe(message, signature, params, metadata, result)
                } catch (e: Exception) {
                    result.error(INVALID_ARGUMENT, "Invalid SIWE login parameters: ${e.message}", null)
                }
            }

            SIWE_LINK -> {
                val message: String? = call.argument("message")
                val signature: String? = call.argument("signature")

                if (message.isNullOrEmpty() || signature.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "Message and signature are required", null)
                    return
                }

                try {
                    val params = deserializeSiweMessageParams(call.arguments as Map<String, Any?>)
                    val metadata = deserializeWalletLoginMetadata(call.arguments as Map<String, Any?>)
                    handleLinkWithSiwe(message, signature, params, metadata, result)
                } catch (e: Exception) {
                    result.error(INVALID_ARGUMENT, "Invalid SIWE link parameters: ${e.message}", null)
                }
            }

            SIWE_UNLINK -> {
                val address: String? = call.argument("address")

                if (address.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "Address is required", null)
                    return
                }

                handleUnlinkWithSiwe(address, result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Handles generating a SIWE message for the user to sign.
     * Uses the new generateMessage() method from the Android SDK.
     */
    private fun handleGenerateMessage(
        params: SiweMessageParams,
        result: MethodChannel.Result
    ) {
        coroutineScope.launch {
            try {
                // Use the new method name from Android SDK
                val generateResult: Result<String> = PrivyManager.privy.siwe.generateMessage(params)

                generateResult.fold(
                    onSuccess = { message ->
                        result.postSuccess(message)
                    },
                    onFailure = { error ->
                        result.postError(SIWE_GENERATE_MESSAGE_ERROR, error.message, null)
                    }
                )
            } catch (e: Exception) {
                result.postError(SIWE_GENERATE_MESSAGE_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles login using SIWE signature and returns the PrivyUser object to Flutter.
     * Uses the new login() method from the Android SDK.
     */
    private fun handleLoginWithSiwe(
        message: String,
        signature: String,
        params: SiweMessageParams,
        metadata: WalletLoginMetadata?,
        result: MethodChannel.Result
    ) {
        coroutineScope.launch {
            try {
                // Use the new method name from Android SDK
                val loginResult: Result<PrivyUser> = PrivyManager.privy.siwe.login(
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
     * Handles linking a wallet using SIWE signature to the authenticated user.
     * Uses the new link() method from the Android SDK.
     */
    private fun handleLinkWithSiwe(
        message: String,
        signature: String,
        params: SiweMessageParams,
        metadata: WalletLoginMetadata?,
        result: MethodChannel.Result
    ) {
        coroutineScope.launch {
            try {
                // Use the new method name from Android SDK
                val linkResult: Result<PrivyUser> = PrivyManager.privy.siwe.link(
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
                        result.postError(SIWE_LINK_ERROR, error.message, null)
                    }
                )
            } catch (e: Exception) {
                result.postError(SIWE_LINK_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles unlinking an Ethereum wallet from the currently authenticated user.
     * Uses the unlink() method from the Android SDK.
     */
    private fun handleUnlinkWithSiwe(
        address: String,
        result: MethodChannel.Result
    ) {
        coroutineScope.launch {
            try {
                val unlinkResult: Result<PrivyUser> = PrivyManager.privy.siwe.unlink(address)

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
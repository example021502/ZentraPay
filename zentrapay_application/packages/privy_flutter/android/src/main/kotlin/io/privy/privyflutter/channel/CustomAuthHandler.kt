package io.privy.privyflutter.channel

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.privy.privyflutter.PrivyManager
import io.privy.privyflutter.constants.ErrorConstants.LOGIN_ERROR
import io.privy.privyflutter.helpers.MethodHandler
import io.privy.privyflutter.helpers.postError
import io.privy.privyflutter.helpers.postSuccess
import io.privy.privyflutter.helpers.serializeUser
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * Handles custom authentication methods for Flutter using Privy's SDK.
 * This class listens to method calls from Flutter and processes custom auth-based authentication.
 */

class CustomAuthHandler(private val coroutineScope: CoroutineScope) : MethodHandler(
    setOf(
        LOGIN_WITH_CUSTOM_ACCESS_TOKEN,
    ),
) {

    // Define private constants
    private companion object {
        private const val LOGIN_WITH_CUSTOM_ACCESS_TOKEN = "loginWithCustomAccessToken"
    }

    /**
     * Handles method calls received from Flutter.
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            LOGIN_WITH_CUSTOM_ACCESS_TOKEN -> handleLoginWithCustomAccessToken(result)
            else -> result.notImplemented()
        }
    }

    /**
     * Handles logging in with a custom access token using Privy's SDK.
     * Serializes and returns the PrivyUser object to Flutter on success.
     */
    private fun handleLoginWithCustomAccessToken(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                // Call Privy's SDK method for custom auth login
                val loginResult = PrivyManager.privy.customAuth.loginWithCustomAccessToken()

                loginResult.fold(
                    onSuccess = { user ->

                        // Serialize PrivyUser to send back to Flutter
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
}

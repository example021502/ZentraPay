package io.privy.privyflutter.channel

import android.content.Intent
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.privy.auth.oAuth.OAuthProvider
import io.privy.auth.PrivyUser
import io.privy.privyflutter.PrivyManager
import io.privy.privyflutter.constants.ErrorConstants.INVALID_ARGUMENT
import io.privy.privyflutter.constants.ErrorConstants.LINK_ERROR
import io.privy.privyflutter.constants.ErrorConstants.LOGIN_ERROR
import io.privy.privyflutter.constants.ErrorConstants.UNLINK_ERROR
import io.privy.privyflutter.helpers.MethodHandler
import io.privy.privyflutter.helpers.serializeUser
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * Handles OAuth authentication methods for Flutter using Privy's SDK.
 * This class listens to method calls from Flutter and processes OAuth-based authentication.
 */
class OAuthHandler(private val coroutineScope: CoroutineScope) : MethodHandler(
    setOf(
        OAUTH_LOGIN,
        OAUTH_LINK,
        OAUTH_UNLINK,
    ),
) {

    // Define private constants directly in the class
    private companion object {
        private const val OAUTH_LOGIN = "oauthLogin"
        private const val OAUTH_LINK = "oauthLink"
        private const val OAUTH_UNLINK = "oauthUnlink"
    }

    /**
     * Handles method calls received from Flutter.
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            OAUTH_LOGIN -> login(call, result)
            OAUTH_LINK -> link(call, result)
            OAUTH_UNLINK -> unlink(call, result)
            else -> result.notImplemented()
        }
    }

    /**
     * Handles OAuth login with a specified provider.
     */
    private fun login(call: MethodCall, result: MethodChannel.Result) {
        val providerString = call.argument<String>("provider")
        val appUrlScheme: String = call.argument<String>("appUrlScheme") ?: ""

        if (providerString.isNullOrEmpty()) {
            result.error(INVALID_ARGUMENT, "Provider is required for OAuth login", null)
            return
        }

        val provider: OAuthProvider = try {
            convertToOAuthProvider(providerString)
        } catch (e: IllegalArgumentException) {
            result.error(INVALID_ARGUMENT, e.message, null)
            return
        }

        coroutineScope.launch {
            try {
                // The Privy SDK's OAuth login method now returns the Result<PrivyUser> directly
                val loginResult = PrivyManager.privy.oAuth.login(provider, appUrlScheme)

                loginResult.fold(
                    onSuccess = { user ->
                        val serializedUser = serializeUser(user)
                        result.success(serializedUser)
                    },
                    onFailure = { error ->
                        result.error(LOGIN_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.error(LOGIN_ERROR, e.message, null)
            }
        }
    }

    /**
     * Links an OAuth provider to the currently authenticated user.
     */
    private fun link(call: MethodCall, result: MethodChannel.Result) {
        val providerString = call.argument<String>("provider")
        val appUrlScheme: String = call.argument<String>("appUrlScheme") ?: ""

        if (providerString.isNullOrEmpty()) {
            result.error(INVALID_ARGUMENT, "Provider is required for OAuth link", null)
            return
        }

        val provider: OAuthProvider = try {
            convertToOAuthProvider(providerString)
        } catch (e: IllegalArgumentException) {
            result.error(INVALID_ARGUMENT, e.message, null)
            return
        }

        coroutineScope.launch {
            try {
                val linkResult = PrivyManager.privy.oAuth.link(provider, appUrlScheme)

                linkResult.fold(
                    onSuccess = { user ->
                        val serializedUser = serializeUser(user)
                        result.success(serializedUser)
                    },
                    onFailure = { error ->
                        result.error(LINK_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.error(LINK_ERROR, e.message, null)
            }
        }
    }

    /**
     * Unlinks an OAuth provider from the currently authenticated user.
     */
    private fun unlink(call: MethodCall, result: MethodChannel.Result) {
        val providerString = call.argument<String>("provider")
        val subject = call.argument<String>("subject")

        if (providerString.isNullOrEmpty()) {
            result.error(INVALID_ARGUMENT, "Provider is required for OAuth unlink", null)
            return
        }

        if (subject.isNullOrEmpty()) {
            result.error(INVALID_ARGUMENT, "Subject is required for OAuth unlink", null)
            return
        }

        val provider: OAuthProvider = try {
            convertToOAuthProvider(providerString)
        } catch (e: IllegalArgumentException) {
            result.error(INVALID_ARGUMENT, e.message, null)
            return
        }

        coroutineScope.launch {
            try {
                val unlinkResult = PrivyManager.privy.oAuth.unlink(provider, subject)

                unlinkResult.fold(
                    onSuccess = { user ->
                        val serializedUser = serializeUser(user)
                        result.success(serializedUser)
                    },
                    onFailure = { error ->
                        result.error(UNLINK_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.error(UNLINK_ERROR, e.message, null)
            }
        }
    }

    /**
     * Converts a Flutter OAuth provider string to the native Android OAuthProvider enum.
     *
     * Flutter sends lowercase provider names (e.g., "google", "twitter") but the Android
     * Privy SDK expects PascalCase enum values (e.g., OAuthProvider.Google, OAuthProvider.Twitter).
     * This function handles the conversion between these formats.
     *
     * @param providerString The lowercase provider string from Flutter
     * @return The corresponding OAuthProvider enum value
     * @throws IllegalArgumentException if the provider string doesn't match any known provider
     */
    private fun convertToOAuthProvider(providerString: String): OAuthProvider {
        val pascalCaseProvider = providerString.replaceFirstChar { it.uppercase() }
        return OAuthProvider.valueOf(pascalCaseProvider)
    }
}

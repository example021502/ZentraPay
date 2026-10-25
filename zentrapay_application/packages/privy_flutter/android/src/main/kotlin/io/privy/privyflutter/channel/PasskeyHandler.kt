package io.privy.privyflutter.channel

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.privy.auth.PrivyUser
import io.privy.privyflutter.PrivyManager
import io.privy.privyflutter.constants.ErrorConstants.INVALID_ARGUMENT
import io.privy.privyflutter.constants.ErrorConstants.PASSKEY_SIGNUP_ERROR
import io.privy.privyflutter.constants.ErrorConstants.PASSKEY_LOGIN_ERROR
import io.privy.privyflutter.constants.ErrorConstants.PASSKEY_LINK_ERROR
import io.privy.privyflutter.constants.ErrorConstants.PASSKEY_UNLINK_ERROR
import io.privy.privyflutter.helpers.MethodHandler
import io.privy.privyflutter.helpers.postError
import io.privy.privyflutter.helpers.postSuccess
import io.privy.privyflutter.helpers.serializeUser
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * Handles passkey authentication methods for Flutter using Privy's SDK.
 * This class listens to method calls from Flutter and processes passkey-based authentication
 * using FIDO2/WebAuthn.
 */
class PasskeyHandler(private val coroutineScope: CoroutineScope) : MethodHandler(
    setOf(
        PASSKEY_SIGNUP,
        PASSKEY_LOGIN,
        PASSKEY_LINK,
        PASSKEY_UNLINK,
    ),
) {

    // Define private constants directly in the class
    private companion object {
        private const val PASSKEY_SIGNUP = "passkeySignup"
        private const val PASSKEY_LOGIN = "passkeyLogin"
        private const val PASSKEY_LINK = "passkeyLink"
        private const val PASSKEY_UNLINK = "passkeyUnlink"
    }

    /**
     * Handles method calls received from Flutter.
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            PASSKEY_SIGNUP -> {
                val relyingParty: String? = call.argument("relyingParty")
                val displayName: String? = call.argument("displayName")

                if (relyingParty.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "Relying party is required for passkey signup", null)
                    return
                }

                handleSignup(relyingParty, displayName, result)
            }

            PASSKEY_LOGIN -> {
                val relyingParty: String? = call.argument("relyingParty")

                if (relyingParty.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "Relying party is required for passkey login", null)
                    return
                }

                handleLogin(relyingParty, result)
            }

            PASSKEY_LINK -> {
                val relyingParty: String? = call.argument("relyingParty")
                val displayName: String? = call.argument("displayName")

                if (relyingParty.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "Relying party is required for passkey link", null)
                    return
                }

                handleLink(relyingParty, displayName, result)
            }

            PASSKEY_UNLINK -> {
                val credentialId: String? = call.argument("credentialId")

                if (credentialId.isNullOrEmpty()) {
                    result.error(INVALID_ARGUMENT, "Credential ID is required for passkey unlink", null)
                    return
                }

                handleUnlink(credentialId, result)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Handles passkey signup flow.
     *
     * This initiates the passkey creation flow:
     * 1. Requests registration challenge from server
     * 2. Prompts user to create passkey using biometrics/PIN
     * 3. Registers the credential with server
     * 4. Returns authenticated user
     */
    private fun handleSignup(
        relyingParty: String,
        displayName: String?,
        result: MethodChannel.Result,
    ) {
        coroutineScope.launch {
            try {
                val signupResult: Result<PrivyUser> =
                    PrivyManager.privy.passkey.signup(relyingParty, displayName)

                signupResult.fold(
                    onSuccess = { user ->
                        val serializedUser = serializeUser(user)
                        result.postSuccess(serializedUser)
                    },
                    onFailure = { error ->
                        result.postError(PASSKEY_SIGNUP_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(PASSKEY_SIGNUP_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles passkey login flow.
     *
     * This initiates the passkey authentication flow:
     * 1. Requests authentication challenge from server
     * 2. Shows passkey selector to user
     * 3. User authenticates using biometrics/PIN
     * 4. Verifies credential with server
     * 5. Returns authenticated user
     */
    private fun handleLogin(relyingParty: String, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val loginResult: Result<PrivyUser> =
                    PrivyManager.privy.passkey.login(relyingParty)

                loginResult.fold(
                    onSuccess = { user ->
                        val serializedUser = serializeUser(user)
                        result.postSuccess(serializedUser)
                    },
                    onFailure = { error ->
                        result.postError(PASSKEY_LOGIN_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(PASSKEY_LOGIN_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles passkey link flow.
     *
     * This links a passkey to the currently authenticated user's account:
     * 1. Requests registration challenge from server
     * 2. Prompts user to create passkey using biometrics/PIN
     * 3. Registers the credential with server
     * 4. Links passkey to existing user account
     * 5. Returns updated user
     */
    private fun handleLink(
        relyingParty: String,
        displayName: String?,
        result: MethodChannel.Result,
    ) {
        coroutineScope.launch {
            try {
                val linkResult: Result<PrivyUser> =
                    PrivyManager.privy.passkey.link(relyingParty, displayName)

                linkResult.fold(
                    onSuccess = { user ->
                        val serializedUser = serializeUser(user)
                        result.postSuccess(serializedUser)
                    },
                    onFailure = { error ->
                        result.postError(PASSKEY_LINK_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(PASSKEY_LINK_ERROR, e.message, null)
            }
        }
    }

    /**
     * Handles passkey unlink flow.
     *
     * This removes a passkey from the currently authenticated user's account:
     * 1. Identifies passkey by credential ID
     * 2. Removes credential from server
     * 3. Unlinks passkey from user account
     * 4. Returns updated user
     */
    private fun handleUnlink(credentialId: String, result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val unlinkResult: Result<PrivyUser> =
                    PrivyManager.privy.passkey.unlink(credentialId)

                unlinkResult.fold(
                    onSuccess = { user ->
                        val serializedUser = serializeUser(user)
                        result.postSuccess(serializedUser)
                    },
                    onFailure = { error ->
                        result.postError(PASSKEY_UNLINK_ERROR, error.message, null)
                    },
                )
            } catch (e: Exception) {
                result.postError(PASSKEY_UNLINK_ERROR, e.message, null)
            }
        }
    }
}

package io.privy.privyflutter.channel

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.privy.auth.PrivyUser
import io.privy.privyflutter.PrivyManager
import io.privy.privyflutter.constants.ErrorConstants.AWAIT_READY_ERROR
import io.privy.privyflutter.constants.ErrorConstants.GET_ACCESS_TOKEN_ERROR
import io.privy.privyflutter.constants.ErrorConstants.GET_USER_DATA_ERROR
import io.privy.privyflutter.constants.ErrorConstants.LOGOUT_ERROR
import io.privy.privyflutter.constants.ErrorConstants.REFRESH_USER_ERROR
import io.privy.privyflutter.constants.ErrorConstants.USER_NOT_FOUND
import io.privy.privyflutter.helpers.MethodHandler
import io.privy.privyflutter.helpers.postError
import io.privy.privyflutter.helpers.postSuccess
import io.privy.privyflutter.helpers.serializeAuthState
import io.privy.privyflutter.helpers.serializeUser
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

/**
 * Handles email authentication methods for Flutter using Privy's SDK.
 * This class listens to method calls from Flutter and processes email-based authentication.
 */
class AuthHandler(private val coroutineScope: CoroutineScope) : MethodHandler(
    setOf(
        LOGOUT,
        AWAIT_READY,
        GET_USER,
        REFRESH_USER,
        GET_ACCESS_TOKEN,
        GET_AUTH_STATE,
    ),
) {

    // Define private constants
    private companion object {
        private const val LOGOUT = "logout"
        private const val AWAIT_READY = "awaitReady"
        private const val GET_USER = "getUser"
        private const val REFRESH_USER = "refreshUser"
        private const val GET_ACCESS_TOKEN = "getAccessToken"
        private const val GET_AUTH_STATE = "getAuthState"
    }

    /**
     * Handles method calls received from Flutter.
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            LOGOUT -> {
                handleLogout(result)
            }

            AWAIT_READY -> {
                handleAwaitReady(result)
            }

            GET_USER -> {
                handleGetUser(result)
            }

            REFRESH_USER -> {
                handleRefreshUser(result)
            }

            GET_ACCESS_TOKEN -> {
                handleGetAccessToken(result)
            }

            GET_AUTH_STATE -> {
                getAuthState(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Handles user logout by calling the PrivyManager.privy.logout method.
     * If the user is already logged out on the native side, this succeeds silently.
     */
    private fun handleLogout(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.getUser()
                if (user != null) {
                    PrivyManager.privy.logout()
                }
                result.postSuccess(true)
            } catch (e: Exception) {
                result.postError(LOGOUT_ERROR, e.message, null)
            }
        }
    }

    /**
     * Calls Privy SDK to ensure it's fully initialized before proceeding.
     */
    private fun handleAwaitReady(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                PrivyManager.privy.awaitReady()
                result.postSuccess(null) // Indicate success to Flutter
            } catch (e: Exception) {
                result.postError(AWAIT_READY_ERROR, e.message, null)
            }
        }
    }

    /**
     * Fetches the user data from the Privy SDK and serializes it before returning to Flutter.
     */
    private fun handleGetUser(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val user: PrivyUser? = PrivyManager.privy.getUser()
                if (user != null) {
                    val serializedUser = serializeUser(user)
                    result.postSuccess(serializedUser) // Return the serialized user data to Flutter
                } else {
                    result.postError(USER_NOT_FOUND, "User is not authenticated", null)
                }
            } catch (e: Exception) {
                result.postError(GET_USER_DATA_ERROR, e.message, null)
            }
        }
    }

    /**
     * Refreshes the user data from the server, then returns the updated user to Flutter.
     */
    private fun handleRefreshUser(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val user: PrivyUser? = PrivyManager.privy.getUser()
                if (user != null) {
                    user.refresh().fold(
                        onSuccess = {
                            val refreshedUser = PrivyManager.privy.getUser()
                            if (refreshedUser != null) {
                                val serializedUser = serializeUser(refreshedUser)
                                result.postSuccess(serializedUser)
                            } else {
                                result.postError(USER_NOT_FOUND, "User is not authenticated", null)
                            }
                        },
                        onFailure = { error ->
                            result.postError(REFRESH_USER_ERROR, error.message, null)
                        },
                    )
                } else {
                    result.postError(USER_NOT_FOUND, "User is not authenticated", null)
                }
            } catch (e: Exception) {
                result.postError(REFRESH_USER_ERROR, e.message, null)
            }
        }
    }

    /**
     * Fetches the access token from the Privy SDK and returns it to Flutter.
     */
    private fun handleGetAccessToken(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val user: PrivyUser? = PrivyManager.privy.user

                if (user != null) {
                    val accessTokenResult: Result<String> = user.getAccessToken()

                    accessTokenResult.fold(
                        onSuccess = { token ->
                            result.postSuccess(token) // Return access token to Flutter
                        },
                        onFailure = { error ->
                            result.postError(GET_ACCESS_TOKEN_ERROR, error.message, null) // Handle failure case
                        },
                    )
                } else {
                    result.postError(USER_NOT_FOUND, "User is not authenticated", null)
                }
            } catch (e: Exception) {
                result.postError(GET_ACCESS_TOKEN_ERROR, e.message, null)
            }
        }
    }


    private fun getAuthState(result: MethodChannel.Result) {
        coroutineScope.launch {
            try {
                val authState = PrivyManager.privy.getAuthState()

                val serializedAuthState = serializeAuthState(authState) 

                result.postSuccess(serializedAuthState)
            } catch (e: Exception) {
                result.postError("getAuthStateError", e.message, null)
            }
        }
      }
}

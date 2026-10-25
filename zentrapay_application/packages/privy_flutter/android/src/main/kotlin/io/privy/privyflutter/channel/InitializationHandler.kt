package io.privy.privyflutter.channel

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.privy.auth.PrivyUser
import io.privy.auth.mfa.MfaConfig
import io.privy.auth.mfa.MfaListener
import io.privy.privyflutter.PrivyManager
import io.privy.privyflutter.helpers.MethodHandler
import io.privy.privyflutter.helpers.serializeUser
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume
import kotlin.time.Duration.Companion.milliseconds

/**
 * Handles method calls from Flutter to initialize the Privy SDK and manage authentication.
 */
class InitializationHandler(
    private val context: Context,
    private val methodChannel: MethodChannel,
    private val coroutineScope: CoroutineScope,
) : MethodHandler(
    setOf(
        INITIALIZE_PRIVY,
    ),
) {
    // Define private constants directly in the class
    private companion object {
        private const val INITIALIZE_PRIVY = "initializePrivy"
    }

    /**
     * Handles method calls received from Flutter.
     * Supports initializing Privy with or without custom authentication.
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            INITIALIZE_PRIVY -> {
                // Extract arguments from Flutter call
                val appId = call.argument<String>("appId")!!
                val appClientId = call.argument<String>("appClientId")!!
                val logLevel = call.argument<String>("logLevel") ?: "NONE"
                val shouldInitializeCustomAuth =
                    call.argument<Boolean>("shouldInitializeCustomAuth")!!
                val shouldInitializeMfa = call.argument<Boolean>("shouldInitializeMfa") ?: false
                val mfaTimeoutMs = call.argument<Int>("mfaTimeoutMs")
                val disableAutomaticMigration =
                    call.argument<Boolean>("disableAutomaticMigration") ?: false

                // Define the token provider function if custom authentication is enabled
                val tokenProvider: suspend () -> String? = if (shouldInitializeCustomAuth) {
                    { fetchTokenFromDart() } // Fetch token dynamically from Flutter
                } else {
                    { null } // Default no-op function if custom authentication is not used
                }

                // Build MFA config if configured from Flutter
                val mfaConfig: MfaConfig? = if (shouldInitializeMfa) {
                    MfaConfig(
                        listener = object : MfaListener {
                            override fun onMfaRequired(user: PrivyUser) {
                                coroutineScope.launch {
                                    val serialized = serializeUser(user)
                                    withContext(Dispatchers.Main) {
                                        methodChannel.invokeMethod("onMfaRequired", serialized)
                                    }
                                }
                            }
                        },
                        timeout = (mfaTimeoutMs ?: 300000).milliseconds,
                    )
                } else {
                    null
                }

                // Initialize Privy with the provided configuration
                PrivyManager.initialize(
                    context = context,
                    appId = appId,
                    appClientId = appClientId,
                    logLevel = logLevel,
                    shouldInitializeCustomAuth = shouldInitializeCustomAuth,
                    tokenProvider = tokenProvider,
                    mfaConfig = mfaConfig,
                    disableAutomaticMigration = disableAutomaticMigration,
                )

                // Return success response to Flutter
                result.success("Privy initialized successfully")
            }

            else -> {
                // Handle unimplemented method calls
                result.notImplemented()
            }
        }
    }

    /**
     * Fetches an authentication token from the Flutter side.
     * This is used for custom authentication when Privy requires a valid access token.
     */
    private suspend fun fetchTokenFromDart(): String? {
        return withContext(Dispatchers.Main) { // Ensure execution on the main thread
            suspendCancellableCoroutine { continuation ->
                // Request a token from Flutter via MethodChannel
                methodChannel.invokeMethod(
                    "getCustomAuthToken",
                    null,
                    object : MethodChannel.Result {

                        override fun success(result: Any?) {
                            val token = result as? String
                            continuation.resume(token) // Return the token if available
                        }

                        override fun notImplemented() {
                            continuation.resume(null) // Return null if the method is not implemented
                        }

                        override fun error(
                            errorCode: String,
                            errorMessage: String?,
                            errorDetails: Any?,
                        ) {
                            continuation.resume(null) // Return null in case of an error
                        }
                    },
                )
            }
        }
    }
}

package io.privy.privyflutter

import android.content.Context
import io.privy.auth.mfa.MfaConfig
import io.privy.logging.PrivyLogLevel
import io.privy.sdk.LoginWithCustomAuthConfig
import io.privy.sdk.Privy
import io.privy.sdk.PrivyConfig

/**
 * Singleton object to manage the Privy instance and its initialization.
 */
object PrivyManager {

    // Late-initialized Privy instance. Will be assigned when initialize() is called.
    lateinit var privy: Privy

    // Boolean flag to track whether Privy has been initialized.
    var isInitialized = false

    /**
     * Initializes the Privy instance with the given configuration.
     * Ensures that initialization happens only once.
     *
     * @param context The application context.
     * @param appId The unique Privy app ID.
     * @param appClientId The client ID for authentication.
     * @param logLevel The logging level for Privy.
     * @param shouldInitializeCustomAuth Boolean to indicate if custom authentication should be enabled.
     * @param tokenProvider Optional suspendable function to fetch authentication tokens.
     */
    fun initialize(
        context: Context,
        appId: String,
        appClientId: String,
        logLevel: String,
        shouldInitializeCustomAuth: Boolean,
        tokenProvider: suspend () -> String? = { null }, // Optional for custom auth
        mfaConfig: MfaConfig? = null,
        disableAutomaticMigration: Boolean = false,
    ) {
        // Prevents multiple initializations of Privy
        if (isInitialized) {
            return
        }

        // Initialize Privy with the provided configuration
        privy = Privy.init(
            context = context.applicationContext,
            config = PrivyConfig(
                appId = appId,
                appClientId = appClientId,
                logLevel = PrivyLogLevel.valueOf(logLevel), // Convert string to PrivyLogLevel enum
                customAuthConfig = LoginWithCustomAuthConfig(
                    tokenProvider = tokenProvider,
                ),
                mfaConfig = mfaConfig,
                disableAutomaticMigration = disableAutomaticMigration,
            ),
        )
        // Set the initialized flag to true after successful initialization
        isInitialized = true
    }
}

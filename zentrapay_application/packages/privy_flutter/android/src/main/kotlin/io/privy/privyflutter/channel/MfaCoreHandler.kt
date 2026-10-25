package io.privy.privyflutter.channel

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.privy.auth.PrivyUser
import io.privy.auth.mfa.MfaConfig
import io.privy.auth.mfa.MfaListener
import io.privy.privyflutter.PrivyManager
import io.privy.privyflutter.constants.ErrorConstants.INVALID_ARGUMENT
import io.privy.privyflutter.constants.ErrorConstants.MFA_ERROR
import io.privy.privyflutter.helpers.MethodHandler
import io.privy.privyflutter.helpers.postError
import io.privy.privyflutter.helpers.postSuccess
import io.privy.privyflutter.helpers.serializeUser
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.time.Duration.Companion.milliseconds

/**
 * Handles MFA configuration and blocked action resumption for Flutter.
 */
class MfaCoreHandler(
    private val coroutineScope: CoroutineScope,
    private val methodChannel: MethodChannel,
) : MethodHandler(
    setOf(MFA_SET_CONFIG, MFA_RESUME_BLOCKED_ACTIONS),
) {

    private companion object {
        private const val MFA_SET_CONFIG = "mfaSetConfig"
        private const val MFA_RESUME_BLOCKED_ACTIONS = "mfaResumeBlockedActions"
    }

    /**
     * Handles method calls received from Flutter.
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            MFA_SET_CONFIG -> handleSetConfig(call, result)
            MFA_RESUME_BLOCKED_ACTIONS -> handleResumeBlockedActions(call, result)
            else -> result.notImplemented()
        }
    }

    /**
     * Configures MFA with a listener and timeout.
     */
    private fun handleSetConfig(call: MethodCall, result: MethodChannel.Result) {
        val timeoutMs: Int? = call.argument("timeoutMs")
        if (timeoutMs == null) {
            result.error(INVALID_ARGUMENT, "timeoutMs is required", null)
            return
        }

        coroutineScope.launch {
            try {
                PrivyManager.privy.mfa.setConfig(
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
                        timeout = timeoutMs.milliseconds,
                    ),
                )
                result.postSuccess(null)
            } catch (e: Exception) {
                result.postError(MFA_ERROR, e.message, null)
            }
        }
    }

    /**
     * Resumes blocked MFA actions, optionally passing an error to cancel.
     */
    private fun handleResumeBlockedActions(call: MethodCall, result: MethodChannel.Result) {
        val errorMessage: String? = call.argument("error")

        coroutineScope.launch {
            try {
                if (errorMessage != null) {
                    PrivyManager.privy.mfa.resumeBlockedActions(
                        mfaError = Exception(errorMessage),
                    )
                } else {
                    PrivyManager.privy.mfa.resumeBlockedActions()
                }
                result.postSuccess(null)
            } catch (e: Exception) {
                result.postError(MFA_ERROR, e.message, null)
            }
        }
    }
}

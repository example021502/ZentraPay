package io.privy.privyflutter.handlers

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.privy.privyflutter.constants.ErrorConstants.SET_PUB_DEV_VERSION_ERROR
import io.privy.privyflutter.helpers.MethodHandler
import io.privy.sdk.internal.PrivyInternal

class VersionHandler : MethodHandler(setOf(SET_PUB_DEV_VERSION)) {

    // Define private constants directly in the class
    private companion object {
        private const val SET_PUB_DEV_VERSION = "setPubDevVersion"
        private const val KEY_PLATFORM = "platform"
        private const val KEY_VERSION = "version"
        private const val KEY_SECRET = "secret"
        private const val SECRET_KEY = "caba52bb-499e-4034-aaa6-bb4fbcdee175"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            SET_PUB_DEV_VERSION -> handleSetPubDevVersion(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleSetPubDevVersion(call: MethodCall, result: MethodChannel.Result) {
        val sdkVersion = call.argument<String>("sdkVersion") ?: "unknown"

        try {
            val config = mapOf(
                KEY_PLATFORM to "flutter",
                KEY_VERSION to sdkVersion,
                KEY_SECRET to SECRET_KEY,
            )

            PrivyInternal.setConfig(config)
            result.success(null)
        } catch (e: Exception) {
            result.error(SET_PUB_DEV_VERSION_ERROR, "Failed to set SDK version: ${e.localizedMessage}", null)
        }
    }
}

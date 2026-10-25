package io.privy.privyflutter.helpers

import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * Extension function to post a success response on the main thread.
 */
suspend fun MethodChannel.Result.postSuccess(response: Any?) {
    withContext(Dispatchers.Main) {
        success(response)
    }
}

/**
 * Extension function to post an error response on the main thread.
 */
suspend fun MethodChannel.Result.postError(code: String, message: String?, details: Any?) {
    withContext(Dispatchers.Main) {
        error(code, message, details)
    }
}

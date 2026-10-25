package io.privy.privyflutter.channel

import android.util.Log
import io.flutter.plugin.common.EventChannel
import io.privy.privyflutter.PrivyManager
import io.privy.privyflutter.helpers.serializeAuthState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Handles authentication state updates and sends them to Flutter via an EventChannel.
 */
class AuthStateEventChannelHandler(private val coroutineScope: CoroutineScope) :
    EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events

        coroutineScope.launch {
            try {
                // Start collecting authState changes from Privy after initialization
                PrivyManager.privy.authState.collectLatest { authState ->

                    val serializedAuthState = serializeAuthState(authState)

                    withContext(Dispatchers.Main) {
                        eventSink?.success(serializedAuthState) // Send serialized data to Flutter on the main thread
                    }
                }
            } catch (e: Exception) {
                Log.e("AuthStateHandler", "Error while listening to authState: ${e.message}")
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        // Stop sending events when Flutter stops listening
        eventSink = null
    }
}

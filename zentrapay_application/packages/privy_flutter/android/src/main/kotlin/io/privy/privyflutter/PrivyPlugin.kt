package io.privy.privyflutter

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.privy.privyflutter.channel.AuthHandler
import io.privy.privyflutter.channel.AuthStateEventChannelHandler
import io.privy.privyflutter.channel.AuthorizationSignatureHandler
import io.privy.privyflutter.channel.CustomAuthHandler
import io.privy.privyflutter.channel.EmailAuthHandler
import io.privy.privyflutter.channel.InitializationHandler
import io.privy.privyflutter.channel.MfaCoreHandler
import io.privy.privyflutter.channel.MfaSmsHandler
import io.privy.privyflutter.channel.MfaPasskeyHandler
import io.privy.privyflutter.channel.MfaTotpHandler
import io.privy.privyflutter.channel.OAuthHandler
import io.privy.privyflutter.channel.PasskeyHandler
import io.privy.privyflutter.channel.SiweAuthHandler
import io.privy.privyflutter.channel.SiwsAuthHandler
import io.privy.privyflutter.channel.SmsAuthHandler
import io.privy.privyflutter.channel.WalletHandler
import io.privy.privyflutter.handlers.VersionHandler
import io.privy.privyflutter.helpers.MethodHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

class PrivyPlugin : FlutterPlugin {
    // MethodChannel for handling method calls from Flutter
    private lateinit var methodChannel: MethodChannel

    // EventChannel for streaming authentication state updates to Flutter
    private lateinit var eventChannel: EventChannel

    // CoroutineScope for handling asynchronous tasks
    private lateinit var coroutineScope: CoroutineScope

    // Authentication state event handler
    private lateinit var authStateHandler: AuthStateEventChannelHandler

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        coroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

        // Create MethodChannel and handle method calls dynamically
        methodChannel = MethodChannel(binding.binaryMessenger, "privy_flutter")

        // Initialize handlers with CoroutineScope, making sure they implement MethodHandler
        val handlers: List<MethodHandler> = listOf(
            EmailAuthHandler(coroutineScope),
            SmsAuthHandler(coroutineScope),
            AuthHandler(coroutineScope),
            CustomAuthHandler(coroutineScope),
            WalletHandler(coroutineScope),
            OAuthHandler(coroutineScope),
            PasskeyHandler(coroutineScope),
            SiweAuthHandler(coroutineScope),
            SiwsAuthHandler(coroutineScope),
            AuthorizationSignatureHandler(coroutineScope),
            MfaCoreHandler(coroutineScope, methodChannel),
            MfaSmsHandler(coroutineScope),
            MfaTotpHandler(coroutineScope),
            MfaPasskeyHandler(coroutineScope),
            InitializationHandler(binding.applicationContext, methodChannel, coroutineScope),
            VersionHandler(), // VersionHandler initializes immediately
        )

        // Initialize AuthStateEventChannelHandler with CoroutineScope
        authStateHandler = AuthStateEventChannelHandler(coroutineScope)

        // Directly find the handler that can handle the method
        methodChannel.setMethodCallHandler { call, result ->
            val handler = handlers.find { it.canHandle(call.method) }
            handler?.onMethodCall(call, result) ?: result.notImplemented()
        }

        // Setup EventChannel for auth state updates
        eventChannel = EventChannel(binding.binaryMessenger, "privy_flutter/authState")
        eventChannel.setStreamHandler(authStateHandler)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        coroutineScope.cancel() // Cancel coroutine scope to prevent memory leaks
    }
}

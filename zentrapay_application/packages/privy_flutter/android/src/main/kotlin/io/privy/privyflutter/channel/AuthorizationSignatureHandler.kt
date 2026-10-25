package io.privy.privyflutter.channel

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.privy.privyflutter.PrivyManager
import io.privy.privyflutter.constants.ErrorConstants.GENERATE_AUTHORIZATION_SIGNATURE_ERROR
import io.privy.privyflutter.constants.ErrorConstants.INVALID_ARGUMENT
import io.privy.privyflutter.constants.ErrorConstants.USER_NOT_AUTHENTICATED
import io.privy.privyflutter.helpers.MethodHandler
import io.privy.privyflutter.helpers.postError
import io.privy.privyflutter.helpers.postSuccess
import io.privy.wallet.walletApi.WalletApiPayload
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.serializer

class AuthorizationSignatureHandler(private val coroutineScope: CoroutineScope) : MethodHandler(
    setOf(
        GENERATE_AUTHORIZATION_SIGNATURE,
        GENERATE_AUTHORIZATION_SIGNATURE_FROM_BYTES,
    ),
) {

    private companion object {
        private const val GENERATE_AUTHORIZATION_SIGNATURE = "generateAuthorizationSignature"
        private const val GENERATE_AUTHORIZATION_SIGNATURE_FROM_BYTES =
            "generateAuthorizationSignatureFromBytes"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            GENERATE_AUTHORIZATION_SIGNATURE -> {
                val version = call.argument<Int>("version")
                val url = call.argument<String>("url")
                val method = call.argument<String>("method")
                val headers = call.argument<Map<String, String>>("headers")
                val bodyJson = call.argument<String>("body")

                if (version == null || url == null || method == null ||
                    headers == null || bodyJson == null
                ) {
                    result.error(
                        INVALID_ARGUMENT,
                        "version, url, method, headers, and body are required",
                        null,
                    )
                    return
                }

                handleGenerateSignature(version, url, method, headers, bodyJson, result)
            }
            GENERATE_AUTHORIZATION_SIGNATURE_FROM_BYTES -> {
                val payload = (call.arguments as? List<*>)?.let { list ->
                    ByteArray(list.size) { (list[it] as Number).toByte() }
                }

                if (payload == null) {
                    result.error(
                        INVALID_ARGUMENT,
                        "payload is required",
                        null,
                    )
                    return
                }

                handleGenerateSignatureFromBytes(payload, result)
            }
        }
    }

    private fun handleGenerateSignature(
        version: Int,
        url: String,
        method: String,
        headers: Map<String, String>,
        bodyJson: String,
        result: MethodChannel.Result,
    ) {
        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user
                if (user == null) {
                    result.postError(
                        USER_NOT_AUTHENTICATED,
                        "User is not authenticated.",
                        null,
                    )
                    return@launch
                }

                val body = Json.decodeFromString<JsonObject>(bodyJson)

                val payload = WalletApiPayload(
                    version = version,
                    url = url,
                    method = method,
                    headers = headers,
                    body = body,
                )

                val signatureResult = user.generateAuthorizationSignature(
                    payload,
                    serializer<WalletApiPayload<JsonObject>>(),
                )

                signatureResult.fold(
                    onSuccess = { signature ->
                        result.postSuccess(signature)
                    },
                    onFailure = { error ->
                        result.postError(
                            GENERATE_AUTHORIZATION_SIGNATURE_ERROR,
                            error.message,
                            null,
                        )
                    },
                )
            } catch (e: Exception) {
                result.postError(GENERATE_AUTHORIZATION_SIGNATURE_ERROR, e.message, null)
            }
        }
    }

    private fun handleGenerateSignatureFromBytes(
        payload: ByteArray,
        result: MethodChannel.Result,
    ) {
        coroutineScope.launch {
            try {
                val user = PrivyManager.privy.user
                if (user == null) {
                    result.postError(
                        USER_NOT_AUTHENTICATED,
                        "User is not authenticated.",
                        null,
                    )
                    return@launch
                }

                val signatureResult = user.generateAuthorizationSignature(payload)

                signatureResult.fold(
                    onSuccess = { signature ->
                        result.postSuccess(signature)
                    },
                    onFailure = { error ->
                        result.postError(
                            GENERATE_AUTHORIZATION_SIGNATURE_ERROR,
                            error.message,
                            null,
                        )
                    },
                )
            } catch (e: Exception) {
                result.postError(GENERATE_AUTHORIZATION_SIGNATURE_ERROR, e.message, null)
            }
        }
    }
}

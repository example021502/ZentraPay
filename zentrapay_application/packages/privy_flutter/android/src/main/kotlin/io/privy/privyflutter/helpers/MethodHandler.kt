package io.privy.privyflutter.helpers

import io.flutter.plugin.common.MethodChannel

/**
 * Abstract class for handling Flutter method calls.
 * Automatically provides a set of supported methods.
 */
abstract class MethodHandler(
    protected val methods: Set<String>,
) : MethodChannel.MethodCallHandler {

    // Reusable method-checking function
    fun canHandle(method: String): Boolean = methods.contains(method)
}

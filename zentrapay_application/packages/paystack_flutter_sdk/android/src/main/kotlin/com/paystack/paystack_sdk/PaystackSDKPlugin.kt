package com.paystack.paystack_sdk

import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.paystack.android.core.Paystack
import com.paystack.android.ui.paymentsheet.PaymentSheet
import com.paystack.android.ui.paymentsheet.PaymentSheetResult
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.HiddenLifecycleReference
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class PaystackSDKPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private lateinit var paymentSheet: PaymentSheet
  private var activity: FlutterFragmentActivity? = null
  private lateinit var pendingResult: Result

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.paystack.flutter")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    pendingResult = result
    when (call.method) {
      "initialize" -> {
        val publicKey = call.argument<String>("publicKey")
        val enableLogging = call.argument<Boolean>("enableLogging") ?: false
        if (publicKey.isNullOrEmpty()) {
          result.error(
            "INVALID_ARGUMENT",
            "Missing public key",
            null
          )
          return
        }
        initialize(publicKey, enableLogging)
      }
      "launch" -> {
        val accessCode = call.argument<String>("accessCode")
        if(accessCode.isNullOrEmpty()) {
          result.error(
            "INVALID_ARGUMENT",
            "Missing access code",
            null
          )
          return
        }
        launch(accessCode)
      }
      else -> result.notImplemented()
    }
  }

  private fun initialize(publicKey: String, enableLogging: Boolean) {
    try {
      Paystack
        .builder()
        .setPublicKey(publicKey)
        .setLoggingEnabled(enableLogging)
        .build()
      pendingResult.success(true)
    } catch (e: Exception) {
      pendingResult.error(
        "INITIALIZATION_ERROR",
        e.message,
        null
      )
    }
  }

  private fun launch(accessCode: String) {
    if (activity == null) {
      pendingResult.error(
        "MISSING_VIEW",
        "Activity is not found to present payment UI",
        null
      )
      return
    }

    try {
      paymentSheet.launch(accessCode)
    } catch (e: Exception) {
      pendingResult.error("LAUNCH_ERROR", e.message, null)
      return
    }
  }

  private fun paymentComplete(paymentSheetResult: PaymentSheetResult) {
    when (paymentSheetResult) {
      is PaymentSheetResult.Completed -> {
        pendingResult.success(mapOf(
          "status" to "success",
          "message" to "Transaction successful",
          "reference" to paymentSheetResult.paymentCompletionDetails.reference
        ))
      }
      is PaymentSheetResult.Cancelled -> {
        pendingResult.success(mapOf(
          "status" to "cancelled",
          "message" to "Transaction cancelled",
          "reference" to ""
        ))
      }
      is PaymentSheetResult.Failed -> {
        pendingResult.success(mapOf(
          "status" to "failed",
          "message" to paymentSheetResult.error.message,
          "reference" to ""
        ))
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity as FlutterFragmentActivity
    (binding.lifecycle as HiddenLifecycleReference)
      .lifecycle
      .addObserver(LifecycleEventObserver { _, event ->
        if (event == Lifecycle.Event.ON_CREATE) {
          val activity = requireNotNull(activity)
          paymentSheet = PaymentSheet(activity, ::paymentComplete)
        }
      })
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity as FlutterFragmentActivity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}

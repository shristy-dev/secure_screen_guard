package com.securescreenguard.secure_screen_guard

import android.app.Activity
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class SecureScreenGuardPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    private var activity: Activity? = null
    private var eventSink: EventChannel.EventSink? = null

    // Track current mode; used to restore state on activity changes.
    private var isEnabled = false

    // ─── FlutterPlugin ────────────────────────────────────────────────────

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel = MethodChannel(
            binding.binaryMessenger,
            "secure_screen_guard/methods"
        )
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(
            binding.binaryMessenger,
            "secure_screen_guard/events"
        )
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    // ─── ActivityAware ────────────────────────────────────────────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        // Restore flag if it was enabled before an activity recreation.
        if (isEnabled) applyFlag()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        if (isEnabled) applyFlag()
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    // ─── MethodCallHandler ────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "enable" -> {
                isEnabled = true
                applyFlag()
                result.success(null)
            }
            "disable" -> {
                isEnabled = false
                clearFlag()
                result.success(null)
            }
            "setMode" -> {
                val mode = call.argument<String>("mode") ?: "balanced"
                handleMode(mode)
                result.success(null)
            }
            "isProtected" -> result.success(isEnabled)
            // Android cannot natively detect if another app is recording, so always false.
            "isRecording" -> result.success(false)
            else -> result.notImplemented()
        }
    }

    // ─── Helpers ──────────────────────────────────────────────────────────

    private fun applyFlag() {
        activity?.runOnUiThread {
            activity?.window?.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
        }
    }

    private fun clearFlag() {
        activity?.runOnUiThread {
            activity?.window?.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }

    private fun handleMode(mode: String) {
        when (mode) {
            "strict" -> {
                isEnabled = true
                applyFlag()
            }
            "off" -> {
                isEnabled = false
                clearFlag()
            }
            // "balanced" — FLAG_SECURE is controlled per-widget by explicit enable/disable calls.
            else -> {}
        }
    }
}

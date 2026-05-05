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

    private var widgetProtectionEnabled = false
    private var mode: String = "balanced"

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

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        applyProtectionState()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        applyProtectionState()
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "enable" -> {
                widgetProtectionEnabled = true
                applyProtectionState()
                result.success(null)
            }
            "disable" -> {
                widgetProtectionEnabled = false
                applyProtectionState()
                result.success(null)
            }
            "setMode" -> {
                val requestedMode = call.argument<String>("mode") ?: "balanced"
                handleMode(requestedMode)
                result.success(null)
            }
            "isProtected" -> result.success(isCurrentlyProtected())
            "isRecording" -> result.success(false)
            else -> result.notImplemented()
        }
    }

    private fun shouldProtect(): Boolean {
        return when (mode) {
            "strict" -> true
            "off" -> false
            else -> widgetProtectionEnabled
        }
    }

    private fun isCurrentlyProtected(): Boolean {
        val window = activity?.window ?: return false
        val flags = window.attributes.flags
        return (flags and WindowManager.LayoutParams.FLAG_SECURE) != 0
    }

    private fun applyProtectionState() {
        if (shouldProtect()) {
            applyFlag()
        } else {
            clearFlag()
        }
    }

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
        this.mode = mode
        applyProtectionState()
    }

    private fun notifyEvent(name: String) {
        activity?.runOnUiThread {
            eventSink?.success(name)
        }
    }
}

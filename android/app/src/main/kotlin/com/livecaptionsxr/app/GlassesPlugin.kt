package com.livecaptionsxr.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import androidx.xr.projected.ExperimentalProjectedApi
import androidx.xr.projected.ProjectedContext
import androidx.xr.projected.ProjectedDeviceController
import androidx.xr.projected.ProjectedDeviceController.Companion.CAPABILITY_VISUAL_UI
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

/**
 * Flutter plugin for detecting and launching the Samsung XR AI Glasses experience.
 *
 * Provides a MethodChannel interface for Dart code to:
 * - Detect if AI glasses are connected (via Jetpack XR SDK)
 * - Query glasses capabilities (visual UI, etc.)
 * - Launch the native GlassesActivity with projected context
 * - Forward captions to the glasses display via CaptionBridge
 */
@OptIn(ExperimentalProjectedApi::class)
class GlassesPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    companion object {
        private const val TAG = "GlassesPlugin"
        private const val METHOD_CHANNEL = "live_captions_xr/glasses"
    }

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private var activity: Activity? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)
        Log.d(TAG, "GlassesPlugin attached to Flutter engine")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        scope.cancel()
        Log.d(TAG, "GlassesPlugin detached from Flutter engine")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isGlassesAvailable" -> checkGlassesAvailable(result)
            "getGlassesCapabilities" -> getGlassesCapabilities(result)
            "launchGlassesActivity" -> launchGlassesActivity(result)
            "sendCaption" -> {
                val text = call.argument<String>("text") ?: ""
                CaptionBridge.updateCaption(text)
                result.success(true)
            }
            "isGlassesActivityActive" -> {
                result.success(CaptionBridge.isGlassesActivityActive.value)
            }
            "stopGlassesActivity" -> {
                stopGlassesActivity(result)
            }
            else -> result.notImplemented()
        }
    }

    private fun checkGlassesAvailable(result: Result) {
        scope.launch {
            try {
                val isConnected = ProjectedContext.isProjectedDeviceConnected(
                    context,
                    Dispatchers.IO
                ).first()
                Log.d(TAG, "Glasses connected: $isConnected")
                result.success(isConnected)
            } catch (e: Exception) {
                Log.w(TAG, "Jetpack XR SDK not available, glasses not detected", e)
                result.success(false)
            }
        }
    }

    private fun getGlassesCapabilities(result: Result) {
        scope.launch {
            try {
                val deviceController = ProjectedDeviceController.create(context)
                val capabilities = deviceController.capabilities
                val capMap = mapOf(
                    "visualUi" to capabilities.contains(CAPABILITY_VISUAL_UI),
                    "capabilities" to capabilities.toList()
                )
                result.success(capMap)
            } catch (e: Exception) {
                Log.w(TAG, "Failed to get glasses capabilities", e)
                result.success(mapOf("visualUi" to false, "capabilities" to emptyList<String>()))
            }
        }
    }

    private fun launchGlassesActivity(result: Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("NO_ACTIVITY", "No activity available to launch glasses", null)
            return
        }

        try {
            val options = ProjectedContext.createProjectedActivityOptions(currentActivity)
            val intent = Intent(currentActivity, GlassesActivity::class.java)
            currentActivity.startActivity(intent, options.toBundle())
            Log.d(TAG, "GlassesActivity launched with projected options")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch GlassesActivity", e)
            result.error("LAUNCH_FAILED", e.message, null)
        }
    }

    private fun stopGlassesActivity(result: Result) {
        try {
            val intent = Intent("com.livecaptionsxr.app.STOP_GLASSES")
            context.sendBroadcast(intent)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop GlassesActivity", e)
            result.error("STOP_FAILED", e.message, null)
        }
    }
}

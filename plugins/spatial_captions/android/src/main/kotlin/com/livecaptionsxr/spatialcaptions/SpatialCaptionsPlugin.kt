package com.livecaptionsxr.spatialcaptions

import android.app.Activity
import android.content.Context
import android.util.Log
import com.google.ar.sceneform.math.Vector3
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Android implementation of the Spatial Captions plugin. This handles method channel
 * calls from Flutter and forwards them to the AR Sceneform based renderer hosted in
 * [AugmentedCaptionActivity].
 */
class SpatialCaptionsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    ActivityAware {

    private lateinit var channel: MethodChannel
    private var applicationContext: Context? = null
    private var activity: Activity? = null

    private var arCaptionManager: ARCaptionManager? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "spatial_captions")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "addCaption" -> handleAddCaption(call, result)
            "updateCaption" -> handleUpdateCaption(call, result)
            "replaceCaption" -> handleReplaceCaption(call, result)
            "removeCaption" -> handleRemoveCaption(call, result)
            "clearCaptions" -> handleClearCaptions(result)
            "setCaptionDuration" -> handleSetCaptionDuration(call, result)
            "setOrientationLock" -> handleSetOrientationLock(call, result)
            "initializeWithSceneView" -> handleInitialize(result)
            "testConnection" -> handleTestConnection(result)
            else -> result.notImplemented()
        }
    }

    private fun ensureManager(result: MethodChannel.Result): Boolean {
        if (arCaptionManager == null) {
            result.error("NO_MANAGER", "AR view has not been initialized", null)
            return false
        }
        return true
    }

    private fun handleAddCaption(call: MethodCall, result: MethodChannel.Result) {
        if (!ensureManager(result)) return
        val args = call.arguments as? Map<*, *>
        val id = args?.get("id") as? String
        val text = args?.get("text") as? String
        val x = args?.get("x") as? Double
        val y = args?.get("y") as? Double
        val z = args?.get("z") as? Double
        val type = args?.get("type") as? String
        val speakerId = args?.get("speakerId") as? String

        if (id == null || text == null || x == null || y == null || z == null || type == null) {
            result.error("BAD_ARGS", "Invalid arguments for addCaption", null)
            return
        }

        arCaptionManager?.addCaption(
            id = id,
            text = text,
            position = Vector3(x.toFloat(), y.toFloat(), z.toFloat()),
            type = type,
            speakerId = speakerId
        )
        result.success(null)
    }

    private fun handleUpdateCaption(call: MethodCall, result: MethodChannel.Result) {
        if (!ensureManager(result)) return
        val args = call.arguments as? Map<*, *>
        val id = args?.get("id") as? String ?: run {
            result.error("BAD_ARGS", "Caption id required", null); return
        }
        val text = args?.get("text") as? String
        val x = args?.get("x") as? Double
        val y = args?.get("y") as? Double
        val z = args?.get("z") as? Double
        val type = args?.get("type") as? String

        arCaptionManager?.updateCaption(
            id = id,
            text = text,
            position = if (x != null && y != null && z != null) Vector3(x.toFloat(), y.toFloat(), z.toFloat()) else null,
            type = type
        )
        result.success(null)
    }

    private fun handleReplaceCaption(call: MethodCall, result: MethodChannel.Result) {
        if (!ensureManager(result)) return
        val args = call.arguments as? Map<*, *>
        val oldId = args?.get("oldId") as? String
        val newId = args?.get("newId") as? String
        val text = args?.get("text") as? String
        val type = args?.get("type") as? String
        if (oldId == null || newId == null || text == null || type == null) {
            result.error("BAD_ARGS", "Invalid arguments for replaceCaption", null)
            return
        }
        arCaptionManager?.replaceCaption(oldId, newId, text, type)
        result.success(null)
    }

    private fun handleRemoveCaption(call: MethodCall, result: MethodChannel.Result) {
        if (!ensureManager(result)) return
        val args = call.arguments as? Map<*, *>
        val id = args?.get("id") as? String ?: run {
            result.error("BAD_ARGS", "Caption id required", null); return
        }
        arCaptionManager?.removeCaption(id)
        result.success(null)
    }

    private fun handleClearCaptions(result: MethodChannel.Result) {
        if (!ensureManager(result)) return
        arCaptionManager?.clearCaptions()
        result.success(null)
    }

    private fun handleSetCaptionDuration(call: MethodCall, result: MethodChannel.Result) {
        if (!ensureManager(result)) return
        val args = call.arguments as? Map<*, *>
        val seconds = args?.get("seconds") as? Int ?: run {
            result.error("BAD_ARGS", "Duration seconds missing", null); return
        }
        arCaptionManager?.setCaptionDuration(seconds.toLong())
        result.success(null)
    }

    private fun handleSetOrientationLock(call: MethodCall, result: MethodChannel.Result) {
        if (!ensureManager(result)) return
        val args = call.arguments as? Map<*, *>
        val lockLandscape = args?.get("lockLandscape") as? Boolean ?: false
        arCaptionManager?.setOrientationLock(lockLandscape)
        result.success(null)
    }

    private fun handleInitialize(result: MethodChannel.Result) {
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity context not available", null)
            return
        }
        arCaptionManager = ARCaptionManager(activity!!)
        result.success(true)
    }

    private fun handleTestConnection(result: MethodChannel.Result) {
        Log.d(TAG, "SpatialCaptionsPlugin testConnection invoked")
        result.success("android_connected")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    companion object {
        const val TAG = "SpatialCaptionsPlugin"
    }
}
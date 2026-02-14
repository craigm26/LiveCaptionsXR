package com.livecaptionsxr.spatial_captions

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Android stub for the spatial_captions plugin.
 * On Android, spatial captions are rendered in the Flutter UI layer
 * (not via native ARKit like iOS), so this plugin returns no-op success
 * responses to prevent MissingPluginException crashes.
 */
class SpatialCaptionsPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "spatial_captions")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initializeWithSceneView" -> {
                // Android doesn't use ARKit SceneView — return true so Dart side continues
                result.success(true)
            }
            "addCaption" -> result.success(null)
            "updateCaption" -> result.success(null)
            "replaceCaption" -> result.success(null)
            "removeCaption" -> result.success(null)
            "clearCaptions" -> result.success(null)
            "setCaptionDuration" -> result.success(null)
            "setOrientationLock" -> result.success(null)
            "testConnection" -> result.success("Android spatial_captions stub — captions rendered in Flutter UI")
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

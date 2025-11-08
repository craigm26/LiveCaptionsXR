package com.livecaptionsxr.app

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

/**
 * Lightweight plugin that exposes the `live_captions_xr/ar_anchor_methods`
 * channel on Android so the shared Dart [ARAnchorManager] can talk to a
 * consistent platform API even when full ARCore support is unavailable.
 *
 * For now we return stubbed data so the rest of the pipeline can continue
 * to operate in 2D mode on devices (or emulators) without AR support.
 */
class ArAnchorPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getDeviceOrientation" -> result.success(identityMatrix())
            "createAnchorAtAngle",
            "createAnchorAtWorldTransform" -> {
                val anchorId = "android_anchor_${UUID.randomUUID()}"
                result.success(anchorId)
            }
            "removeAnchor" -> result.success(null)
            else -> result.notImplemented()
        }
    }

    private fun identityMatrix(): List<Double> = listOf(
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
    )

    companion object {
        private const val CHANNEL_NAME = "live_captions_xr/ar_anchor_methods"
    }
}

package com.example.aurasense

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import com.google.ar.core.Anchor
import com.google.ar.core.Pose

class VisualObjectPlugin : MethodChannel.MethodCallHandler {
    companion object {
        private var channel: MethodChannel? = null

        fun registerWith(registrar: PluginRegistry.Registrar) {
            channel = MethodChannel(registrar.messenger(), "live_captions_xr/visual_object_methods")
            val instance = VisualObjectPlugin()
            channel?.setMethodCallHandler(instance)
        }

        // Example: Call this when you detect an Anchor or object
        fun sendVisualObjectDetected(anchor: Anchor, label: String, confidence: Double, boundingBox: List<Double>) {
            val pose: Pose = anchor.pose
            val matrix = FloatArray(16)
            pose.toMatrix(matrix, 0)
            val arr = matrix.map { it.toDouble() }
            val args = mapOf(
                "label" to label,
                "confidence" to confidence,
                "boundingBox" to boundingBox, // [left, top, right, bottom]
                "worldTransform" to arr
            )
            channel?.invokeMethod("onVisualObjectDetected", args)
        }
    }

    // No-op: Dart->native calls not needed for this plugin
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        result.notImplemented()
    }
} 
package com.example.aurasense

import android.app.Activity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import com.google.ar.core.Anchor
import com.google.ar.core.Session
import com.google.ar.core.Pose

class ARAnchorManager(private val activity: Activity) : MethodChannel.MethodCallHandler {
    companion object {
        private var arSession: Session? = null
        private val anchorMap = mutableMapOf<String, Anchor>()

        fun registerWith(registrar: PluginRegistry.Registrar) {
            val channel = MethodChannel(registrar.messenger(), "live_captions_xr/ar_anchor_methods")
            val instance = ARAnchorManager(registrar.activity())
            channel.setMethodCallHandler(instance)
        }

        fun setARSession(session: Session) {
            arSession = session
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "createAnchorAtAngle" -> {
                val angle = call.argument<Double>("angle") ?: 0.0
                val distance = call.argument<Double>("distance") ?: 2.0
                val session = arSession
                if (session == null) {
                    result.error("NO_SESSION", "ARCore session not set", null)
                    return
                }
                // The camera pose is IMU-fused and updated in real time by ARCore.
                // Use it as the base for all anchor placement to ensure world-accurate positioning.
                // TODO: Get camera pose from your AR renderer
                // val cameraPose = session.camera.pose
                // For stub, use identity pose
                val cameraPose = Pose.IDENTITY
                val yRotation = Pose.makeRotation(0f, 1f, 0f, angle.toFloat())
                val translation = floatArrayOf(0f, 0f, -distance.toFloat())
                val anchorPose = cameraPose.compose(yRotation).compose(Pose(translation, floatArrayOf(0f, 0f, 0f, 1f)))
                val anchor = session.createAnchor(anchorPose)
                val id = anchor.hashCode().toString()
                anchorMap[id] = anchor
                result.success(id)
            }
            "createAnchorAtWorldTransform" -> {
                val transform = call.argument<List<Double>>("transform")
                val session = arSession
                if (session == null || transform == null || transform.size != 16) {
                    result.error("INVALID_ARGUMENTS", "Missing or invalid transform/session", null)
                    return
                }
                val matrix = FloatArray(16) { i -> transform[i].toFloat() }
                val pose = Pose(matrix, 0)
                val anchor = session.createAnchor(pose)
                val id = anchor.hashCode().toString()
                anchorMap[id] = anchor
                result.success(id)
            }
            "removeAnchor" -> {
                val identifier = call.argument<String>("identifier")
                val anchor = anchorMap[identifier]
                if (anchor != null) {
                    anchor.detach()
                    anchorMap.remove(identifier)
                }
                result.success(null)
            }
            "getDeviceOrientation" -> {
                // Diagnostic: Return the current device orientation as a flat 16-element array (row-major)
                val session = arSession
                // TODO: Get camera pose from your AR renderer (e.g., arSceneView.arFrame.camera.pose)
                // For stub, use identity pose
                val pose = Pose.IDENTITY
                val matrix = FloatArray(16)
                pose.toMatrix(matrix, 0)
                // Return as List<Double> for Dart
                result.success(matrix.map { it.toDouble() })
            }
            else -> result.notImplemented()
        }
    }
} 
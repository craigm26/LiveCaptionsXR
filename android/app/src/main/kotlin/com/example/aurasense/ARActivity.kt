package com.example.aurasense

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.google.ar.core.Anchor
import com.google.ar.core.Frame
import com.google.ar.core.Session
import io.flutter.plugin.common.MethodChannel

class ARActivity : AppCompatActivity() {
    private var arSession: Session? = null
    private var captionChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // TODO: Set up ARCore session and rendering
        arSession = Session(this)
        // Set up MethodChannel for captions
        captionChannel = MethodChannel((application as io.flutter.app.FlutterApplication).flutterEngine?.dartExecutor, "live_captions_xr/caption_methods")
        captionChannel?.setMethodCallHandler { call, result ->
            if (call.method == "placeCaption") {
                val args = call.arguments as? Map<*, *>
                val transform = (args?.get("transform") as? List<*>)?.mapNotNull { (it as? Double) }
                val text = args?.get("text") as? String
                if (transform != null && text != null && transform.size == 16) {
                    placeCaption(transform, text)
                    result.success(null)
                } else {
                    result.error("BAD_ARGS", "Invalid arguments", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    // Example frame update method (should be called every frame)
    fun onFrame(frame: Frame) {
        // Iterate over all anchors
        for (anchor in frame.updatedAnchors) {
            val label = "ARAnchor"
            val confidence = 0.9
            val boundingBox = listOf(0.0, 0.0, 100.0, 100.0) // TODO: Use real bounding box if available
            VisualObjectPlugin.sendVisualObjectDetected(anchor, label, confidence, boundingBox)
        }
    }

    fun placeCaption(transform: List<Double>, text: String) {
        val session = arSession ?: return
        if (transform.size != 16) return
        val matrix = FloatArray(16) { i -> transform[i].toFloat() }
        val pose = com.google.ar.core.Pose(matrix, 0)
        val anchor = session.createAnchor(pose)
        // TODO: Render the caption text at this anchor in your AR renderer
    }

    // TODO: Integrate with ARCore rendering and real detection logic
} 
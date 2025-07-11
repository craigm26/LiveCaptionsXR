package com.example.live_captions_xr

import android.Manifest
import android.content.pm.PackageManager
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.plugins.shim.ShimPluginRegistry

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.craig.livecaptions/visual"
    private lateinit var channel: MethodChannel
    private lateinit var hybridLocalizationEngine: com.example.live_captions_xr.HybridLocalizationEngine

    private val CAMERA_PERMISSION_REQUEST_CODE = 100

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // Register the stereo audio capture plugin
        flutterEngine.plugins.add(StereoAudioCapturePlugin())

        // Register the speech localizer plugin
        // SpeechLocalizerPlugin.registerWith(io.flutter.plugin.common.PluginRegistry.PluginRegistrar { this })

        // Register the AR anchor manager plugin for ARCore integration
        // ARAnchorManager.registerWith(this)
        // TODO: Migrate custom plugins to the new FlutterPlugin API if needed.
        // TODO: Set the ARCore session from your AR renderer:
        // ARAnchorManager.setARSession(yourArCoreSession)

        val hybridChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "live_captions_xr/hybrid_localization_methods")
        hybridLocalizationEngine = com.example.live_captions_xr.HybridLocalizationEngine()
        hybridChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "predict" -> {
                    hybridLocalizationEngine.predict()
                    result.success(null)
                }
                "updateWithAudioMeasurement" -> {
                    val args = call.arguments as? Map<*, *>
                    val angle = (args?.get("angle") as? Double)?.toFloat()
                    val confidence = (args?.get("confidence") as? Double)?.toFloat()
                    val deviceTransform = (args?.get("deviceTransform") as? List<*>)?.mapNotNull { (it as? Double)?.toFloat() }?.toFloatArray()
                    if (angle != null && confidence != null && deviceTransform != null && deviceTransform.size == 16) {
                        hybridLocalizationEngine.updateWithAudioMeasurement(angle, confidence, deviceTransform)
                        result.success(null)
                    } else {
                        result.error("BAD_ARGS", "Invalid arguments for updateWithAudioMeasurement", null)
                    }
                }
                "updateWithVisualMeasurement" -> {
                    val args = call.arguments as? Map<*, *>
                    val transform = (args?.get("transform") as? List<*>)?.mapNotNull { (it as? Double)?.toFloat() }?.toFloatArray()
                    val confidence = (args?.get("confidence") as? Double)?.toFloat()
                    if (transform != null && confidence != null && transform.size == 16) {
                        hybridLocalizationEngine.updateWithVisualMeasurement(transform, confidence)
                        result.success(null)
                    } else {
                        result.error("BAD_ARGS", "Invalid arguments for updateWithVisualMeasurement", null)
                    }
                }
                "getFusedTransform" -> {
                    val tf = hybridLocalizationEngine.fusedTransform
                    // Return as List<Double> (row-major)
                    val arr = tf.map { it.toDouble() }
                    result.success(arr)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startDetection" -> {
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
                        == PackageManager.PERMISSION_GRANTED) {
                        result.success(null)
                    } else {
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.CAMERA),
                            CAMERA_PERMISSION_REQUEST_CODE
                        )
                        result.error("CAMERA_PERMISSION_DENIED", "Camera permission is required.", null)
                    }
                }
                "stopDetection" -> {
                    result.success(null)
                }
                "captureFrame" -> {
                    // The captureFrame method is not implemented in the new VisualSpeakerIdentifier
                    // as the analysis is now done in a stream.
                    // This will need to be re-implemented if still required.
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (requestCode == CAMERA_PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            }
        }
    }
}

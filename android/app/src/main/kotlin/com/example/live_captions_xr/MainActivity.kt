package com.example.live_captions_xr

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val VISUAL_CHANNEL = "com.craig.livecaptions/visual"
    private val HYBRID_CHANNEL = "live_captions_xr/hybrid_localization_methods"

    private lateinit var visualCaptureController: VisualCaptureController
    private lateinit var hybridLocalizationEngine: HybridLocalizationEngine

    private val CAMERA_PERMISSION_REQUEST_CODE = 100
    private var cameraInitialized = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        visualCaptureController = VisualCaptureController(applicationContext)
        hybridLocalizationEngine = HybridLocalizationEngine()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register the stereo audio capture plugin
        flutterEngine.plugins.add(StereoAudioCapturePlugin())

        // Visual Capture Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VISUAL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "captureVisualSnapshot" -> {
                    if (cameraInitialized) {
                        visualCaptureController.captureSnapshot(result)
                    } else {
                        result.error("CAMERA_NOT_READY", "Camera not initialized or permission denied.", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Hybrid Localization Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, HYBRID_CHANNEL).setMethodCallHandler { call, result ->
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
    }

    private fun initializeCamera() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            visualCaptureController.initialize { success, message ->
                if (success) {
                    cameraInitialized = true
                    Log.d("MainActivity", "Camera initialized successfully.")
                } else {
                    cameraInitialized = false
                    Log.e("MainActivity", "Camera initialization failed: $message")
                }
            }
        } else {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CAMERA), CAMERA_PERMISSION_REQUEST_CODE)
        }
    }

    override fun onResume() {
        super.onResume()
        initializeCamera()
    }

    override fun onPause() {
        super.onPause()
        visualCaptureController.release()
        cameraInitialized = false
    }

    override fun onDestroy() {
        super.onDestroy()
        visualCaptureController.close()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CAMERA_PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                initializeCamera()
            } else {
                Log.e("MainActivity", "Camera permission was denied.")
            }
        }
    }
}

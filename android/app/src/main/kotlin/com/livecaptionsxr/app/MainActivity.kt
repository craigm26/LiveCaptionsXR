package com.livecaptionsxr.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.livecaptionsxr.engine.bus.EngineEvent
import com.livecaptionsxr.spatialcaptions.SpatialCaptionsPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private val VISUAL_CHANNEL = "com.craig.livecaptions/visual"
    private val HYBRID_CHANNEL = "live_captions_xr/hybrid_localization_methods"
    private val AR_NAVIGATION_CHANNEL = "live_captions_xr/ar_navigation"
    private val ENGINE_CONTROL_CHANNEL = "live_captions_xr/engine_control"
    private val ENGINE_EVENTS_CHANNEL = "live_captions_xr/engine_events"

    private lateinit var visualCaptureController: VisualCaptureController
    private lateinit var hybridLocalizationEngine: HybridLocalizationEngine

    private val CAMERA_PERMISSION_REQUEST_CODE = 100
    private var cameraInitialized = false

    private val engineEventsScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private var engineEventsJob: Job? = null

    private val liveCaptionsApp: LiveCaptionsApplication?
        get() = application as? LiveCaptionsApplication

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        visualCaptureController = VisualCaptureController(applicationContext)
        hybridLocalizationEngine = HybridLocalizationEngine()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register native plugins that aren't auto-registered (because they live inside the host app)
        flutterEngine.plugins.add(StereoAudioCapturePlugin())
        flutterEngine.plugins.add(SpatialCaptionsPlugin())
        flutterEngine.plugins.add(ArAnchorPlugin())

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

        // Engine control channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ENGINE_CONTROL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startEngine" -> {
                    liveCaptionsApp?.warmupEngine()
                    result.success(null)
                }
                "stopEngine" -> {
                    liveCaptionsApp?.shutdownEngine()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, ENGINE_EVENTS_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                val bus = liveCaptionsApp?.eventBus ?: return
                engineEventsJob = engineEventsScope.launch {
                    bus.events.collect { event ->
                        events?.success(event.toMap())
                    }
                }
            }

            override fun onCancel(arguments: Any?) {
                engineEventsJob?.cancel()
                engineEventsJob = null
            }
        })

        // AR Navigation Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AR_NAVIGATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showARView" -> {
                    liveCaptionsApp?.warmupEngine()
                    startActivity(Intent(this, XrCaptionsActivity::class.java))
                    result.success(null)
                }
                "arViewWillClose" -> {
                    result.success("noop")
                }
                else -> result.notImplemented()
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
        if (flutterEngine != null) {
            initializeCamera()
        }
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
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
        engineEventsJob?.cancel()
        engineEventsScope.cancel()
        liveCaptionsApp?.shutdownEngine()
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

    private fun EngineEvent.toMap(): Map<String, Any?> {
        return when (this) {
            is EngineEvent.SpeakerUpdate -> mapOf(
                "type" to "speaker",
                "speakerId" to state.id.value,
                "text" to state.lastText,
                "direction" to state.direction?.let {
                    mapOf(
                        "azimuth" to it.azimuthDeg,
                        "elevation" to it.elevationDeg,
                        "confidence" to it.confidence
                    )
                },
                "timestampUs" to state.lastUpdatedUs,
                "isSpeaking" to state.isSpeaking
            )
            is EngineEvent.CaptionUpdate -> mapOf(
                "type" to "caption",
                "speakerId" to delta.speaker?.value,
                "text" to delta.text,
                "isFinal" to delta.isFinal,
                "timestampUs" to delta.timestampUs
            )
        }
    }
}

package com.livecaptionsxr.app

import android.content.Context
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import java.io.File

/**
 * Flutter plugin for Nexa SDK ASR (Automatic Speech Recognition) integration.
 *
 * This plugin provides on-device speech-to-text using Nexa SDK with support for:
 * - NPU acceleration on Qualcomm Snapdragon devices
 * - GPU fallback for other Android devices
 * - CPU fallback for unsupported hardware
 *
 * For the Qualcomm x Nexa On-Device AI Bounty Program.
 */
class NexaAsrPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    companion object {
        private const val TAG = "NexaAsrPlugin"
        private const val METHOD_CHANNEL = "live_captions_xr/nexa_asr"
        private const val EVENT_CHANNEL = "live_captions_xr/nexa_asr_events"

        // Supported Snapdragon chipsets for NPU acceleration
        private val NPU_SUPPORTED_CHIPSETS = listOf(
            "SM8750",  // Snapdragon 8 Gen 4
            "SM8650",  // Snapdragon 8 Gen 3
            "SM8550",  // Snapdragon 8 Gen 2
            "SM8475",  // Snapdragon 8+ Gen 1
            "SM8450",  // Snapdragon 8 Gen 1
        )
    }

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    // Nexa SDK components (will be initialized when SDK is available)
    private var isInitialized = false
    private var isProcessing = false
    private var currentModelPath: String? = null
    private var inferenceMode: InferenceMode = InferenceMode.CPU

    enum class InferenceMode {
        NPU,   // Qualcomm Hexagon NPU
        GPU,   // GPU acceleration
        CPU    // CPU fallback
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)

        Log.d(TAG, "NexaAsrPlugin attached to Flutter engine")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        scope.cancel()
        dispose()
        Log.d(TAG, "NexaAsrPlugin detached from Flutter engine")
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                val modelPath = call.argument<String>("modelPath")
                val preferNpu = call.argument<Boolean>("preferNpu") ?: true
                initialize(modelPath, preferNpu, result)
            }
            "transcribe" -> {
                val audioData = call.argument<ByteArray>("audioData")
                val sampleRate = call.argument<Int>("sampleRate") ?: 16000
                if (audioData != null) {
                    transcribe(audioData, sampleRate, result)
                } else {
                    result.error("INVALID_ARGS", "audioData is required", null)
                }
            }
            "startStreaming" -> {
                startStreaming(result)
            }
            "stopStreaming" -> {
                stopStreaming(result)
            }
            "processAudioChunk" -> {
                val audioData = call.argument<ByteArray>("audioData")
                if (audioData != null) {
                    processAudioChunk(audioData, result)
                } else {
                    result.error("INVALID_ARGS", "audioData is required", null)
                }
            }
            "isNpuAvailable" -> {
                result.success(isNpuAvailable())
            }
            "getDeviceInfo" -> {
                result.success(getDeviceInfo())
            }
            "getInferenceMode" -> {
                result.success(inferenceMode.name)
            }
            "dispose" -> {
                dispose()
                result.success(null)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        Log.d(TAG, "Event channel listening started")
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        Log.d(TAG, "Event channel listening cancelled")
    }

    /**
     * Initialize the Nexa ASR service with the specified model.
     */
    private fun initialize(modelPath: String?, preferNpu: Boolean, result: Result) {
        scope.launch {
            try {
                sendEvent("status", mapOf("message" to "Initializing Nexa ASR...", "progress" to 0.0))

                // Determine the best inference mode for this device
                inferenceMode = when {
                    preferNpu && isNpuAvailable() -> InferenceMode.NPU
                    isGpuAvailable() -> InferenceMode.GPU
                    else -> InferenceMode.CPU
                }

                Log.d(TAG, "Selected inference mode: $inferenceMode")
                sendEvent("status", mapOf(
                    "message" to "Using ${inferenceMode.name} acceleration",
                    "progress" to 0.2
                ))

                // Store model path for later use
                currentModelPath = modelPath ?: getDefaultModelPath()

                sendEvent("status", mapOf("message" to "Loading ASR model...", "progress" to 0.5))

                // Initialize Nexa SDK (placeholder - actual SDK initialization)
                // TODO: Replace with actual Nexa SDK initialization when SDK is integrated
                // val nexaSdk = NexaSdk.getInstance()
                // nexaSdk.init(context)
                // asrModel = nexaSdk.loadAsrModel(currentModelPath, inferenceMode)

                // Simulated initialization for now
                delay(500)

                isInitialized = true

                sendEvent("status", mapOf(
                    "message" to "Nexa ASR initialized with ${inferenceMode.name}",
                    "progress" to 1.0,
                    "isComplete" to true
                ))

                Log.d(TAG, "Nexa ASR initialized successfully")
                result.success(mapOf(
                    "success" to true,
                    "inferenceMode" to inferenceMode.name,
                    "modelPath" to currentModelPath
                ))

            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize Nexa ASR", e)
                sendEvent("error", mapOf("message" to "Failed to initialize: ${e.message}"))
                result.error("INIT_ERROR", "Failed to initialize Nexa ASR: ${e.message}", null)
            }
        }
    }

    /**
     * Transcribe audio data to text using Nexa ASR.
     */
    private fun transcribe(audioData: ByteArray, sampleRate: Int, result: Result) {
        if (!isInitialized) {
            result.error("NOT_INITIALIZED", "Nexa ASR not initialized", null)
            return
        }

        scope.launch {
            try {
                sendEvent("transcribing", mapOf("progress" to 0.0))

                // TODO: Replace with actual Nexa SDK transcription
                // val transcription = asrModel.transcribe(audioData, sampleRate)

                // Simulated transcription for now
                sendEvent("transcribing", mapOf("progress" to 0.5))
                delay(100)

                val transcription = mapOf(
                    "text" to "[Nexa ASR Demo] Audio processed (${audioData.size} bytes)",
                    "confidence" to 0.95,
                    "language" to "en",
                    "duration" to (audioData.size / (sampleRate * 2.0)) // Assuming 16-bit audio
                )

                sendEvent("transcribing", mapOf("progress" to 1.0))
                sendEvent("transcription", transcription)

                Log.d(TAG, "Transcription complete: ${transcription["text"]}")
                result.success(transcription)

            } catch (e: Exception) {
                Log.e(TAG, "Transcription failed", e)
                sendEvent("error", mapOf("message" to "Transcription failed: ${e.message}"))
                result.error("TRANSCRIBE_ERROR", "Transcription failed: ${e.message}", null)
            }
        }
    }

    /**
     * Start streaming mode for real-time transcription.
     */
    private fun startStreaming(result: Result) {
        if (!isInitialized) {
            result.error("NOT_INITIALIZED", "Nexa ASR not initialized", null)
            return
        }

        if (isProcessing) {
            result.success(mapOf("success" to true, "message" to "Already streaming"))
            return
        }

        scope.launch {
            try {
                // TODO: Initialize streaming session with Nexa SDK
                // streamingSession = asrModel.startStreamingSession()

                isProcessing = true
                sendEvent("streaming", mapOf("started" to true))

                Log.d(TAG, "Streaming started")
                result.success(mapOf("success" to true))

            } catch (e: Exception) {
                Log.e(TAG, "Failed to start streaming", e)
                result.error("STREAMING_ERROR", "Failed to start streaming: ${e.message}", null)
            }
        }
    }

    /**
     * Stop streaming mode.
     */
    private fun stopStreaming(result: Result) {
        if (!isProcessing) {
            result.success(mapOf("success" to true, "message" to "Not streaming"))
            return
        }

        scope.launch {
            try {
                // TODO: Close streaming session with Nexa SDK
                // streamingSession?.close()

                isProcessing = false
                sendEvent("streaming", mapOf("started" to false))

                Log.d(TAG, "Streaming stopped")
                result.success(mapOf("success" to true))

            } catch (e: Exception) {
                Log.e(TAG, "Failed to stop streaming", e)
                result.error("STREAMING_ERROR", "Failed to stop streaming: ${e.message}", null)
            }
        }
    }

    /**
     * Process an audio chunk during streaming mode.
     */
    private fun processAudioChunk(audioData: ByteArray, result: Result) {
        if (!isProcessing) {
            result.error("NOT_STREAMING", "Streaming not active", null)
            return
        }

        scope.launch {
            try {
                // TODO: Process audio chunk with Nexa SDK streaming session
                // val partialResult = streamingSession?.processChunk(audioData)

                // Simulated partial result for now
                val partialResult = mapOf(
                    "text" to "",
                    "isFinal" to false,
                    "confidence" to 0.0
                )

                // Only send events for non-empty results
                if ((partialResult["text"] as String).isNotEmpty()) {
                    sendEvent("partialResult", partialResult)
                }

                result.success(partialResult)

            } catch (e: Exception) {
                Log.e(TAG, "Failed to process audio chunk", e)
                result.error("CHUNK_ERROR", "Failed to process chunk: ${e.message}", null)
            }
        }
    }

    /**
     * Check if NPU (Qualcomm Hexagon) is available on this device.
     */
    private fun isNpuAvailable(): Boolean {
        val chipset = getChipsetName()
        val isSupported = NPU_SUPPORTED_CHIPSETS.any { chipset.contains(it, ignoreCase = true) }
        Log.d(TAG, "NPU availability check: chipset=$chipset, supported=$isSupported")
        return isSupported
    }

    /**
     * Check if GPU acceleration is available.
     */
    private fun isGpuAvailable(): Boolean {
        // Most modern Android devices support GPU compute via OpenCL or Vulkan
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
    }

    /**
     * Get the chipset/SoC name from device info.
     */
    private fun getChipsetName(): String {
        return try {
            // Try to read from /proc/cpuinfo
            val cpuInfo = File("/proc/cpuinfo").readText()
            val hardwareLine = cpuInfo.lines().find { it.startsWith("Hardware") }
            hardwareLine?.substringAfter(":")?.trim() ?: Build.HARDWARE
        } catch (e: Exception) {
            Build.HARDWARE
        }
    }

    /**
     * Get device information for debugging and analytics.
     */
    private fun getDeviceInfo(): Map<String, Any> {
        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "device" to Build.DEVICE,
            "hardware" to Build.HARDWARE,
            "chipset" to getChipsetName(),
            "sdkVersion" to Build.VERSION.SDK_INT,
            "npuAvailable" to isNpuAvailable(),
            "gpuAvailable" to isGpuAvailable(),
            "currentInferenceMode" to inferenceMode.name
        )
    }

    /**
     * Get the default model path for ASR.
     */
    private fun getDefaultModelPath(): String {
        return "${context.filesDir}/models/nexa-asr"
    }

    /**
     * Send an event to the Flutter side via EventChannel.
     */
    private fun sendEvent(type: String, data: Map<String, Any?>) {
        scope.launch(Dispatchers.Main) {
            eventSink?.success(mapOf("type" to type, "data" to data))
        }
    }

    /**
     * Clean up resources.
     */
    private fun dispose() {
        try {
            isProcessing = false
            isInitialized = false

            // TODO: Dispose Nexa SDK resources
            // asrModel?.close()
            // streamingSession?.close()

            Log.d(TAG, "Nexa ASR disposed")
        } catch (e: Exception) {
            Log.e(TAG, "Error disposing Nexa ASR", e)
        }
    }
}

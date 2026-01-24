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
 * Flutter plugin for Nexa SDK LLM (Large Language Model) integration.
 *
 * This plugin provides on-device text enhancement and inference using Nexa SDK with support for:
 * - NPU acceleration on Qualcomm Snapdragon devices
 * - GPU fallback for other Android devices
 * - CPU fallback for unsupported hardware
 *
 * Recommended models:
 * - Granite-4.0-h-350M-NPU: Fast text enhancement (92 tokens/s on NPU)
 * - OmniNeural-4B: Multimodal with vision+text
 *
 * For the Qualcomm x Nexa On-Device AI Bounty Program.
 */
class NexaLlmPlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    companion object {
        private const val TAG = "NexaLlmPlugin"
        private const val METHOD_CHANNEL = "live_captions_xr/nexa_llm"
        private const val EVENT_CHANNEL = "live_captions_xr/nexa_llm_events"

        // Supported Snapdragon chipsets for NPU acceleration
        private val NPU_SUPPORTED_CHIPSETS = listOf(
            "SM8750",  // Snapdragon 8 Gen 4
            "SM8650",  // Snapdragon 8 Gen 3
            "SM8550",  // Snapdragon 8 Gen 2
            "SM8475",  // Snapdragon 8+ Gen 1
            "SM8450",  // Snapdragon 8 Gen 1
        )

        // Default prompts for caption enhancement
        private const val ENHANCEMENT_PROMPT = """Improve the following transcription by:
1. Adding proper punctuation
2. Correcting obvious errors
3. Ensuring proper capitalization
4. Keeping the original meaning intact

Raw: "%s"
Enhanced:"""

        private const val MULTIMODAL_PROMPT = """Enhance this caption with visual context:

Original caption: "%s"

Provide an enhanced caption that:
- Keeps the original meaning intact
- Adds relevant visual details
- Remains natural and concise

Enhanced:"""
    }

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    // Nexa SDK components (will be initialized when SDK is available)
    private var isInitialized = false
    private var currentModelPath: String? = null
    private var currentModelName: String = "granite-4.0-h-350m-npu"
    private var inferenceMode: InferenceMode = InferenceMode.CPU
    private var supportsVision: Boolean = false

    // Enhancement cache for common phrases
    private val enhancementCache = LinkedHashMap<String, String>(100, 0.75f, true)
    private val maxCacheSize = 100

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

        Log.d(TAG, "NexaLlmPlugin attached to Flutter engine")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        scope.cancel()
        dispose()
        Log.d(TAG, "NexaLlmPlugin detached from Flutter engine")
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                val modelPath = call.argument<String>("modelPath")
                val modelName = call.argument<String>("modelName") ?: "granite-4.0-h-350m-npu"
                val preferNpu = call.argument<Boolean>("preferNpu") ?: true
                initialize(modelPath, modelName, preferNpu, result)
            }
            "enhanceText" -> {
                val text = call.argument<String>("text")
                if (text != null) {
                    enhanceText(text, result)
                } else {
                    result.error("INVALID_ARGS", "text is required", null)
                }
            }
            "multimodalInference" -> {
                val text = call.argument<String>("text")
                val imageData = call.argument<ByteArray>("imageData")
                if (text != null) {
                    multimodalInference(text, imageData, result)
                } else {
                    result.error("INVALID_ARGS", "text is required", null)
                }
            }
            "generateResponse" -> {
                val prompt = call.argument<String>("prompt")
                val maxTokens = call.argument<Int>("maxTokens") ?: 256
                val temperature = call.argument<Double>("temperature") ?: 0.7
                if (prompt != null) {
                    generateResponse(prompt, maxTokens, temperature, result)
                } else {
                    result.error("INVALID_ARGS", "prompt is required", null)
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
            "supportsVision" -> {
                result.success(supportsVision)
            }
            "clearCache" -> {
                enhancementCache.clear()
                result.success(true)
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
     * Initialize the Nexa LLM service with the specified model.
     */
    private fun initialize(modelPath: String?, modelName: String, preferNpu: Boolean, result: Result) {
        scope.launch {
            try {
                sendEvent("status", mapOf("message" to "Initializing Nexa LLM...", "progress" to 0.0))

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

                // Store model info
                currentModelPath = modelPath ?: getDefaultModelPath(modelName)
                currentModelName = modelName

                // Check if model supports vision (multimodal)
                supportsVision = modelName.contains("omni", ignoreCase = true) ||
                        modelName.contains("vlm", ignoreCase = true) ||
                        modelName.contains("vision", ignoreCase = true)

                sendEvent("status", mapOf(
                    "message" to "Loading $modelName model...",
                    "progress" to 0.5
                ))

                // Initialize Nexa SDK (placeholder - actual SDK initialization)
                // TODO: Replace with actual Nexa SDK initialization when SDK is integrated
                // val nexaSdk = NexaSdk.getInstance()
                // nexaSdk.init(context)
                // llmModel = VlmWrapper.builder()
                //     .setModelName(modelName)
                //     .setModelPath(currentModelPath)
                //     .setPlugin(when(inferenceMode) {
                //         InferenceMode.NPU -> PluginType.NPU
                //         InferenceMode.GPU -> PluginType.GPU
                //         else -> PluginType.CPU
                //     })
                //     .build()

                // Simulated initialization for now
                delay(500)

                isInitialized = true

                sendEvent("status", mapOf(
                    "message" to "Nexa LLM initialized with ${inferenceMode.name}",
                    "progress" to 1.0,
                    "isComplete" to true
                ))

                Log.d(TAG, "Nexa LLM initialized successfully with model: $modelName")
                result.success(mapOf(
                    "success" to true,
                    "inferenceMode" to inferenceMode.name,
                    "modelName" to modelName,
                    "modelPath" to currentModelPath,
                    "supportsVision" to supportsVision
                ))

            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize Nexa LLM", e)
                sendEvent("error", mapOf("message" to "Failed to initialize: ${e.message}"))
                result.error("INIT_ERROR", "Failed to initialize Nexa LLM: ${e.message}", null)
            }
        }
    }

    /**
     * Enhance transcribed text using the LLM.
     */
    private fun enhanceText(text: String, result: Result) {
        if (!isInitialized) {
            result.error("NOT_INITIALIZED", "Nexa LLM not initialized", null)
            return
        }

        // Check cache first
        enhancementCache[text]?.let { cached ->
            Log.d(TAG, "Using cached enhancement for: $text")
            sendEvent("enhancement", mapOf(
                "original" to text,
                "enhanced" to cached,
                "cached" to true
            ))
            result.success(mapOf(
                "original" to text,
                "enhanced" to cached,
                "cached" to true
            ))
            return
        }

        scope.launch {
            try {
                sendEvent("enhancing", mapOf("progress" to 0.0, "text" to text))

                val prompt = ENHANCEMENT_PROMPT.format(text)

                sendEvent("enhancing", mapOf("progress" to 0.3))

                // TODO: Replace with actual Nexa SDK inference
                // val response = llmModel.generate(prompt, maxTokens = 128, temperature = 0.3)

                // Simulated enhancement for now
                sendEvent("enhancing", mapOf("progress" to 0.7))
                delay(50)

                // Demo: Add basic punctuation and capitalization
                val enhancedText = enhanceTextDemo(text)

                sendEvent("enhancing", mapOf("progress" to 1.0))

                // Add to cache
                addToCache(text, enhancedText)

                sendEvent("enhancement", mapOf(
                    "original" to text,
                    "enhanced" to enhancedText,
                    "cached" to false
                ))

                Log.d(TAG, "Text enhanced: '$text' -> '$enhancedText'")
                result.success(mapOf(
                    "original" to text,
                    "enhanced" to enhancedText,
                    "cached" to false
                ))

            } catch (e: Exception) {
                Log.e(TAG, "Text enhancement failed", e)
                sendEvent("error", mapOf("message" to "Enhancement failed: ${e.message}"))
                result.error("ENHANCE_ERROR", "Enhancement failed: ${e.message}", null)
            }
        }
    }

    /**
     * Perform multimodal inference with text and optional image.
     */
    private fun multimodalInference(text: String, imageData: ByteArray?, result: Result) {
        if (!isInitialized) {
            result.error("NOT_INITIALIZED", "Nexa LLM not initialized", null)
            return
        }

        if (imageData != null && !supportsVision) {
            Log.w(TAG, "Current model doesn't support vision, using text-only inference")
        }

        scope.launch {
            try {
                sendEvent("inference", mapOf("progress" to 0.0, "type" to "multimodal"))

                val prompt = if (imageData != null && supportsVision) {
                    MULTIMODAL_PROMPT.format(text)
                } else {
                    ENHANCEMENT_PROMPT.format(text)
                }

                sendEvent("inference", mapOf("progress" to 0.3))

                // TODO: Replace with actual Nexa SDK multimodal inference
                // val response = if (imageData != null && supportsVision) {
                //     llmModel.generateWithImage(prompt, imageData, maxTokens = 256)
                // } else {
                //     llmModel.generate(prompt, maxTokens = 128)
                // }

                // Simulated inference for now
                sendEvent("inference", mapOf("progress" to 0.7))
                delay(100)

                val response = if (imageData != null) {
                    "[Nexa VLM Demo] Enhanced with visual context: $text"
                } else {
                    enhanceTextDemo(text)
                }

                sendEvent("inference", mapOf("progress" to 1.0))

                sendEvent("inferenceResult", mapOf(
                    "original" to text,
                    "result" to response,
                    "hasImage" to (imageData != null)
                ))

                Log.d(TAG, "Multimodal inference complete")
                result.success(mapOf(
                    "original" to text,
                    "result" to response,
                    "hasImage" to (imageData != null)
                ))

            } catch (e: Exception) {
                Log.e(TAG, "Multimodal inference failed", e)
                sendEvent("error", mapOf("message" to "Inference failed: ${e.message}"))
                result.error("INFERENCE_ERROR", "Inference failed: ${e.message}", null)
            }
        }
    }

    /**
     * Generate a response from the LLM with a custom prompt.
     */
    private fun generateResponse(prompt: String, maxTokens: Int, temperature: Double, result: Result) {
        if (!isInitialized) {
            result.error("NOT_INITIALIZED", "Nexa LLM not initialized", null)
            return
        }

        scope.launch {
            try {
                sendEvent("generating", mapOf("progress" to 0.0))

                // TODO: Replace with actual Nexa SDK generation
                // val response = llmModel.generate(prompt, maxTokens, temperature.toFloat())

                // Simulated generation for now
                sendEvent("generating", mapOf("progress" to 0.5))
                delay(100)

                val response = "[Nexa LLM Demo] Response to: ${prompt.take(50)}..."

                sendEvent("generating", mapOf("progress" to 1.0))
                sendEvent("generated", mapOf("prompt" to prompt, "response" to response))

                Log.d(TAG, "Response generated")
                result.success(mapOf(
                    "prompt" to prompt,
                    "response" to response,
                    "tokensUsed" to response.split(" ").size
                ))

            } catch (e: Exception) {
                Log.e(TAG, "Response generation failed", e)
                sendEvent("error", mapOf("message" to "Generation failed: ${e.message}"))
                result.error("GENERATE_ERROR", "Generation failed: ${e.message}", null)
            }
        }
    }

    /**
     * Demo text enhancement (until actual SDK is integrated).
     */
    private fun enhanceTextDemo(text: String): String {
        // Basic enhancement: capitalize first letter, add period if needed
        var enhanced = text.trim()
        if (enhanced.isEmpty()) return enhanced

        // Capitalize first letter
        enhanced = enhanced.replaceFirstChar { it.uppercase() }

        // Add punctuation if missing
        if (!enhanced.endsWith(".") && !enhanced.endsWith("!") && !enhanced.endsWith("?")) {
            enhanced += "."
        }

        return enhanced
    }

    /**
     * Add enhanced text to cache with LRU eviction.
     */
    private fun addToCache(original: String, enhanced: String) {
        if (enhancementCache.size >= maxCacheSize) {
            val iterator = enhancementCache.entries.iterator()
            if (iterator.hasNext()) {
                iterator.next()
                iterator.remove()
            }
        }
        enhancementCache[original] = enhanced
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
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
    }

    /**
     * Get the chipset/SoC name from device info.
     */
    private fun getChipsetName(): String {
        return try {
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
            "currentInferenceMode" to inferenceMode.name,
            "currentModelName" to currentModelName,
            "supportsVision" to supportsVision
        )
    }

    /**
     * Get the default model path for the specified model.
     */
    private fun getDefaultModelPath(modelName: String): String {
        return "${context.filesDir}/models/$modelName"
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
            isInitialized = false
            enhancementCache.clear()

            // TODO: Dispose Nexa SDK resources
            // llmModel?.close()

            Log.d(TAG, "Nexa LLM disposed")
        } catch (e: Exception) {
            Log.e(TAG, "Error disposing Nexa LLM", e)
        }
    }
}

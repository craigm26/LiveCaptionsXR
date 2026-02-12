package com.example.nexa_ai_flutter

import com.nexa.sdk.LlmWrapper
import com.nexa.sdk.VlmWrapper
import com.nexa.sdk.bean.GenerationConfig
import com.nexa.sdk.bean.LlmStreamResult
import com.nexa.sdk.bean.SamplerConfig
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class LlmStreamHandler(
    private val llmWrappers: Map<String, LlmWrapper>,
    private val vlmWrappers: Map<String, VlmWrapper>,
    private val scope: CoroutineScope
) : EventChannel.StreamHandler {
    private var streamJob: Job? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (arguments !is Map<*, *> || events == null) return

        val wrapperId = arguments["wrapperId"] as? String ?: return
        val prompt = arguments["prompt"] as? String ?: return
        val configMap = arguments["config"] as? Map<*, *> ?: return

        val wrapper = llmWrappers[wrapperId] ?: vlmWrappers[wrapperId]
        if (wrapper == null) {
            events.error("WRAPPER_NOT_FOUND", "Wrapper with ID $wrapperId not found", null)
            return
        }

        val config = parseGenerationConfig(configMap)

        streamJob = scope.launch {
            try {
                when (wrapper) {
                    is LlmWrapper -> {
                        wrapper.generateStreamFlow(prompt, config).collect { result ->
                            handleStreamResult(result, events)
                        }
                    }
                    is VlmWrapper -> {
                        wrapper.generateStreamFlow(prompt, config).collect { result ->
                            handleStreamResult(result, events)
                        }
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    events.error("STREAM_ERROR", e.message, null)
                }
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        streamJob?.cancel()
        streamJob = null
    }

    private suspend fun handleStreamResult(result: LlmStreamResult, events: EventChannel.EventSink) {
        withContext(Dispatchers.Main) {
            when (result) {
                is LlmStreamResult.Token -> {
                    events.success(mapOf(
                        "type" to "token",
                        "text" to result.text
                    ))
                }
                is LlmStreamResult.Completed -> {
                    events.success(mapOf(
                        "type" to "completed",
                        "profile" to mapOf(
                            "ttftMs" to result.profile.ttftMs,
                            "decodingSpeed" to result.profile.decodingSpeed
                        )
                    ))
                }
                is LlmStreamResult.Error -> {
                    events.success(mapOf(
                        "type" to "error",
                        "message" to result.throwable.message
                    ))
                }
            }
        }
    }

    private fun parseGenerationConfig(map: Map<*, *>): GenerationConfig {
        val samplerConfigMap = map["samplerConfig"] as? Map<*, *>
        val samplerConfig = samplerConfigMap?.let {
            SamplerConfig(
                temperature = (it["temperature"] as? Double)?.toFloat() ?: 0.7f,
                topK = it["topK"] as? Int ?: 40,
                topP = (it["topP"] as? Double)?.toFloat() ?: 0.95f,
                minP = (it["minP"] as? Double)?.toFloat() ?: 0.05f,
                presencePenalty = (it["presencePenalty"] as? Double)?.toFloat() ?: 0.0f,
                frequencyPenalty = (it["frequencyPenalty"] as? Double)?.toFloat() ?: 0.0f,
                grammarString = it["grammarString"] as? String ?: ""
            )
        }

        return GenerationConfig(
            maxTokens = map["maxTokens"] as? Int ?: 0,
            stopWords = (map["stopWords"] as? List<*>)?.mapNotNull { it as? String }?.toTypedArray(),
            stopCount = map["stopCount"] as? Int ?: 0,
            nPast = map["nPast"] as? Int ?: 0,
            samplerConfig = samplerConfig,
            imagePaths = (map["imagePaths"] as? List<*>)?.mapNotNull { it as? String }?.toTypedArray(),
            imageCount = map["imageCount"] as? Int ?: 0,
            audioPaths = (map["audioPaths"] as? List<*>)?.mapNotNull { it as? String }?.toTypedArray(),
            audioCount = map["audioCount"] as? Int ?: 0
        )
    }
}

class VlmStreamHandler(
    private val vlmWrappers: Map<String, VlmWrapper>,
    private val scope: CoroutineScope
) : EventChannel.StreamHandler {
    private var streamJob: Job? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (arguments !is Map<*, *> || events == null) return

        val wrapperId = arguments["wrapperId"] as? String ?: return
        val prompt = arguments["prompt"] as? String ?: return
        val configMap = arguments["config"] as? Map<*, *> ?: return

        val wrapper = vlmWrappers[wrapperId]
        if (wrapper == null) {
            events.error("WRAPPER_NOT_FOUND", "VLM Wrapper with ID $wrapperId not found", null)
            return
        }

        val config = parseGenerationConfig(configMap)

        streamJob = scope.launch {
            try {
                wrapper.generateStreamFlow(prompt, config).collect { result ->
                    handleStreamResult(result, events)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    events.error("STREAM_ERROR", e.message, null)
                }
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        streamJob?.cancel()
        streamJob = null
    }

    private suspend fun handleStreamResult(result: LlmStreamResult, events: EventChannel.EventSink) {
        withContext(Dispatchers.Main) {
            when (result) {
                is LlmStreamResult.Token -> {
                    events.success(mapOf(
                        "type" to "token",
                        "text" to result.text
                    ))
                }
                is LlmStreamResult.Completed -> {
                    events.success(mapOf(
                        "type" to "completed",
                        "profile" to mapOf(
                            "ttftMs" to result.profile.ttftMs,
                            "decodingSpeed" to result.profile.decodingSpeed
                        )
                    ))
                }
                is LlmStreamResult.Error -> {
                    events.success(mapOf(
                        "type" to "error",
                        "message" to result.throwable.message
                    ))
                }
            }
        }
    }

    private fun parseGenerationConfig(map: Map<*, *>): GenerationConfig {
        val samplerConfigMap = map["samplerConfig"] as? Map<*, *>
        val samplerConfig = samplerConfigMap?.let {
            SamplerConfig(
                temperature = (it["temperature"] as? Double)?.toFloat() ?: 0.7f,
                topK = it["topK"] as? Int ?: 40,
                topP = (it["topP"] as? Double)?.toFloat() ?: 0.95f,
                minP = (it["minP"] as? Double)?.toFloat() ?: 0.05f,
                presencePenalty = (it["presencePenalty"] as? Double)?.toFloat() ?: 0.0f,
                frequencyPenalty = (it["frequencyPenalty"] as? Double)?.toFloat() ?: 0.0f,
                grammarString = it["grammarString"] as? String ?: ""
            )
        }

        return GenerationConfig(
            maxTokens = map["maxTokens"] as? Int ?: 0,
            stopWords = (map["stopWords"] as? List<*>)?.mapNotNull { it as? String }?.toTypedArray(),
            stopCount = map["stopCount"] as? Int ?: 0,
            nPast = map["nPast"] as? Int ?: 0,
            samplerConfig = samplerConfig,
            imagePaths = (map["imagePaths"] as? List<*>)?.mapNotNull { it as? String }?.toTypedArray(),
            imageCount = map["imageCount"] as? Int ?: 0,
            audioPaths = (map["audioPaths"] as? List<*>)?.mapNotNull { it as? String }?.toTypedArray(),
            audioCount = map["audioCount"] as? Int ?: 0
        )
    }
}

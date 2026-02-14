package com.example.nexa_ai_flutter

import android.content.Context
import com.nexa.sdk.*
import com.nexa.sdk.bean.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.collect
import java.util.UUID

/** NexaAiFlutterPlugin */
class NexaAiFlutterPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var llmStreamChannel: EventChannel
    private lateinit var vlmStreamChannel: EventChannel
    private lateinit var downloadProgressChannel: EventChannel
    private lateinit var context: Context
    private val modelScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private lateinit var downloadManager: ModelDownloadManager
    private lateinit var capabilityChecker: DeviceCapabilityChecker

    // Store model wrappers by ID
    private val llmWrappers = mutableMapOf<String, LlmWrapper>()
    private val vlmWrappers = mutableMapOf<String, VlmWrapper>()
    private val embedderWrappers = mutableMapOf<String, EmbedderWrapper>()
    private val asrWrappers = mutableMapOf<String, AsrWrapper>()
    private val rerankerWrappers = mutableMapOf<String, RerankerWrapper>()
    private val cvWrappers = mutableMapOf<String, CvWrapper>()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        downloadManager = ModelDownloadManager(context)
        capabilityChecker = DeviceCapabilityChecker()

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "nexa_ai_flutter")
        channel.setMethodCallHandler(this)

        llmStreamChannel = EventChannel(flutterPluginBinding.binaryMessenger, "nexa_ai_flutter/llm_stream")
        llmStreamChannel.setStreamHandler(LlmStreamHandler(llmWrappers, vlmWrappers, modelScope))

        vlmStreamChannel = EventChannel(flutterPluginBinding.binaryMessenger, "nexa_ai_flutter/vlm_stream")
        vlmStreamChannel.setStreamHandler(VlmStreamHandler(vlmWrappers, modelScope))

        downloadProgressChannel = EventChannel(flutterPluginBinding.binaryMessenger, "nexa_ai_flutter/download_progress")
        downloadProgressChannel.setStreamHandler(DownloadProgressHandler(downloadManager, modelScope))
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initializeSdk" -> initializeSdk(result)
            "createLlm" -> createLlm(call, result)
            "createVlm" -> createVlm(call, result)
            "createEmbedder" -> createEmbedder(call, result)
            "createAsr" -> createAsr(call, result)
            "createReranker" -> createReranker(call, result)
            "createCv" -> createCv(call, result)
            "applyChatTemplate" -> applyChatTemplate(call, result)
            "applyVlmChatTemplate" -> applyVlmChatTemplate(call, result)
            "embed" -> embed(call, result)
            "transcribe" -> transcribe(call, result)
            "rerank" -> rerank(call, result)
            "cvInfer" -> cvInfer(call, result)
            "stopStream" -> stopStream(call, result)
            "reset" -> reset(call, result)
            "destroy" -> destroy(call, result)
            // Download methods
            "getAvailableModels" -> getAvailableModels(result)
            "isModelDownloaded" -> isModelDownloaded(call, result)
            "getModelPath" -> getModelPath(call, result)
            "cancelDownload" -> cancelDownload(call, result)
            "deleteModel" -> deleteModel(call, result)
            "getStorageInfo" -> getStorageInfo(result)
            "getModelsDirectory" -> getModelsDirectory(result)
            "cleanupIncompleteDownloads" -> cleanupIncompleteDownloads(result)
            "getDownloadedModels" -> getDownloadedModels(result)
            // Device capability methods
            "getDeviceInfo" -> getDeviceInfo(result)
            "checkModelCompatibility" -> checkModelCompatibility(call, result)
            else -> result.notImplemented()
        }
    }

    private fun initializeSdk(result: Result) {
        try {
            NexaSdk.getInstance().init(context, object : NexaSdk.InitCallback {
                override fun onSuccess() {
                    result.success(null)
                }
                override fun onFailure(reason: String) {
                    result.error("INIT_ERROR", reason, null)
                }
            })
        } catch (e: Exception) {
            result.error("INIT_ERROR", e.message, null)
        }
    }

    private fun createLlm(call: MethodCall, result: Result) {
        modelScope.launch {
            try {
                val config = parseModelConfig(call.argument<Map<String, Any>>("config")!!)
                val input = LlmCreateInput(
                    model_name = call.argument<String>("modelName") ?: "",
                    model_path = call.argument<String>("modelPath")!!,
                    tokenizer_path = call.argument<String>("tokenizerPath"),
                    config = config,
                    plugin_id = call.argument<String>("pluginId") ?: "cpu_gpu"
                )

                LlmWrapper.builder().llmCreateInput(input).build()
                    .onSuccess { wrapper ->
                        val wrapperId = UUID.randomUUID().toString()
                        llmWrappers[wrapperId] = wrapper
                        withContext(Dispatchers.Main) {
                            result.success(wrapperId)
                        }
                    }
                    .onFailure { error ->
                        withContext(Dispatchers.Main) {
                            result.error("CREATE_LLM_ERROR", error.message, null)
                        }
                    }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("CREATE_LLM_ERROR", e.message, null)
                }
            }
        }
    }

    private fun createVlm(call: MethodCall, result: Result) {
        modelScope.launch {
            try {
                val config = parseModelConfig(call.argument<Map<String, Any>>("config")!!)
                val input = VlmCreateInput(
                    model_name = call.argument<String>("modelName") ?: "",
                    model_path = call.argument<String>("modelPath")!!,
                    mmproj_path = call.argument<String>("mmprojPath"),
                    config = config,
                    plugin_id = call.argument<String>("pluginId") ?: "cpu_gpu"
                )

                VlmWrapper.builder().vlmCreateInput(input).build()
                    .onSuccess { wrapper ->
                        val wrapperId = UUID.randomUUID().toString()
                        vlmWrappers[wrapperId] = wrapper
                        withContext(Dispatchers.Main) {
                            result.success(wrapperId)
                        }
                    }
                    .onFailure { error ->
                        withContext(Dispatchers.Main) {
                            result.error("CREATE_VLM_ERROR", error.message, null)
                        }
                    }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("CREATE_VLM_ERROR", e.message, null)
                }
            }
        }
    }

    private fun createEmbedder(call: MethodCall, result: Result) {
        modelScope.launch {
            try {
                val config = parseModelConfig(call.argument<Map<String, Any>>("config")!!)
                val input = EmbedderCreateInput(
                    model_name = call.argument<String>("modelName") ?: "",
                    model_path = call.argument<String>("modelPath")!!,
                    config = config,
                    plugin_id = call.argument<String>("pluginId") ?: "cpu_gpu"
                )

                EmbedderWrapper.builder().embedderCreateInput(input).build()
                    .onSuccess { wrapper ->
                        val wrapperId = UUID.randomUUID().toString()
                        embedderWrappers[wrapperId] = wrapper
                        withContext(Dispatchers.Main) {
                            result.success(wrapperId)
                        }
                    }
                    .onFailure { error ->
                        withContext(Dispatchers.Main) {
                            result.error("CREATE_EMBEDDER_ERROR", error.message, null)
                        }
                    }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("CREATE_EMBEDDER_ERROR", e.message, null)
                }
            }
        }
    }

    private fun createAsr(call: MethodCall, result: Result) {
        modelScope.launch {
            try {
                val config = parseModelConfig(call.argument<Map<String, Any>>("config")!!)
                val input = AsrCreateInput(
                    model_name = call.argument<String>("modelName") ?: "",
                    model_path = call.argument<String>("modelPath")!!,
                    config = config,
                    plugin_id = call.argument<String>("pluginId") ?: "cpu_gpu"
                )

                AsrWrapper.builder().asrCreateInput(input).build()
                    .onSuccess { wrapper ->
                        val wrapperId = UUID.randomUUID().toString()
                        asrWrappers[wrapperId] = wrapper
                        withContext(Dispatchers.Main) {
                            result.success(wrapperId)
                        }
                    }
                    .onFailure { error ->
                        withContext(Dispatchers.Main) {
                            result.error("CREATE_ASR_ERROR", error.message, null)
                        }
                    }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("CREATE_ASR_ERROR", e.message, null)
                }
            }
        }
    }

    private fun createReranker(call: MethodCall, result: Result) {
        modelScope.launch {
            try {
                val config = parseModelConfig(call.argument<Map<String, Any>>("config")!!)
                val input = RerankerCreateInput(
                    model_name = call.argument<String>("modelName") ?: "",
                    model_path = call.argument<String>("modelPath")!!,
                    config = config,
                    plugin_id = call.argument<String>("pluginId") ?: "cpu_gpu"
                )

                RerankerWrapper.builder().rerankerCreateInput(input).build()
                    .onSuccess { wrapper ->
                        val wrapperId = UUID.randomUUID().toString()
                        rerankerWrappers[wrapperId] = wrapper
                        withContext(Dispatchers.Main) {
                            result.success(wrapperId)
                        }
                    }
                    .onFailure { error ->
                        withContext(Dispatchers.Main) {
                            result.error("CREATE_RERANKER_ERROR", error.message, null)
                        }
                    }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("CREATE_RERANKER_ERROR", e.message, null)
                }
            }
        }
    }

    private fun createCv(call: MethodCall, result: Result) {
        modelScope.launch {
            try {
                val configMap = call.argument<Map<String, Any>>("config")!!
                val capabilityStr = configMap["capabilities"] as? String ?: "OCR"
                val capability = when (capabilityStr.uppercase()) {
                    "OCR" -> CVCapability.OCR
                    else -> CVCapability.OCR
                }

                val cvConfig = CVModelConfig(
                    capabilities = capability,
                    det_model_path = (configMap["detModelPath"] as? String) ?: "",
                    rec_model_path = (configMap["recModelPath"] as? String) ?: "",
                    char_dict_path = (configMap["charDictPath"] as? String) ?: "",
                    npu_model_folder_path = (configMap["npuModelFolderPath"] as? String) ?: "",
                    npu_lib_folder_path = (configMap["npuLibFolderPath"] as? String) ?: ""
                )

                val input = CVCreateInput(
                    model_name = call.argument<String>("modelName") ?: "paddleocr",
                    config = cvConfig,
                    plugin_id = call.argument<String>("pluginId") ?: "cpu_gpu"
                )

                CvWrapper.builder().createInput(input).build()
                    .onSuccess { wrapper ->
                        val wrapperId = UUID.randomUUID().toString()
                        cvWrappers[wrapperId] = wrapper
                        withContext(Dispatchers.Main) {
                            result.success(wrapperId)
                        }
                    }
                    .onFailure { error ->
                        withContext(Dispatchers.Main) {
                            result.error("CREATE_CV_ERROR", error.message, null)
                        }
                    }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("CREATE_CV_ERROR", e.message, null)
                }
            }
        }
    }

    private fun applyChatTemplate(call: MethodCall, result: Result) {
        modelScope.launch {
            try {
                val wrapperId = call.argument<String>("wrapperId")!!
                val wrapper = llmWrappers[wrapperId] ?: throw Exception("Wrapper not found")

                val messages = parseChatMessages(call.argument<List<Map<String, Any>>>("messages")!!)
                val tools = call.argument<String>("tools")
                val enableThinking = call.argument<Boolean>("enableThinking") ?: false

                wrapper.applyChatTemplate(messages.toTypedArray(), tools, enableThinking)
                    .onSuccess { templateOutput ->
                        withContext(Dispatchers.Main) {
                            result.success(mapOf("formattedText" to templateOutput.formattedText))
                        }
                    }
                    .onFailure { error ->
                        withContext(Dispatchers.Main) {
                            result.error("CHAT_TEMPLATE_ERROR", error.message, null)
                        }
                    }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("CHAT_TEMPLATE_ERROR", e.message, null)
                }
            }
        }
    }

    private fun applyVlmChatTemplate(call: MethodCall, result: Result) {
        modelScope.launch {
            try {
                val wrapperId = call.argument<String>("wrapperId")!!
                val wrapper = vlmWrappers[wrapperId] ?: throw Exception("Wrapper not found")

                val messages = parseVlmChatMessages(call.argument<List<Map<String, Any>>>("messages")!!)
                val tools = call.argument<String>("tools")
                val enableThinking = call.argument<Boolean>("enableThinking") ?: false

                wrapper.applyChatTemplate(messages.toTypedArray(), tools, enableThinking)
                    .onSuccess { templateOutput ->
                        withContext(Dispatchers.Main) {
                            result.success(mapOf("formattedText" to templateOutput.formattedText))
                        }
                    }
                    .onFailure { error ->
                        withContext(Dispatchers.Main) {
                            result.error("VLM_CHAT_TEMPLATE_ERROR", error.message, null)
                        }
                    }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("VLM_CHAT_TEMPLATE_ERROR", e.message, null)
                }
            }
        }
    }

    private fun embed(call: MethodCall, result: Result) {
        modelScope.launch {
            try {
                val wrapperId = call.argument<String>("wrapperId")!!
                val wrapper = embedderWrappers[wrapperId] ?: throw Exception("Wrapper not found")

                val texts = call.argument<List<String>>("texts")!!.toTypedArray()
                val normalize = call.argument<Map<String, Any>>("config")?.get("normalize") as? Boolean ?: true
                val config = EmbeddingConfig(normalize = normalize)

                wrapper.embed(texts, config)
                    .onSuccess { embeddings ->
                        withContext(Dispatchers.Main) {
                            result.success(embeddings.embeddings.toList())
                        }
                    }
                    .onFailure { error ->
                        withContext(Dispatchers.Main) {
                            result.error("EMBED_ERROR", error.message, null)
                        }
                    }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("EMBED_ERROR", e.message, null)
                }
            }
        }
    }

    private fun transcribe(call: MethodCall, result: Result) {
        modelScope.launch {
            try {
                val wrapperId = call.argument<String>("wrapperId")!!
                val wrapper = asrWrappers[wrapperId] ?: throw Exception("Wrapper not found")

                val input = AsrTranscribeInput(
                    audioPath = call.argument<String>("audioPath")!!,
                    language = call.argument<String>("language") ?: "en"
                )

                wrapper.transcribe(input)
                    .onSuccess { transcription ->
                        withContext(Dispatchers.Main) {
                            result.success(
                                mapOf(
                                    "result" to mapOf("transcript" to transcription.result.transcript),
                                    "profileData" to transcription.profileData.toString()
                                )
                            )
                        }
                    }
                    .onFailure { error ->
                        withContext(Dispatchers.Main) {
                            result.error("TRANSCRIBE_ERROR", error.message, null)
                        }
                    }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("TRANSCRIBE_ERROR", e.message, null)
                }
            }
        }
    }

    private fun rerank(call: MethodCall, result: Result) {
        modelScope.launch {
            try {
                val wrapperId = call.argument<String>("wrapperId")!!
                val wrapper = rerankerWrappers[wrapperId] ?: throw Exception("Wrapper not found")

                val query = call.argument<String>("query")!!
                val documents = call.argument<List<String>>("documents")!!.toTypedArray()
                val config = RerankConfig()

                wrapper.rerank(query, documents, config)
                    .onSuccess { rerankerResult ->
                        withContext(Dispatchers.Main) {
                            result.success(
                                mapOf(
                                    "scores" to rerankerResult.scores?.toList(),
                                    "scoreCount" to rerankerResult.scoreCount,
                                    "profileData" to rerankerResult.profileData.toString()
                                )
                            )
                        }
                    }
                    .onFailure { error ->
                        withContext(Dispatchers.Main) {
                            result.error("RERANK_ERROR", error.message, null)
                        }
                    }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("RERANK_ERROR", e.message, null)
                }
            }
        }
    }

    private fun cvInfer(call: MethodCall, result: Result) {
        modelScope.launch {
            try {
                val wrapperId = call.argument<String>("wrapperId")!!
                val wrapper = cvWrappers[wrapperId] ?: throw Exception("Wrapper not found")

                val imagePath = call.argument<String>("imagePath")!!

                wrapper.infer(imagePath)
                    .onSuccess { results ->
                        withContext(Dispatchers.Main) {
                            result.success(results.map { cvResult ->
                                mapOf(
                                    "text" to cvResult.text,
                                    "confidence" to cvResult.confidence
                                )
                            })
                        }
                    }
                    .onFailure { error ->
                        withContext(Dispatchers.Main) {
                            result.error("CV_INFER_ERROR", error.message, null)
                        }
                    }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("CV_INFER_ERROR", e.message, null)
                }
            }
        }
    }

    private fun stopStream(call: MethodCall, result: Result) {
        modelScope.launch {
            try {
                val wrapperId = call.argument<String>("wrapperId")!!
                val llmWrapper = llmWrappers[wrapperId]
                val vlmWrapper = vlmWrappers[wrapperId]

                when {
                    llmWrapper != null -> llmWrapper.stopStream()
                    vlmWrapper != null -> vlmWrapper.stopStream()
                    else -> throw Exception("Wrapper not found")
                }

                withContext(Dispatchers.Main) {
                    result.success(null)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("STOP_STREAM_ERROR", e.message, null)
                }
            }
        }
    }

    private fun reset(call: MethodCall, result: Result) {
        modelScope.launch {
            try {
                val wrapperId = call.argument<String>("wrapperId")!!
                val llmWrapper = llmWrappers[wrapperId]
                val vlmWrapper = vlmWrappers[wrapperId]

                when {
                    llmWrapper != null -> llmWrapper.reset()
                    vlmWrapper != null -> vlmWrapper.reset()
                    else -> throw Exception("Wrapper not found")
                }

                withContext(Dispatchers.Main) {
                    result.success(null)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("RESET_ERROR", e.message, null)
                }
            }
        }
    }

    private fun destroy(call: MethodCall, result: Result) {
        modelScope.launch {
            try {
                val wrapperId = call.argument<String>("wrapperId")!!

                when {
                    llmWrappers.containsKey(wrapperId) -> {
                        llmWrappers[wrapperId]?.destroy()
                        llmWrappers.remove(wrapperId)
                    }
                    vlmWrappers.containsKey(wrapperId) -> {
                        vlmWrappers[wrapperId]?.destroy()
                        vlmWrappers.remove(wrapperId)
                    }
                    embedderWrappers.containsKey(wrapperId) -> {
                        embedderWrappers[wrapperId]?.destroy()
                        embedderWrappers.remove(wrapperId)
                    }
                    asrWrappers.containsKey(wrapperId) -> {
                        asrWrappers[wrapperId]?.destroy()
                        asrWrappers.remove(wrapperId)
                    }
                    rerankerWrappers.containsKey(wrapperId) -> {
                        rerankerWrappers[wrapperId]?.destroy()
                        rerankerWrappers.remove(wrapperId)
                    }
                    cvWrappers.containsKey(wrapperId) -> {
                        cvWrappers[wrapperId]?.destroy()
                        cvWrappers.remove(wrapperId)
                    }
                    else -> throw Exception("Wrapper not found")
                }

                withContext(Dispatchers.Main) {
                    result.success(null)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("DESTROY_ERROR", e.message, null)
                }
            }
        }
    }

    // Download methods
    private fun getAvailableModels(result: Result) {
        try {
            val models = downloadManager.getAvailableModels()
            result.success(models)
        } catch (e: Exception) {
            result.error("GET_MODELS_ERROR", e.message, null)
        }
    }

    private fun isModelDownloaded(call: MethodCall, result: Result) {
        try {
            val modelId = call.argument<String>("modelId")!!
            val isDownloaded = downloadManager.isModelDownloaded(modelId)
            result.success(isDownloaded)
        } catch (e: Exception) {
            result.error("CHECK_DOWNLOAD_ERROR", e.message, null)
        }
    }

    private fun getModelPath(call: MethodCall, result: Result) {
        try {
            val modelId = call.argument<String>("modelId")!!
            val path = downloadManager.getModelPath(modelId)
            result.success(path)
        } catch (e: Exception) {
            result.error("GET_PATH_ERROR", e.message, null)
        }
    }

    private fun cancelDownload(call: MethodCall, result: Result) {
        try {
            val modelId = call.argument<String>("modelId")!!
            downloadManager.cancelDownload(modelId)
            result.success(null)
        } catch (e: Exception) {
            result.error("CANCEL_ERROR", e.message, null)
        }
    }

    private fun deleteModel(call: MethodCall, result: Result) {
        try {
            val modelId = call.argument<String>("modelId")!!
            downloadManager.deleteModel(modelId)
            result.success(null)
        } catch (e: Exception) {
            result.error("DELETE_ERROR", e.message, null)
        }
    }

    private fun getStorageInfo(result: Result) {
        try {
            val info = downloadManager.getStorageInfo()
            result.success(info)
        } catch (e: Exception) {
            result.error("STORAGE_INFO_ERROR", e.message, null)
        }
    }

    private fun getModelsDirectory(result: Result) {
        try {
            val dir = downloadManager.getModelsDirectory()
            result.success(dir.absolutePath)
        } catch (e: Exception) {
            result.error("GET_DIR_ERROR", e.message, null)
        }
    }

    private fun cleanupIncompleteDownloads(result: Result) {
        try {
            downloadManager.cleanupIncompleteDownloads()
            result.success(null)
        } catch (e: Exception) {
            result.error("CLEANUP_ERROR", e.message, null)
        }
    }

    private fun getDownloadedModels(result: Result) {
        try {
            val models = downloadManager.getDownloadedModels()
            result.success(models)
        } catch (e: Exception) {
            result.error("GET_DOWNLOADED_ERROR", e.message, null)
        }
    }

    private fun getDeviceInfo(result: Result) {
        try {
            val deviceInfo = capabilityChecker.getDeviceInfo()
            result.success(deviceInfo)
        } catch (e: Exception) {
            result.error("DEVICE_INFO_ERROR", e.message, null)
        }
    }

    private fun checkModelCompatibility(call: MethodCall, result: Result) {
        try {
            val modelId = call.argument<String>("modelId")!!
            val compatibility = capabilityChecker.checkModelCompatibility(modelId)
            result.success(compatibility)
        } catch (e: Exception) {
            result.error("COMPATIBILITY_CHECK_ERROR", e.message, null)
        }
    }

    // Helper functions
    private fun parseModelConfig(map: Map<String, Any>): ModelConfig {
        return ModelConfig(
            nCtx = map["nCtx"] as? Int ?: 4096,
            max_tokens = map["maxTokens"] as? Int ?: 2048,
            enable_thinking = map["enableThinking"] as? Boolean ?: false,
            npu_lib_folder_path = map["npuLibFolderPath"] as? String ?: "",
            npu_model_folder_path = map["npuModelFolderPath"] as? String ?: ""
        )
    }

    private fun parseChatMessages(list: List<Map<String, Any>>): List<ChatMessage> {
        return list.map { ChatMessage(it["role"] as String, it["content"] as String) }
    }

    private fun parseVlmChatMessages(list: List<Map<String, Any>>): List<VlmChatMessage> {
        return list.map { msg ->
            val contents = (msg["contents"] as List<Map<String, Any>>).map { content ->
                VlmContent(content["type"] as String, content["content"] as String)
            }
            VlmChatMessage(msg["role"] as String, contents)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        llmStreamChannel.setStreamHandler(null)
        vlmStreamChannel.setStreamHandler(null)
        downloadProgressChannel.setStreamHandler(null)
        modelScope.cancel()
    }
}

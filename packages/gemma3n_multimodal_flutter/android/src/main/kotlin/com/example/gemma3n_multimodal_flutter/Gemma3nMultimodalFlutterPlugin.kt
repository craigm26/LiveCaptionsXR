package com.example.gemma3n_multimodal_flutter

import android.content.Context
import android.graphics.BitmapFactory
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import com.google.mediapipe.tasks.genai.llminference.LlmInference.LlmInferenceOptions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

class Gemma3nMultimodalFlutterPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val llmInferenceInstances = mutableMapOf<String, LlmInference>()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "gemma3n_multimodal_flutter")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "create" -> {
                val assetPath = call.argument<String>("assetPath")!!
                val modelPath = copyAssetToCache(assetPath)
                val options = LlmInferenceOptions.builder()
                    .setModelPath(modelPath)
                    .build()
                val llmInference = LlmInference.createFromOptions(context, options)
                llmInferenceInstances[assetPath] = llmInference
                result.success(null)
            }
            "createSession" -> {
                result.success(null)
            }
            "addQueryChunk" -> {
                result.success(null)
            }
            "getResponse" -> {
                val assetPath = call.argument<String>("assetPath")!!
                val queryMessages = call.argument<List<Map<String, Any?>>>("query")!!
                val llmInference = llmInferenceInstances[assetPath]!!

                val textParts = queryMessages.mapNotNull { it["text"] as? String }
                val imageParts = queryMessages.mapNotNull { it["imageBytes"] as? ByteArray }.map {
                    BitmapFactory.decodeByteArray(it, 0, it.size)
                }

                val response = llmInference.generateResponse(textParts.joinToString(" "), imageParts)
                result.success(response)
            }
            "close" -> {
                val assetPath = call.argument<String>("assetPath")!!
                llmInferenceInstances.remove(assetPath)?.close()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun copyAssetToCache(assetPath: String): String {
        val assetManager = context.assets
        val inputStream = assetManager.open(assetPath)
        val file = File(context.cacheDir, assetPath.split("/").last())
        val outputStream = file.outputStream()
        inputStream.copyTo(outputStream)
        return file.absolutePath
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        llmInferenceInstances.values.forEach { it.close() }
        llmInferenceInstances.clear()
    }
}

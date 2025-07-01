package com.example.gemma3n_multimodal

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.content.Context
import android.os.SystemClock
import android.util.Log
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import com.google.mediapipe.tasks.genai.llminference.LlmInferenceOptions
import io.flutter.plugin.common.EventChannel
import org.json.JSONObject
import org.json.JSONArray
import android.graphics.BitmapFactory
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.genai.llminference.LlmInferenceSession
import com.google.mediapipe.tasks.genai.llminference.LlmInferenceSession.LlmInferenceSessionOptions
import com.google.mediapipe.tasks.genai.llminference.GraphOptions

/** Gemma3nMultimodalPlugin */
class Gemma3nMultimodalPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var llmInference: LlmInference? = null
  private var isLoaded: Boolean = false
  private var modelPath: String? = null
  private var backend: String = "CPU"
  private var applicationContext: Context? = null
  private var eventChannel: EventChannel? = null
  private var eventSink: EventChannel.EventSink? = null
  private val audioBuffer = mutableListOf<FloatArray>()

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "gemma3n_multimodal")
    channel.setMethodCallHandler(this)
    applicationContext = flutterPluginBinding.applicationContext
    // Register EventChannel for streaming
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "gemma3n_multimodal_stream")
    eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
      override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        if (arguments !is Map<*, *>) {
          events?.error("INVALID_ARGUMENT", "Arguments must be a map", null)
          return
        }
        val type = arguments["type"] as? String
        when (type) {
          "transcription" -> handleStreamTranscription(arguments, events)
          "multimodal" -> handleStreamMultimodal(arguments, events)
          else -> events?.error("INVALID_ARGUMENT", "Unknown stream type", null)
        }
      }
      override fun onCancel(arguments: Any?) {
        eventSink = null
      }
    })
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "transcribeAudio" -> {
        // TODO: Implement audio transcription using native model
        val audioBytes = call.argument<ByteArray>("audio")
        if (audioBytes == null) {
          result.error("INVALID_ARGUMENT", "Missing 'audio' argument", null)
          return
        }
        // Placeholder response
        result.success("[stub] Transcription result from Android")
      }
      "runMultimodal" -> {
        val text = call.argument<String>("text")
        val imageBytes = call.argument<ByteArray>("image")
        // 1. Create session with vision modality if image is present
        val sessionOptions = LlmInferenceSession.LlmInferenceSessionOptions.builder()
          .setGraphOptions(
            GraphOptions.builder()
              .setEnableVisionModality(imageBytes != null)
              .build()
          )
          .build()
        val session = LlmInferenceSession.createFromOptions(llmInference, sessionOptions)
        // 2. Add text
        text?.let { session.addQueryChunk(it) }
        // 3. Add image
        imageBytes?.let {
          val bitmap = BitmapFactory.decodeByteArray(it, 0, it.size)
          val mpImage = BitmapImageBuilder(bitmap).build()
          session.addImage(mpImage)
        }
        // 4. Add all buffered audio chunks
        for (chunk in audioBuffer) {
          session.addAudioChunk(chunk)
        }
        audioBuffer.clear()
        // 5. Run inference and return result
        val resultText = session.finish()
        session.close()
        val json = JSONObject()
        json.put("text", resultText)
        // Optionally add more fields (e.g., tokens)
        result.success(json.toString())
      }
      "loadModel" -> {
        val path = call.argument<String>("path")
        val useGPU = call.argument<Boolean>("useGPU") ?: false
        val context = applicationContext
        if (context == null || path == null) {
          result.error("INVALID_ARGUMENT", "Missing context or model path", null)
          return
        }
        try {
          val start = SystemClock.elapsedRealtime()
          val options = LlmInferenceOptions.builder()
            .setModelPath(path)
            .apply { if (useGPU) setDelegate(LlmInferenceOptions.Delegate.GPU) else setDelegate(LlmInferenceOptions.Delegate.CPU) }
            .build()
          llmInference = LlmInference.createFromOptions(context, options)
          backend = if (useGPU) "GPU" else "CPU"
          isLoaded = true
          modelPath = path
          val elapsed = SystemClock.elapsedRealtime() - start
          Log.i("Gemma3nMultimodal", "Model loaded: $path, backend: $backend, time: ${elapsed}ms")
          result.success(null)
        } catch (e: Exception) {
          Log.e("Gemma3nMultimodal", "Model load failed: ${e.message}")
          isLoaded = false
          llmInference = null
          result.error("LOAD_FAILED", e.message, null)
        }
      }
      "unloadModel" -> {
        llmInference = null
        isLoaded = false
        modelPath = null
        Log.i("Gemma3nMultimodal", "Model unloaded")
        result.success(null)
      }
      "isModelLoaded" -> {
        result.success(isLoaded)
      }
      "addAudioChunk" -> {
        val audioBytes = call.argument<ByteArray>("audio")
        if (audioBytes == null) {
          result.error("INVALID_ARGUMENT", "Missing audio bytes", null)
          return
        }
        val floatAudio = convertPcm16ToFloat32(audioBytes)
        audioBuffer.add(floatAudio)
        result.success(null)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  // Streaming transcription handler
  private fun handleStreamTranscription(arguments: Map<*, *>, events: EventChannel.EventSink?) {
    val audioBytes = arguments["audio"] as? ByteArray
    val llm = llmInference
    if (llm == null || audioBytes == null) {
      events?.error("NOT_READY", "Model not loaded or missing audio", null)
      return
    }
    // Convert PCM16 to float32
    val floatAudio = convertPcm16ToFloat32(audioBytes)
    // Create a session and add audio
    val session = LlmInferenceSession.createFromOptions(llm, LlmInferenceSession.LlmInferenceSessionOptions.builder().build())
    session.addAudioChunk(floatAudio)
    // Use MediaPipe's async streaming API for partial results
    session.generateResponseAsync(object : LlmInferenceSession.ResultListener {
      override fun onResult(partialResult: String?, done: Boolean) {
        if (partialResult != null) {
          events?.success(partialResult)
        }
        if (done) {
          events?.endOfStream()
          session.close()
        }
      }
      override fun onError(error: Exception) {
        events?.error("STREAM_FAILED", error.message, null)
        events?.endOfStream()
        session.close()
      }
    })
  }

  // Streaming multimodal handler
  private fun handleStreamMultimodal(arguments: Map<*, *>, events: EventChannel.EventSink?) {
    val audioBytes = arguments["audio"] as? ByteArray
    val imageBytes = arguments["image"] as? ByteArray
    val text = arguments["text"] as? String
    if (llmInference == null || (audioBytes == null && imageBytes == null && text == null)) {
      events?.error("NOT_READY", "Model not loaded or no input provided", null)
      return
    }
    // TODO: Replace with actual MediaPipe async streaming API
    // Example: llmInference?.generateResponseAsync(multimodalInput, callback)
    // For now, simulate streaming
    Thread {
      for (i in 1..5) {
        Thread.sleep(120)
        events?.success("Partial multimodal $i")
      }
      events?.endOfStream()
    }.start()
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel?.setStreamHandler(null)
    eventSink = null
  }

  // Helper to get context from FlutterPluginBinding
  private fun getContext(): Context? {
    return applicationContext
  }

  // PCM16 to float32 conversion
  private fun convertPcm16ToFloat32(pcm: ByteArray): FloatArray {
    val floatArray = FloatArray(pcm.size / 2)
    for (i in floatArray.indices) {
      val low = pcm[i * 2].toInt() and 0xff
      val high = pcm[i * 2 + 1].toInt()
      val value = (high shl 8) or low
      floatArray[i] = value / 32768.0f
    }
    return floatArray
  }
}

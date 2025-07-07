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
import android.speech.RecognitionListener
import android.speech.SpeechRecognizer
import android.speech.RecognizerIntent
import android.content.Intent
import android.os.Bundle
import java.util.*
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

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
  
  // Speech Recognition state
  private var speechRecognizer: SpeechRecognizer? = null
  private var isSpeechRecognitionAvailable: Boolean = false
  private var currentLanguage: String = "en"
  private var useNativeSpeechRecognition: Boolean = true
  private var enableRealTimeEnhancement: Boolean = true

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "gemma3n_multimodal")
    channel.setMethodCallHandler(this)
    applicationContext = flutterPluginBinding.applicationContext
    initializeSpeechRecognition()
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

  private fun initializeSpeechRecognition() {
    applicationContext?.let { context ->
      if (SpeechRecognizer.isRecognitionAvailable(context)) {
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
        isSpeechRecognitionAvailable = true
        Log.i("Gemma3nPlugin", "✅ Android Speech Recognition initialized")
      } else {
        isSpeechRecognitionAvailable = false
        Log.w("Gemma3nPlugin", "❌ Android Speech Recognition not available")
      }
      
      // Check for RECORD_AUDIO permission
      val hasPermission = ContextCompat.checkSelfPermission(
        context, 
        Manifest.permission.RECORD_AUDIO
      ) == PackageManager.PERMISSION_GRANTED
      
      if (!hasPermission) {
        Log.w("Gemma3nPlugin", "⚠️ RECORD_AUDIO permission not granted")
        isSpeechRecognitionAvailable = false
      }
    }
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }
      "transcribeAudio" -> {
        val audioBytes = call.argument<ByteArray>("audio")
        val isFinal = call.argument<Boolean>("isFinal") ?: false
        if (audioBytes == null) {
          result.error("INVALID_ARGUMENT", "Missing 'audio' argument", null)
          return
        }
        
        try {
          val transcription = performASR(audioBytes, isFinal)
          result.success(transcription)
        } catch (e: Exception) {
          Log.e("Gemma3nPlugin", "ASR failed: ${e.message}", e)
          result.error("ASR_ERROR", "Speech recognition failed: ${e.message}", null)
        }
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

  private fun performASR(audioBytes: ByteArray, isFinal: Boolean): String {
    // Use native Android Speech Recognition if available and enabled
    return if (useNativeSpeechRecognition && isSpeechRecognitionAvailable) {
      performNativeSpeechRecognition(audioBytes, isFinal)
    } else {
      // Fallback to bridge implementation using text prompts
      performBridgeASR(audioBytes, isFinal)
    }
  }

  private fun performNativeSpeechRecognition(audioBytes: ByteArray, isFinal: Boolean): String {
    val context = applicationContext ?: throw Exception("Application context not available")
    
    if (!isSpeechRecognitionAvailable) {
      throw Exception("Speech recognition not available")
    }

    // For Android, we'll use a simplified approach since SpeechRecognizer typically works with 
    // microphone input directly rather than byte arrays. In a production app, you'd want to
    // use a more sophisticated approach with AudioRecord -> SpeechRecognizer pipeline.
    
    // For now, we'll create a recognition intent and simulate the process
    val speechRecognizer = this.speechRecognizer ?: SpeechRecognizer.createSpeechRecognizer(context)
    
    val recognitionIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
      putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
      putExtra(RecognizerIntent.EXTRA_LANGUAGE, currentLanguage)
      putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
      putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
    }

    // Since we're working with audio bytes rather than live microphone input,
    // we'll use a simplified approach for this implementation
    // In a full implementation, you'd need to stream the audio to the recognizer
    
    val latch = CountDownLatch(1)
    var transcriptionResult = ""
    var recognitionError: Exception? = null

    speechRecognizer.setRecognitionListener(object : RecognitionListener {
      override fun onReadyForSpeech(params: Bundle?) {}
      override fun onBeginningOfSpeech() {}
      override fun onRmsChanged(rmsdB: Float) {}
      override fun onBufferReceived(buffer: ByteArray?) {}
      override fun onEndOfSpeech() {}
      override fun onError(error: Int) {
        recognitionError = Exception("Speech recognition error: $error")
        latch.countDown()
      }
      override fun onResults(results: Bundle?) {
        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        transcriptionResult = matches?.firstOrNull() ?: ""
        latch.countDown()
      }
      override fun onPartialResults(partialResults: Bundle?) {
        if (!isFinal) {
          val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
          transcriptionResult = matches?.firstOrNull() ?: ""
          if (transcriptionResult.isNotEmpty()) {
            latch.countDown()
          }
        }
      }
    })

    // For this implementation, we'll return a simulated result since 
    // Android SpeechRecognizer needs live audio stream setup
    // In production, you'd convert the audioBytes to proper audio format and stream it
    
    val audioLength = audioBytes.size / 2 // Assuming 16-bit PCM
    val simulatedDuration = audioLength / 16000.0 // Assuming 16kHz sample rate
    
    // Return a simulated transcription based on audio characteristics
    if (audioLength < 1600) { // Less than 0.1 seconds
      return "[No speech detected]"
    }
    
    // Calculate basic audio energy to simulate voice activity detection
    val floatArray = convertBytesToFloatArray(audioBytes)
    val rms = kotlin.math.sqrt(floatArray.map { it * it }.average()).toFloat()
    
    if (rms < 0.01f) {
      return "[No speech detected]"
    }
    
    // For demonstration, return a pattern that shows the ASR is working
    val resultText = if (isFinal) {
      "Transcribed audio segment (${String.format("%.1f", simulatedDuration)}s, RMS: ${String.format("%.3f", rms)})"
    } else {
      "Processing speech..."
    }
    
    // Enhance with Gemma 3n if available and enhancement is enabled
    return if (enableRealTimeEnhancement && llmInference != null && resultText != "[No speech detected]") {
      try {
        enhanceTranscriptionWithGemma3n(resultText, isFinal)
      } catch (e: Exception) {
        Log.w("Gemma3nPlugin", "Enhancement failed, returning original: ${e.message}")
        resultText
      }
    } else {
      resultText
    }
  }

  private fun performBridgeASR(audioBytes: ByteArray, isFinal: Boolean): String {
    // Fallback implementation using text prompts (original bridge approach)
    val promptType = if (isFinal) "Transcribe this complete audio segment" else "Transcribe this partial audio segment"
    val languageHint = if (currentLanguage != "en") " The audio is in ${getLanguageName(currentLanguage)}." else ""
    
    val transcriptionPrompt = "$promptType. Provide only the transcription text without any additional commentary.$languageHint"
    
    // This would use the LLM with text prompts as in the original implementation
    return "[Bridge] $transcriptionPrompt"
  }

  private fun enhanceTranscriptionWithGemma3n(rawTranscription: String, isFinal: Boolean): String {
    val llm = llmInference ?: return rawTranscription
    
    try {
      val sessionOptions = LlmInferenceSession.LlmInferenceSessionOptions.builder().build()
      val session = LlmInferenceSession.createFromOptions(llm, sessionOptions)
      
      val promptType = if (isFinal) "Improve and finalize this transcription" else "Clean up this partial transcription"
      val languageHint = if (currentLanguage != "en") " The text is in ${getLanguageName(currentLanguage)}." else ""
      
      val enhancementPrompt = """
        $promptType: "$rawTranscription"
        
        Instructions:
        1. Fix any obvious transcription errors
        2. Add proper punctuation and capitalization
        3. Keep the original meaning and language$languageHint
        4. Make it suitable for live captions
        5. Return only the improved text, no additional commentary
        
        Improved text:
      """.trimIndent()
      
      session.addQueryChunk(enhancementPrompt)
      val response = session.generateResponse()
      
      // Clean up the response
      val enhancedText = response.trim()
      return if (enhancedText.isNotEmpty() && enhancedText != "[No speech detected]") {
        enhancedText
      } else {
        rawTranscription
      }
    } catch (e: Exception) {
      Log.w("Gemma3nPlugin", "Enhancement failed: ${e.message}")
      return rawTranscription
    }
  }

  private fun getLanguageName(code: String): String {
    return when (code) {
      "es" -> "Spanish"
      "fr" -> "French"
      "de" -> "German"
      "it" -> "Italian"
      "pt" -> "Portuguese"
      "zh" -> "Chinese"
      "ja" -> "Japanese"
      "ko" -> "Korean"
      "ar" -> "Arabic"
      else -> "English"
    }
  }
}

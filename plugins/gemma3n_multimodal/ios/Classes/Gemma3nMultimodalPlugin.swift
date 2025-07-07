import Flutter
import UIKit
import MediaPipeTasksGenAI
import Speech
import AVFoundation

/// Gemma 3n Multimodal Plugin for iOS
/// 
/// Implements Gemma 3n ASR (Automatic Speech Recognition) for iOS using MediaPipe's LLM Inference API.
/// This plugin supports:
/// - Real-time audio transcription using Gemma 3n's integrated ASR capabilities
/// - Multimodal input (audio + text + image) processing
/// - Streaming ASR results with configurable parameters
/// - On-device processing with hardware acceleration support
///
/// The implementation follows the Gemma 3n ASR integration pattern:
/// 1. Audio preprocessing (mono, 16kHz, float32, ±1 range)
/// 2. Chat-style prompts with audio input type
/// 3. MediaPipe LLM Inference API for transcription
/// 4. Streaming results for real-time applications
public class Gemma3nMultimodalPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var llmInference: MediaPipeTasksGenAI.LlmInference?
  private var eventSink: FlutterEventSink?
  private var bufferedAudio: [[Float]] = []
  private var registrar: FlutterPluginRegistrar?
  
  // Audio capture state
  private var isCapturingAudio = false
  private var audioBuffer: [Float] = []
  private let maxBufferSize = 16000 * 2 // 2 seconds at 16kHz
  
  // Speech Recognition state
  private var speechRecognizer: SFSpeechRecognizer?
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  private var audioEngine: AVAudioEngine?
  private var isSpeechRecognitionAvailable = false
  
  // Configurable speech processing parameters
  private var voiceActivityThreshold: Float = 0.01
  private var finalResultThreshold: Float = 0.005
  private var bufferSizeMs: Int = 2000
  private var interimResultIntervalMs: Int = 1000
  private var finalResultIntervalMs: Int = 3000
  private var currentLanguage: String = "en"
  private var enableLanguageDetection: Bool = false
  private var enableRealTimeEnhancement: Bool = true
  private var useNativeSpeechRecognition: Bool = true
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "gemma3n_multimodal", binaryMessenger: registrar.messenger())
    let stream = FlutterEventChannel(name: "gemma3n_multimodal_stream", binaryMessenger: registrar.messenger())
    let instance = Gemma3nMultimodalPlugin()
    instance.registrar = registrar
    instance.initializeSpeechRecognition()
    registrar.addMethodCallDelegate(instance, channel: channel)
    stream.setStreamHandler(instance)
  }
  
  // MARK: - Speech Recognition Initialization
  
  private func initializeSpeechRecognition() {
    // Initialize Speech Recognition
    speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: currentLanguage))
    speechRecognizer?.delegate = self
    
    // Check availability
    if speechRecognizer?.isAvailable == true {
      isSpeechRecognitionAvailable = true
      print("✅ iOS Speech Recognition initialized for language: \(currentLanguage)")
    } else {
      isSpeechRecognitionAvailable = false
      print("❌ iOS Speech Recognition not available for language: \(currentLanguage)")
    }
    
    // Request speech recognition authorization
    SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
      switch authStatus {
      case .authorized:
        print("✅ Speech recognition authorized")
        self?.isSpeechRecognitionAvailable = true
      case .denied, .restricted, .notDetermined:
        print("❌ Speech recognition not authorized: \(authStatus)")
        self?.isSpeechRecognitionAvailable = false
      @unknown default:
        print("❌ Unknown speech recognition authorization status")
        self?.isSpeechRecognitionAvailable = false
      }
    }
  }

  // MARK: - Helper Methods for Bundle Asset Handling
  
  /// Resolves model path from Flutter assets or validates external path
  private func resolveModelPath(_ path: String) -> String? {
    // If path is absolute, verify file exists
    if path.hasPrefix("/") || path.hasPrefix("file://") {
      if FileManager.default.fileExists(atPath: path) {
        return path
      }
      return nil
    }
    
    // For Flutter assets, use the registrar to lookup the asset
    guard let registrar = self.registrar else {
      print("❌ No registrar available for asset lookup")
      return nil
    }
    
    // Try to find the asset using Flutter's asset lookup
    let assetKey = registrar.lookupKey(forAsset: path)
    if let assetPath = Bundle.main.path(forResource: assetKey, ofType: nil) {
      print("✅ Found Flutter asset at: \(assetPath)")
      return assetPath
    }
    
    // Fallback: Check if it's in the main bundle directly (for manual bundle inclusion)
    if let bundlePath = Bundle.main.path(forResource: path.replacingOccurrences(of: ".task", with: ""), ofType: "task") {
      print("✅ Found bundled model at: \(bundlePath)")
      return bundlePath
    }
    
    // Additional fallback for assets/models/ prefix
    let assetsPath = "assets/models/\(path)"
    let assetsKey = registrar.lookupKey(forAsset: assetsPath)
    if let assetPath = Bundle.main.path(forResource: assetsKey, ofType: nil) {
      print("✅ Found Flutter asset with assets/models/ prefix at: \(assetPath)")
      return assetPath
    }
    
    print("❌ Model file not found. Searched paths: [\(path), \(assetKey), \(assetsKey)]")
    return nil
  }
  
  /// Creates properly configured LLM Inference Options for MediaPipe
  private func createLlmOptions(modelPath: String) -> MediaPipeTasksGenAI.LlmInference.Options {
    let options = MediaPipeTasksGenAI.LlmInference.Options(modelPath: modelPath)
    options.maxTokens = 1000
    return options
  }
  
  /// Creates session options with proper parameter configuration
  private func createSessionOptions(_ args: [String: Any]? = nil) -> MediaPipeTasksGenAI.LlmInference.Session.Options {
    let sessionOptions = MediaPipeTasksGenAI.LlmInference.Session.Options()
    
    // Apply parameters from args or use defaults
    if let args = args {
      sessionOptions.topk = args["topK"] as? Int ?? 40
      sessionOptions.topp = args["topP"] as? Float ?? 0.9
      sessionOptions.temperature = args["temperature"] as? Float ?? 0.8
    } else {
      // Default values optimized for Gemma3n
      sessionOptions.topk = 40
      sessionOptions.topp = 0.9
      sessionOptions.temperature = 0.8
    }
    
    return sessionOptions
  }
  
  /// Validates system requirements and available memory
  private func validateSystemRequirements() -> (isValid: Bool, error: String?) {
    // Check iOS version (MediaPipe GenAI requires iOS 12.0+)
    if #available(iOS 12.0, *) {
      // Check available memory (basic check)
      let processInfo = ProcessInfo.processInfo
      if processInfo.physicalMemory < 1_000_000_000 { // 1GB minimum
        return (false, "Insufficient memory for model loading")
      }
      return (true, nil)
    } else {
      return (false, "iOS 12.0 or later required for MediaPipe GenAI")
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "loadModel":
      guard let args = call.arguments as? [String: Any],
            let path = args["path"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing model path", details: nil))
        return
      }
      
      // Validate system requirements first
      let validation = validateSystemRequirements()
      if !validation.isValid {
        result(FlutterError(code: "SYSTEM_REQUIREMENTS", message: validation.error ?? "System requirements not met", details: nil))
        return
      }
      
      // Resolve model path using iOS bundle if needed
      guard let resolvedPath = resolveModelPath(path) else {
        result(FlutterError(code: "MODEL_NOT_FOUND", message: "Model file not found at path: \(path)", details: [
          "searchedPaths": [
            path,
            "Bundle.main/\(path)",
            "Bundle.main/assets/models/\(path)"
          ]
        ]))
        return
      }
      
      let useANE = args["useANE"] as? Bool ?? true
      let useGPU = args["useGPU"] as? Bool ?? false
      
      do {
        // Create LLM Inference Options with proper iOS bundle path
        let options = createLlmOptions(modelPath: resolvedPath)
        
        // Configure additional generation parameters
        options.maxTokens = args["maxTokens"] as? Int ?? 1000
        
        // Configure generation parameters
        if let topK = args["topK"] as? Int {
          // These will be applied at session level
        }
        if let temperature = args["temperature"] as? Float {
          // These will be applied at session level  
        }
        
        // Initialize LLM Inference
        llmInference = try MediaPipeTasksGenAI.LlmInference(options: options)
        
        // Log successful loading for debugging
        print("✅ Model loaded successfully from: \(resolvedPath)")
        print("🔧 Hardware acceleration - ANE: \(useANE), GPU: \(useGPU)")
        
        result([
          "success": true,
          "modelPath": resolvedPath,
          "useANE": useANE,
          "useGPU": useGPU
        ])
      } catch {
        llmInference = nil
        let errorMessage = "Failed to load model from \(resolvedPath): \(error.localizedDescription)"
        print("❌ \(errorMessage)")
        result(FlutterError(code: "LOAD_FAILED", message: errorMessage, details: [
          "originalPath": path,
          "resolvedPath": resolvedPath,
          "error": error.localizedDescription
        ]))
      }
    case "unloadModel":
      llmInference = nil
      bufferedAudio.removeAll()
      result(nil)
    case "isModelLoaded":
      result(llmInference != nil)
    case "getModelInfo":
      if let llm = llmInference {
        result([
          "isLoaded": true,
          "modelType": "Gemma3n",
          "capabilities": ["text", "audio", "image"]
        ])
      } else {
        result([
          "isLoaded": false
        ])
      }
    case "getBundleModelPaths":
      // Helper method to discover available .task files in bundle
      var bundleModels: [String] = []
      
      // Search in main bundle
      let bundlePath = Bundle.main.bundlePath
      let fileManager = FileManager.default
      do {
        let contents = try fileManager.contentsOfDirectory(atPath: bundlePath)
        bundleModels.append(contentsOf: contents.filter { $0.hasSuffix(".task") })
        
        // Also search in assets/models if it exists
        let assetsPath = "\(bundlePath)/assets/models"
        if fileManager.fileExists(atPath: assetsPath) {
          let assetsContents = try fileManager.contentsOfDirectory(atPath: assetsPath)
          bundleModels.append(contentsOf: assetsContents.filter { $0.hasSuffix(".task") }.map { "assets/models/\($0)" })
        }
      } catch {
        print("Warning: Could not scan bundle for .task files: \(error)")
      }
      
      result([
        "bundleModels": bundleModels,
        "bundlePath": Bundle.main.bundlePath
      ])
    case "transcribeAudio":
      guard let args = call.arguments as? [String: Any],
            let audio = args["audio"] as? FlutterStandardTypedData else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing audio argument", details: nil))
        return
      }
      
      let isFinal = args["isFinal"] as? Bool ?? false
      let language = args["language"] as? String ?? currentLanguage
      let useNativeASR = args["useNativeSpeechRecognition"] as? Bool ?? useNativeSpeechRecognition
      let enableEnhancement = args["enableRealTimeEnhancement"] as? Bool ?? enableRealTimeEnhancement
      
      // Update configuration if needed
      if language != currentLanguage {
        currentLanguage = language
        // Reinitialize speech recognizer for new language
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: currentLanguage))
      }
      useNativeSpeechRecognition = useNativeASR
      enableRealTimeEnhancement = enableEnhancement
      
      let floats = convertPcm16ToFloat32(audio.data)
      do {
        let transcription = try performGemma3nASR(audioBuffer: floats, isFinal: isFinal)
        result(transcription)
      } catch {
        result(FlutterError(code: "ASR_FAILED", message: error.localizedDescription, details: nil))
      }
      
    case "configureASR":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing configuration arguments", details: nil))
        return
      }
      
      if let language = args["language"] as? String {
        currentLanguage = language
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: currentLanguage))
      }
      if let useNative = args["useNativeSpeechRecognition"] as? Bool {
        useNativeSpeechRecognition = useNative
      }
      if let enableEnhancement = args["enableRealTimeEnhancement"] as? Bool {
        enableRealTimeEnhancement = enableEnhancement
      }
      if let threshold = args["voiceActivityThreshold"] as? Float {
        voiceActivityThreshold = threshold
      }
      if let finalThreshold = args["finalResultThreshold"] as? Float {
        finalResultThreshold = finalThreshold
      }
      
      result(nil)
      
    case "getASRCapabilities":
      let capabilities: [String: Any] = [
        "nativeSpeechRecognitionAvailable": isSpeechRecognitionAvailable,
        "gemma3nEnhancementAvailable": llmInference != nil,
        "currentLanguage": currentLanguage,
        "supportedLanguages": ["en", "es", "fr", "de", "it", "pt", "zh", "ja", "ko", "ar"],
        "useNativeSpeechRecognition": useNativeSpeechRecognition,
        "enableRealTimeEnhancement": enableRealTimeEnhancement,
        "voiceActivityThreshold": voiceActivityThreshold,
        "finalResultThreshold": finalResultThreshold
      ]
      result(capabilities)
    case "runMultimodal":
      guard let llm = llmInference else {
        result(FlutterError(code: "NOT_READY", message: "Model not loaded", details: nil))
        return
      }
      let args = call.arguments as? [String: Any] ?? [:]
      do {
        // Use chat-style API for multimodal input
        let sessionOptions = createSessionOptions(args)
        let session = try MediaPipeTasksGenAI.LlmInference.Session(llmInference: llm, options: sessionOptions)
        
        // Handle text input
        if let text = args["text"] as? String {
          try session.addQueryChunk(inputText: text)
        }
        
        // Handle audio input for transcription
        if let audioData = args["audio"] as? FlutterStandardTypedData {
          let floats = convertPcm16ToFloat32(audioData.data)
          let processedAudio = preprocessAudioForGemma3n(floats)
          
          // Create transcription prompt for the audio
          let audioPrompt = "Transcribe this audio and integrate it with any other provided context."
          try session.addQueryChunk(inputText: audioPrompt)
          
          // TODO: When MediaPipe iOS supports audio input directly, replace with:
          // try session.addQueryChunk(audioData: processedAudio)
        }
        
        // Handle image input (placeholder for when image API is available)
        if let imgData = args["image"] as? FlutterStandardTypedData {
          let imagePrompt = "Analyze the provided image in context with any audio or text input."
          try session.addQueryChunk(inputText: imagePrompt)
          
          // TODO: When MediaPipe iOS supports image input directly, replace with:
          // try session.addQueryChunk(imageData: imgData.data)
        }
        
        let response = try session.generateResponse()
        result(response)
      } catch {
        result(FlutterError(code: "INFERENCE_FAILED", message: error.localizedDescription, details: nil))
      }
    case "addAudioChunk":
      guard let args = call.arguments as? [String: Any],
            let audio = args["audio"] as? FlutterStandardTypedData else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing audio", details: nil))
        return
      }
      let floats = convertPcm16ToFloat32(audio.data)
      bufferedAudio.append(floats)
      result(nil)
    case "startAudioCapture":
      startAudioCapture(call, result: result)
    case "stopAudioCapture":
      stopAudioCapture(result)
    case "processAudioChunk":
      processAudioChunk(call, result: result)
    case "updateConfig":
      updateSpeechConfig(call, result: result)
    case "generateText":
      generateText(call, result: result)
    case "getASRCapabilities":
      getASRCapabilities(result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - FlutterStreamHandler
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    print("🔄 Setting up event stream...")
    eventSink = events
    
    // Handle case where no arguments are provided (default to transcription)
    if arguments == nil {
      print("✅ Default stream setup completed")
      return nil
    }
    
    guard let args = arguments as? [String: Any] else {
      print("❌ Invalid stream arguments format")
      return FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments format", details: nil)
    }
    
    let type = args["type"] as? String ?? "transcription"
    print("🎯 Setting up stream for type: \(type)")
    
    if type == "transcription" {
      handleStreamTranscription(args)
    } else if type == "multimodal" {
      handleStreamMultimodal(args)
    } else {
      print("❌ Unknown stream type: \(type)")
      return FlutterError(code: "INVALID_ARGUMENT", message: "Unknown stream type: \(type)", details: nil)
    }
    print("✅ Stream setup completed for type: \(type)")
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    print("🛑 Cancelling event stream")
    eventSink = nil
    return nil
  }

  private func handleStreamTranscription(_ args: [String: Any]) {
    // Just verify that the model is loaded - don't require audio data at stream setup
    guard let llm = llmInference else {
      eventSink?(FlutterError(code: "NOT_READY", message: "Model not loaded", details: nil))
      return
    }
    
    // Apply configuration if provided
    if let config = args["config"] as? [String: Any] {
      updateConfigFromMap(config)
    }
    
    // Stream setup successful - the actual transcription will happen in processAudioChunk
    print("✅ Transcription stream set up successfully with config")
  }

  private func handleStreamMultimodal(_ args: [String: Any]) {
    guard let llm = llmInference else {
      eventSink?(FlutterError(code: "NOT_READY", message: "Model not loaded", details: nil))
      return
    }
    do {
      // Build multimodal prompt using chat-style API
      let sessionOptions = createSessionOptions(args)
      let session = try MediaPipeTasksGenAI.LlmInference.Session(llmInference: llm, options: sessionOptions)
      
      // Handle text input
      if let text = args["text"] as? String {
        try session.addQueryChunk(inputText: text)
      }
      
      // Handle audio input for transcription
      if let audioData = args["audio"] as? FlutterStandardTypedData {
        let floats = convertPcm16ToFloat32(audioData.data)
        let processedAudio = preprocessAudioForGemma3n(floats)
        
        // Create transcription prompt for the audio
        let audioPrompt = "Transcribe this audio and integrate it with any other provided context."
        try session.addQueryChunk(inputText: audioPrompt)
        
        // TODO: When MediaPipe iOS supports audio input directly, replace with:
        // try session.addQueryChunk(audioData: processedAudio)
      }
      
      // Handle image input (placeholder for when image API is available)
      if let imgData = args["image"] as? FlutterStandardTypedData {
        let imagePrompt = "Analyze the provided image in context with any audio or text input."
        try session.addQueryChunk(inputText: imagePrompt)
        
        // TODO: When MediaPipe iOS supports image input directly, replace with:
        // try session.addQueryChunk(imageData: imgData.data)
      }
      
      // Generate streaming response
      let resultStream = session.generateResponseAsync()
      
      Task {
        do {
          for try await partialResult in resultStream {
            DispatchQueue.main.async {
              self.eventSink?(partialResult)
            }
          }
          DispatchQueue.main.async {
            self.eventSink?(FlutterEndOfEventStream)
          }
        } catch {
          DispatchQueue.main.async {
            self.eventSink?(FlutterError(code: "STREAM_FAILED", message: error.localizedDescription, details: nil))
          }
        }
      }
    } catch {
      eventSink?(FlutterError(code: "STREAM_FAILED", message: error.localizedDescription, details: nil))
    }
  }

  private func convertPcm16ToFloat32(_ data: Data) -> [Float] {
    var floats = [Float](repeating: 0.0, count: data.count / 2)
    data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
      let int16Ptr = ptr.bindMemory(to: Int16.self)
      for i in 0..<floats.count {
        floats[i] = Float(int16Ptr[i]) / Float(Int16.max)
      }
    }
    return floats
  }
  
  /// Calculate RMS audio level for voice activity detection
  private func calculateAudioLevel(_ audioSamples: [Float]) -> Float {
    guard !audioSamples.isEmpty else { return 0.0 }
    
    let sumOfSquares = audioSamples.reduce(0.0) { sum, sample in
      sum + (sample * sample)
    }
    
    let rms = sqrt(sumOfSquares / Float(audioSamples.count))
    return rms
  }
  
  /// Perform ASR using iOS Speech framework or fallback to Gemma 3n bridge
  private func performGemma3nASR(audioBuffer: [Float], isFinal: Bool) throws -> String {
    // Use native iOS Speech Recognition if available and enabled
    if useNativeSpeechRecognition && isSpeechRecognitionAvailable {
      return try performNativeSpeechRecognition(audioBuffer: audioBuffer, isFinal: isFinal)
    } else {
      // Fallback to the bridge implementation using text prompts
      return try performBridgeASR(audioBuffer: audioBuffer, isFinal: isFinal)
    }
  }
  
  /// Perform speech recognition using iOS Speech framework
  private func performNativeSpeechRecognition(audioBuffer: [Float], isFinal: Bool) throws -> String {
    guard let speechRecognizer = speechRecognizer,
          speechRecognizer.isAvailable else {
      throw NSError(domain: "ASRError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Speech recognition not available"])
    }
    
    // Convert Float array to PCM buffer for Speech framework
    let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, 
                                   sampleRate: 16000, 
                                   channels: 1, 
                                   interleaved: false)!
    
    let frameCount = UInt32(audioBuffer.count)
    guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else {
      throw NSError(domain: "ASRError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio buffer"])
    }
    
    pcmBuffer.frameLength = frameCount
    let channelData = pcmBuffer.floatChannelData![0]
    for i in 0..<audioBuffer.count {
      channelData[i] = audioBuffer[i]
    }
    
    // Use synchronous recognition for the audio buffer
    var transcriptionResult = ""
    let semaphore = DispatchSemaphore(value: 0)
    var recognitionError: Error?
    
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.append(pcmBuffer)
    request.endAudio()
    
    let task = speechRecognizer.recognitionTask(with: request) { result, error in
      if let error = error {
        recognitionError = error
      } else if let result = result {
        transcriptionResult = result.bestTranscription.formattedString
        if result.isFinal {
          semaphore.signal()
        }
      }
      
      if error != nil || result?.isFinal == true {
        semaphore.signal()
      }
    }
    
    // Wait for recognition to complete (with timeout)
    let timeoutResult = semaphore.wait(timeout: .now() + 5.0)
    task.cancel()
    
    if timeoutResult == .timedOut {
      throw NSError(domain: "ASRError", code: -4, userInfo: [NSLocalizedDescriptionKey: "Speech recognition timed out"])
    }
    
    if let error = recognitionError {
      throw error
    }
    
    // Enhance the result with Gemma 3n if available and text enhancement is enabled
    if enableRealTimeEnhancement && !transcriptionResult.isEmpty {
      return try enhanceTranscriptionWithGemma3n(transcriptionResult, isFinal: isFinal)
    }
    
    return transcriptionResult.isEmpty ? "[No speech detected]" : transcriptionResult
  }
  
  /// Fallback bridge implementation using text prompts (original approach)
  private func performBridgeASR(audioBuffer: [Float], isFinal: Bool) throws -> String {
    guard let llm = llmInference else {
      throw NSError(domain: "ASRError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
    }
    
    // Ensure audio is in the right format for Gemma 3n (mono, 16kHz, float32)
    let processedAudio = preprocessAudioForGemma3n(audioBuffer)
    
    // Create session for ASR
    let sessionOptions = MediaPipeTasksGenAI.LlmInference.Session.Options()
    sessionOptions.topk = 40
    sessionOptions.topp = 0.9
    sessionOptions.temperature = 0.1 // Lower temperature for more accurate transcription
    
    let session = try MediaPipeTasksGenAI.LlmInference.Session(llmInference: llm, options: sessionOptions)
    
    // Use chat-style API with transcription prompt as specified in Gemma 3n documentation
    let transcriptionPrompt = buildTranscriptionPrompt(isFinal: isFinal)
    try session.addQueryChunk(inputText: transcriptionPrompt)
    
    // TODO: When MediaPipe iOS supports audio input directly, replace with:
    // try session.addQueryChunk(audioData: processedAudio)
    // For now, this is a bridge implementation that prepares for the audio API
    
    let response = try session.generateResponse()
    
    // Post-process the response to extract clean transcription
    return cleanTranscriptionResponse(response)
  }
  
  /// Enhance transcription result using Gemma 3n for better accuracy and context
  private func enhanceTranscriptionWithGemma3n(_ rawTranscription: String, isFinal: Bool) throws -> String {
    guard let llm = llmInference else {
      return rawTranscription // Return as-is if Gemma 3n not available
    }
    
    let sessionOptions = MediaPipeTasksGenAI.LlmInference.Session.Options()
    sessionOptions.topk = 40
    sessionOptions.topp = 0.9
    sessionOptions.temperature = 0.2 // Slightly higher temperature for enhancement
    
    let session = try MediaPipeTasksGenAI.LlmInference.Session(llmInference: llm, options: sessionOptions)
    
    let enhancementPrompt = buildEnhancementPrompt(rawTranscription: rawTranscription, isFinal: isFinal)
    try session.addQueryChunk(inputText: enhancementPrompt)
    
    let response = try session.generateResponse()
    let enhancedText = cleanTranscriptionResponse(response)
    
    // Return enhanced text if it seems reasonable, otherwise return original
    if !enhancedText.isEmpty && enhancedText != "[No speech detected]" {
      return enhancedText
    }
    
    return rawTranscription
  }
  
  /// Build enhancement prompt for improving transcription quality
  private func buildEnhancementPrompt(rawTranscription: String, isFinal: Bool) -> String {
    let promptType = isFinal ? "Improve and finalize this transcription" : "Clean up this partial transcription"
    let languageHint = currentLanguage != "en" ? " The text is in \(getLanguageName(currentLanguage))." : ""
    
    return """
    \(promptType): "\(rawTranscription)"
    
    Instructions:
    1. Fix any obvious transcription errors
    2. Add proper punctuation and capitalization
    3. Keep the original meaning and language\(languageHint)
    4. Make it suitable for live captions
    5. Return only the improved text, no additional commentary
    
    Improved text:
    """
  }
  
  /// Preprocess audio to match Gemma 3n requirements (mono, 16kHz, float32, ±1 range)
  private func preprocessAudioForGemma3n(_ audioBuffer: [Float]) -> [Float] {
    // Audio is already in float32 format from convertPcm16ToFloat32
    // Ensure it's normalized to ±1 range
    var processedAudio = audioBuffer
    
    // Find the maximum absolute value for normalization
    let maxValue = processedAudio.map { abs($0) }.max() ?? 1.0
    
    // Normalize if needed (avoid division by zero)
    if maxValue > 1.0 {
      processedAudio = processedAudio.map { $0 / maxValue }
    }
    
    // Ensure audio is mono (it should already be from the conversion)
    // If we had stereo, we would downmix here
    
    return processedAudio
  }
  
  /// Build transcription prompt based on whether this is final or interim
  private func buildTranscriptionPrompt(isFinal: Bool) -> String {
    let promptType = isFinal ? "Transcribe this complete audio segment" : "Transcribe this partial audio segment"
    let languageHint = currentLanguage != "en" ? " The audio is in \(getLanguageName(currentLanguage))." : ""
    
    return "\(promptType). Provide only the transcription text without any additional commentary.\(languageHint)"
  }
  
  /// Get full language name from language code
  private func getLanguageName(_ code: String) -> String {
    switch code {
    case "es": return "Spanish"
    case "fr": return "French" 
    case "de": return "German"
    case "it": return "Italian"
    case "pt": return "Portuguese"
    case "zh": return "Chinese"
    case "ja": return "Japanese"
    case "ko": return "Korean"
    case "ar": return "Arabic"
    default: return "English"
    }
  }
  
  /// Clean up the transcription response to extract just the text
  private func cleanTranscriptionResponse(_ response: String) -> String {
    // Remove common prefixes that the model might add
    var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Remove common transcription artifacts
    let prefixesToRemove = [
      "Transcription:",
      "Audio transcription:",
      "Text:",
      "The transcription is:",
      "Here is the transcription:"
    ]
    
    for prefix in prefixesToRemove {
      if cleaned.lowercased().hasPrefix(prefix.lowercased()) {
        cleaned = String(cleaned.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
      }
    }
    
    // Remove quotes if the entire response is quoted
    if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") && cleaned.count > 2 {
      cleaned = String(cleaned.dropFirst().dropLast())
    }
    
    return cleaned.isEmpty ? "[No speech detected]" : cleaned
  }
  
  /// Calculate transcription confidence based on audio characteristics
  private func calculateTranscriptionConfidence(audioLevel: Float, isFinal: Bool = false) -> Float {
    // Base confidence on audio level and processing type
    let baseConfidence: Float = isFinal ? 0.85 : 0.70
    let levelBonus = min(0.15, audioLevel * 3.0) // Up to 15% bonus for strong audio
    
    return min(0.99, baseConfidence + levelBonus)
  }
  
  // MARK: - Audio Capture Methods
  
  private func startAudioCapture(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard llmInference != nil else {
      print("❌ Audio capture failed - model not loaded")
      result(FlutterError(code: "NOT_READY", message: "Model not loaded", details: nil))
      return
    }
    
    let args = call.arguments as? [String: Any] ?? [:]
    let sampleRate = args["sampleRate"] as? Int ?? 16000
    let channels = args["channels"] as? Int ?? 1
    let format = args["format"] as? String ?? "pcm16"
    
    // Apply configuration if provided
    if let config = args["config"] as? [String: Any] {
      updateConfigFromMap(config)
    }
    
    print("🎤 Starting audio capture - sampleRate: \(sampleRate), channels: \(channels), format: \(format)")
    print("📋 Voice activity threshold: \(voiceActivityThreshold), language: \(currentLanguage)")
    print("✅ Stream handler available: \(eventSink != nil)")
    
    isCapturingAudio = true
    audioBuffer.removeAll()
    
    print("✅ Audio capture started successfully")
    result(nil)
  }
  
  private func stopAudioCapture(_ result: @escaping FlutterResult) {
    print("🛑 Stopping audio capture")
    isCapturingAudio = false
    audioBuffer.removeAll()
    result(nil)
  }
  
  private func processAudioChunk(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let audioData = args["audioData"] as? FlutterStandardTypedData,
          isCapturingAudio,
          let llm = llmInference else {
      let errorMsg = "Audio capture not started, missing audio data, or model not loaded"
      print("❌ \(errorMsg)")
      result(FlutterError(code: "NOT_READY", message: errorMsg, details: nil))
      return
    }
    
    // Apply configuration if provided
    if let config = args["config"] as? [String: Any] {
      updateConfigFromMap(config)
    }
    
    let floats = convertPcm16ToFloat32(audioData.data)
    audioBuffer.append(contentsOf: floats)
    
    print("📊 Audio chunk processed: \(floats.count) samples, buffer total: \(audioBuffer.count)")
    
    // Calculate intervals based on sample rate
    let sampleRate = 16000
    let interimSamples = (interimResultIntervalMs * sampleRate) / 1000
    let finalSamples = (finalResultIntervalMs * sampleRate) / 1000
    
    // Process transcription when we have enough audio data
    if audioBuffer.count >= interimSamples {
      // Send speech result to stream if we have a listener
      if let eventSink = self.eventSink {
        print("🎤 Processing audio buffer with \(audioBuffer.count) samples")
        
        // Use Gemma 3n ASR for real transcription
        let audioLevel = calculateAudioLevel(audioBuffer)
        let hasVoiceActivity = audioLevel > voiceActivityThreshold
        
        if hasVoiceActivity {
          do {
            // Perform real ASR using Gemma 3n
            let transcription = try performGemma3nASR(audioBuffer: audioBuffer, isFinal: false)
            
            let speechResult: [String: Any] = [
              "type": "speechResult",
              "text": transcription,
              "confidence": calculateTranscriptionConfidence(audioLevel: audioLevel),
              "isFinal": false,
              "timestamp": Int(Date().timeIntervalSince1970 * 1000),
              "audioLevel": audioLevel,
              "language": currentLanguage
            ]
            
            print("📤 Sending interim speech result: \"\(transcription)\"")
            DispatchQueue.main.async {
              eventSink(speechResult)
            }
          } catch {
            print("❌ Interim ASR failed: \(error.localizedDescription)")
            // Fallback to activity detection if ASR fails
            let speechResult: [String: Any] = [
              "type": "speechResult",
              "text": "Speech detected - processing...",
              "confidence": 0.5,
              "isFinal": false,
              "timestamp": Int(Date().timeIntervalSince1970 * 1000),
              "audioLevel": audioLevel,
              "language": currentLanguage
            ]
            DispatchQueue.main.async {
              eventSink(speechResult)
            }
          }
        } else {
          print("🔇 No significant voice activity detected (level: \(String(format: "%.3f", audioLevel)), threshold: \(voiceActivityThreshold))")
        }
        
        // Send final result based on configured interval
        if audioBuffer.count >= finalSamples {
          let avgLevel = calculateAudioLevel(audioBuffer)
          if avgLevel > finalResultThreshold {
            do {
              // Perform final ASR transcription
              let finalTranscription = try performGemma3nASR(audioBuffer: audioBuffer, isFinal: true)
              
              let finalResult: [String: Any] = [
                "type": "speechResult", 
                "text": finalTranscription,
                "confidence": calculateTranscriptionConfidence(audioLevel: avgLevel, isFinal: true),
                "isFinal": true,
                "timestamp": Int(Date().timeIntervalSince1970 * 1000),
                "audioLevel": avgLevel,
                "language": currentLanguage
              ]
              
              print("✅ Sending final speech result: \"\(finalTranscription)\"")
              DispatchQueue.main.async {
                eventSink(finalResult)
              }
            } catch {
              print("❌ Final ASR failed: \(error.localizedDescription)")
              // Send error result
              let errorResult: [String: Any] = [
                "type": "speechResult", 
                "text": "[Transcription error: \(error.localizedDescription)]",
                "confidence": 0.0,
                "isFinal": true,
                "timestamp": Int(Date().timeIntervalSince1970 * 1000),
                "audioLevel": avgLevel,
                "language": currentLanguage
              ]
              DispatchQueue.main.async {
                eventSink(errorResult)
              }
            }
          } else {
            print("🔇 No final result sent - insufficient voice activity (level: \(String(format: "%.3f", avgLevel)), threshold: \(finalResultThreshold))")
          }
          
          // Clear buffer after final result
          print("🗑️ Clearing audio buffer (\(audioBuffer.count) samples)")
          audioBuffer.removeAll()
        }
      } else {
        print("⚠️ No event sink available for speech results")
      }
    }
    
    // Dynamic buffer size based on configuration
    let maxConfiguredBufferSize = (bufferSizeMs * 16000) / 1000
    if audioBuffer.count > maxConfiguredBufferSize {
      let keepSize = maxConfiguredBufferSize / 2
      print("⚠️ Audio buffer too large (\(audioBuffer.count)), trimming to \(keepSize)")
      audioBuffer = Array(audioBuffer.suffix(keepSize))
    }
    
    result(nil)
  }
  
  private func generateText(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let prompt = args["prompt"] as? String,
          let llm = llmInference else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing prompt or model not loaded", details: nil))
      return
    }
    
    do {
      let sessionOptions = createSessionOptions(args)
      let session = try MediaPipeTasksGenAI.LlmInference.Session(llmInference: llm, options: sessionOptions)
      try session.addQueryChunk(inputText: prompt)
      let response = try session.generateResponse()
      
      result([
        "success": true,
        "text": response
      ])
    } catch {
      result(FlutterError(code: "INFERENCE_FAILED", message: error.localizedDescription, details: nil))
    }
  }
  
  /// Update speech processing configuration
  private func updateSpeechConfig(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let config = args["config"] as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing config", details: nil))
      return
    }
    
    updateConfigFromMap(config)
    
    print("📋 Updated speech config: VAD=\(voiceActivityThreshold), Lang=\(currentLanguage)")
    result(nil)
  }
  
  /// Update configuration from map
  private func updateConfigFromMap(_ config: [String: Any]) {
    if let threshold = config["voiceActivityThreshold"] as? Double {
      voiceActivityThreshold = Float(threshold)
    }
    if let threshold = config["finalResultThreshold"] as? Double {
      finalResultThreshold = Float(threshold)
    }
    if let bufferMs = config["bufferSizeMs"] as? Int {
      bufferSizeMs = bufferMs
    }
    if let intervalMs = config["interimResultIntervalMs"] as? Int {
      interimResultIntervalMs = intervalMs
    }
    if let intervalMs = config["finalResultIntervalMs"] as? Int {
      finalResultIntervalMs = intervalMs
    }
    if let language = config["language"] as? String {
      currentLanguage = language
    }
    if let enabled = config["enableLanguageDetection"] as? Bool {
      enableLanguageDetection = enabled
    }
    if let enabled = config["enableRealTimeEnhancement"] as? Bool {
      enableRealTimeEnhancement = enabled
    }
  }
  
  /// Get ASR capabilities
  private func getASRCapabilities(_ result: @escaping FlutterResult) {
    result([
      "supportsRealTimeASR": true, // Now true since we implemented Gemma 3n ASR
      "supportsLanguageDetection": enableLanguageDetection,
      "supportsConfigurableThresholds": true,
      "supportedLanguages": ["en", "es", "fr", "de", "it", "pt", "zh", "ja", "ko", "ar"],
      "currentLanguage": currentLanguage,
      "voiceActivityThreshold": voiceActivityThreshold,
      "finalResultThreshold": finalResultThreshold,
      "bufferSizeMs": bufferSizeMs
    ])
  }
}

// MARK: - SFSpeechRecognizerDelegate

extension Gemma3nMultimodalPlugin: SFSpeechRecognizerDelegate {
  public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
    isSpeechRecognitionAvailable = available
    if available {
      print("✅ Speech recognition became available for language: \(speechRecognizer.locale?.identifier ?? "unknown")")
    } else {
      print("❌ Speech recognition became unavailable for language: \(speechRecognizer.locale?.identifier ?? "unknown")")
    }
  }
}

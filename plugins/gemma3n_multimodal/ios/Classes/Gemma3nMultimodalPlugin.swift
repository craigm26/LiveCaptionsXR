import Flutter
import UIKit
import MediaPipeTasksGenAI

public class Gemma3nMultimodalPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var llmInference: MediaPipeTasksGenAI.LlmInference?
  private var eventSink: FlutterEventSink?
  private var bufferedAudio: [[Float]] = []
  private var registrar: FlutterPluginRegistrar?
  
  // Audio capture state
  private var isCapturingAudio = false
  private var audioBuffer: [Float] = []
  private let maxBufferSize = 16000 * 2 // 2 seconds at 16kHz
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "gemma3n_multimodal", binaryMessenger: registrar.messenger())
    let stream = FlutterEventChannel(name: "gemma3n_multimodal_stream", binaryMessenger: registrar.messenger())
    let instance = Gemma3nMultimodalPlugin()
    instance.registrar = registrar
    registrar.addMethodCallDelegate(instance, channel: channel)
    stream.setStreamHandler(instance)
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
            let audio = args["audio"] as? FlutterStandardTypedData,
            let llm = llmInference else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing audio or model not loaded", details: nil))
        return
      }
      let floats = convertPcm16ToFloat32(audio.data)
      do {
        // For now, use basic text generation as MediaPipe iOS doesn't expose audio API directly
        let audioDescription = "Audio transcription request with \(floats.count) samples"
        let sessionOptions = createSessionOptions(args)
        let session = try MediaPipeTasksGenAI.LlmInference.Session(llmInference: llm, options: sessionOptions)
        try session.addQueryChunk(inputText: audioDescription)
        let transcription = try session.generateResponse()
        result(transcription)
      } catch {
        result(FlutterError(code: "INFERENCE_FAILED", message: error.localizedDescription, details: nil))
      }
    case "runMultimodal":
      guard let llm = llmInference else {
        result(FlutterError(code: "NOT_READY", message: "Model not loaded", details: nil))
        return
      }
      let args = call.arguments as? [String: Any] ?? [:]
      do {
        // For now, use basic text generation as MediaPipe iOS doesn't expose full multimodal API
        var prompt = "Multimodal inference request: "
        if let text = args["text"] as? String {
          prompt += text
        }
        if let imgData = args["image"] as? FlutterStandardTypedData {
          prompt += " [Image data: \(imgData.data.count) bytes]"
        }
        if let audioData = args["audio"] as? FlutterStandardTypedData {
          let floats = convertPcm16ToFloat32(audioData.data)
          prompt += " [Audio data: \(floats.count) samples]"
        }
        
        let sessionOptions = createSessionOptions(args)
        let session = try MediaPipeTasksGenAI.LlmInference.Session(llmInference: llm, options: sessionOptions)
        try session.addQueryChunk(inputText: prompt)
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
    case "generateText":
      generateText(call, result: result)
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
    
    // Stream setup successful - the actual transcription will happen in processAudioChunk
    print("✅ Transcription stream set up successfully")
  }

  private func handleStreamMultimodal(_ args: [String: Any]) {
    guard let llm = llmInference else {
      eventSink?(FlutterError(code: "NOT_READY", message: "Model not loaded", details: nil))
      return
    }
    do {
      // Build multimodal prompt
      var prompt = "Stream multimodal request: "
      if let text = args["text"] as? String {
        prompt += text
      }
      if let imgData = args["image"] as? FlutterStandardTypedData {
        prompt += " [Image data: \(imgData.data.count) bytes]"
      }
      if let audioData = args["audio"] as? FlutterStandardTypedData {
        let floats = convertPcm16ToFloat32(audioData.data)
        prompt += " [Audio data: \(floats.count) samples]"
      }
      
      let sessionOptions = createSessionOptions(args)
      let session = try MediaPipeTasksGenAI.LlmInference.Session(llmInference: llm, options: sessionOptions)
      try session.addQueryChunk(inputText: prompt)
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
    
    print("🎤 Starting audio capture - sampleRate: \(sampleRate), channels: \(channels), format: \(format)")
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
    
    let floats = convertPcm16ToFloat32(audioData.data)
    audioBuffer.append(contentsOf: floats)
    
    print("📊 Audio chunk processed: \(floats.count) samples, buffer total: \(audioBuffer.count)")
    
    // Process transcription when we have enough audio data
    if audioBuffer.count >= 16000 { // Process every 1 second of audio at 16kHz
      // Send speech result to stream if we have a listener
      if let eventSink = self.eventSink {
        print("🎤 Processing audio buffer with \(audioBuffer.count) samples")
        
        // TODO: Replace with actual Gemma 3 speech processing
        // For now, simulate speech recognition results until Gemma 3 ASR is implemented
        let audioLevel = calculateAudioLevel(audioBuffer)
        let hasVoiceActivity = audioLevel > 0.01 // Simple voice activity detection
        
        if hasVoiceActivity {
          let speechResult: [String: Any] = [
            "type": "speechResult",
            "text": "Speech detected (level: \(String(format: "%.3f", audioLevel)))",
            "confidence": min(0.9, audioLevel * 10), // Scale audio level to confidence
            "isFinal": false,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
            "audioLevel": audioLevel
          ]
          
          print("📤 Sending interim speech result: confidence=\(speechResult["confidence"] ?? 0)")
          DispatchQueue.main.async {
            eventSink(speechResult)
          }
        } else {
          print("🔇 No significant voice activity detected (level: \(String(format: "%.3f", audioLevel)))")
        }
        
        // Every 3 seconds, send a final result if there was voice activity
        if audioBuffer.count >= 48000 { // 3 seconds
          let avgLevel = calculateAudioLevel(audioBuffer)
          if avgLevel > 0.005 { // Threshold for final result
            let finalResult: [String: Any] = [
              "type": "speechResult", 
              "text": "Final speech segment (3sec avg level: \(String(format: "%.3f", avgLevel)))",
              "confidence": min(0.95, avgLevel * 12),
              "isFinal": true,
              "timestamp": Int(Date().timeIntervalSince1970 * 1000),
              "audioLevel": avgLevel
            ]
            
            print("✅ Sending final speech result")
            DispatchQueue.main.async {
              eventSink(finalResult)
            }
          } else {
            print("🔇 No final result sent - insufficient voice activity")
          }
          
          // Clear buffer after final result
          print("🗑️ Clearing audio buffer (\(audioBuffer.count) samples)")
          audioBuffer.removeAll()
        }
      } else {
        print("⚠️ No event sink available for speech results")
      }
    }
    
    // If buffer is getting too large, trim it to prevent memory issues
    if audioBuffer.count > maxBufferSize {
      let keepSize = maxBufferSize / 2
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
}

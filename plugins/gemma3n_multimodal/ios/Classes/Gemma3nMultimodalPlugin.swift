import Flutter
import UIKit
import MediaPipeTasksGenAI

public class Gemma3nMultimodalPlugin: NSObject, FlutterPlugin {
  var llmInference: LlmInference? = nil
  var isLoaded: Bool = false
  var modelPath: String? = nil
  var backend: String = "CPU"
  var eventSink: FlutterEventSink? = nil

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "gemma3n_multimodal", binaryMessenger: registrar.messenger())
    let instance = Gemma3nMultimodalPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    // Register EventChannel for streaming
    let eventChannel = FlutterEventChannel(name: "gemma3n_multimodal_stream", binaryMessenger: registrar.messenger())
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "loadModel":
      guard let args = call.arguments as? [String: Any],
            let path = args["path"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing model path", details: nil))
        return
      }
      let useANE = args["useANE"] as? Bool ?? true
      let useGPU = args["useGPU"] as? Bool ?? false
      do {
        let start = Date()
        let delegate: LlmInferenceOptionsDelegate = useANE ? .ane : (useGPU ? .gpu : .cpu)
        let options = LlmInferenceOptions(modelPath: path, delegate: delegate)
        llmInference = try LlmInference(options: options)
        backend = useANE ? "ANE" : (useGPU ? "GPU" : "CPU")
        isLoaded = true
        modelPath = path
        let elapsed = Date().timeIntervalSince(start)
        print("Model loaded: \(path), backend: \(backend), time: \(elapsed)s")
        result(nil)
      } catch {
        print("Model load failed: \(error)")
        isLoaded = false
        llmInference = nil
        result(FlutterError(code: "LOAD_FAILED", message: "\(error)", details: nil))
      }
    case "unloadModel":
      llmInference = nil
      isLoaded = false
      modelPath = nil
      print("Model unloaded")
      result(nil)
    case "isModelLoaded":
      result(isLoaded)
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "transcribeAudio":
      guard let args = call.arguments as? [String: Any],
            let audioData = args["audio"] as? FlutterStandardTypedData,
            let llm = llmInference else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Model not loaded or missing audio", details: nil))
        return
      }
      // Convert PCM16 to float32
      let floatAudio = Self.pcm16ToFloat32(audioData.data)
      do {
        // Create a session and add audio
        let session = try llm.createSession()
        try session.addAudio(floatAudio)
        let output = try session.finish()
        result(output)
      } catch {
        result(FlutterError(code: "INFER_FAILED", message: "\(error)", details: nil))
      }
    case "runMultimodal":
      guard let llm = llmInference else {
        result(FlutterError(code: "NOT_READY", message: "Model not loaded", details: nil))
        return
      }
      let args = call.arguments as? [String: Any] ?? [:]
      let audioData = args["audio"] as? FlutterStandardTypedData
      let imageData = args["image"] as? FlutterStandardTypedData
      let text = args["text"] as? String
      do {
        let session = try llm.createSession()
        if let text = text {
          try session.addText(text)
        }
        if let imageData = imageData {
          try session.addImage(imageData.data)
        }
        if let audioData = audioData {
          let floatAudio = Self.pcm16ToFloat32(audioData.data)
          try session.addAudio(floatAudio)
        }
        let output = try session.finish()
        result(output)
      } catch {
        result(FlutterError(code: "INFER_FAILED", message: "\(error)", details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

// MARK: - FlutterStreamHandler for streaming inference
extension Gemma3nMultimodalPlugin: FlutterStreamHandler {
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    guard let args = arguments as? [String: Any], let type = args["type"] as? String else {
      return FlutterError(code: "INVALID_ARGUMENT", message: "Arguments must be a map with type", details: nil)
    }
    switch type {
    case "transcription":
      handleStreamTranscription(arguments: args, eventSink: events)
    case "multimodal":
      handleStreamMultimodal(arguments: args, eventSink: events)
    default:
      return FlutterError(code: "INVALID_ARGUMENT", message: "Unknown stream type", details: nil)
    }
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }

  // Streaming transcription handler
  private func handleStreamTranscription(arguments: [String: Any], eventSink: @escaping FlutterEventSink) {
    guard let audioBytes = arguments["audio"] as? FlutterStandardTypedData, let llm = llmInference else {
      eventSink(FlutterError(code: "NOT_READY", message: "Model not loaded or missing audio", details: nil))
      return
    }
    Task {
      do {
        let session = try llm.createSession()
        let floatAudio = Self.pcm16ToFloat32(audioBytes.data)
        try session.addAudio(floatAudio)
        // Use MediaPipe's async streaming API for partial results
        let stream = try session.generateResponseAsync()
        for try await partial in stream {
          eventSink(partial)
        }
        eventSink(FlutterEndOfEventStream)
      } catch {
        eventSink(FlutterError(code: "STREAM_FAILED", message: "\(error)", details: nil))
        eventSink(FlutterEndOfEventStream)
      }
    }
  }

  // Streaming multimodal handler
  private func handleStreamMultimodal(arguments: [String: Any], eventSink: @escaping FlutterEventSink) {
    let audioBytes = arguments["audio"] as? FlutterStandardTypedData
    let imageBytes = arguments["image"] as? FlutterStandardTypedData
    let text = arguments["text"] as? String
    guard let llm = llmInference, (audioBytes != nil || imageBytes != nil || text != nil) else {
      eventSink(FlutterError(code: "NOT_READY", message: "Model not loaded or no input provided", details: nil))
      return
    }
    Task {
      do {
        let session = try llm.createSession()
        if let text = text {
          try session.addText(text)
        }
        if let imageBytes = imageBytes {
          try session.addImage(imageBytes.data)
        }
        if let audioBytes = audioBytes {
          let floatAudio = Self.pcm16ToFloat32(audioBytes.data)
          try session.addAudio(floatAudio)
        }
        // Use MediaPipe's async streaming API for partial results
        let stream = try session.generateResponseAsync()
        for try await partial in stream {
          eventSink(partial)
        }
        eventSink(FlutterEndOfEventStream)
      } catch {
        eventSink(FlutterError(code: "STREAM_FAILED", message: "\(error)", details: nil))
        eventSink(FlutterEndOfEventStream)
      }
    }
  }
}

// MARK: - PCM16 to Float32 conversion helper
extension Gemma3nMultimodalPlugin {
  /// Converts PCM16 (little-endian) Data to [Float]
  static func pcm16ToFloat32(_ data: Data) -> [Float] {
    let count = data.count / 2
    var floatArray = [Float](repeating: 0, count: count)
    data.withUnsafeBytes { (rawBuffer: UnsafeRawBufferPointer) in
      let ptr = rawBuffer.bindMemory(to: Int16.self)
      for i in 0..<count {
        floatArray[i] = Float(ptr[i]) / 32768.0
      }
    }
    return floatArray
  }
}

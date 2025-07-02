import Flutter
import UIKit
import MediaPipeTasksGenAI

public class Gemma3nMultimodalPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  private var llmInference: LlmInference?
  private var eventSink: FlutterEventSink?
  private var bufferedAudio: [[Float]] = []
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "gemma3n_multimodal", binaryMessenger: registrar.messenger())
    let stream = FlutterEventChannel(name: "gemma3n_multimodal_stream", binaryMessenger: registrar.messenger())
    let instance = Gemma3nMultimodalPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    stream.setStreamHandler(instance)
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
      let useANE = args["useANE"] as? Bool ?? true
      let useGPU = args["useGPU"] as? Bool ?? false
      do {
        let options = LlmInferenceOptions()
        options.baseOptions.modelPath = path
        if useANE {
          options.baseOptions.delegate = .coreML
        } else if useGPU {
          options.baseOptions.delegate = .gpu
        } else {
          options.baseOptions.delegate = .cpu
        }
        llmInference = try LlmInference(options: options)
        result(nil)
      } catch {
        llmInference = nil
        result(FlutterError(code: "LOAD_FAILED", message: error.localizedDescription, details: nil))
      }
    case "unloadModel":
      llmInference = nil
      bufferedAudio.removeAll()
      result(nil)
    case "isModelLoaded":
      result(llmInference != nil)
    case "transcribeAudio":
      guard let args = call.arguments as? [String: Any],
            let audio = args["audio"] as? FlutterStandardTypedData,
            let llm = llmInference else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing audio or model not loaded", details: nil))
        return
      }
      let floats = convertPcm16ToFloat32(audio.data)
      do {
        let session = try llm.createSession()
        try session.addAudioChunk(floats)
        let text = try session.finish()
        result(text)
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
        let opts = LlmInferenceSessionOptions()
        if args["image"] != nil { opts.graphOptions.enableVisionModality = true }
        let session = try llm.createSession(options: opts)
        if let text = args["text"] as? String { try session.addQueryChunk(text) }
        if let imgData = args["image"] as? FlutterStandardTypedData, let img = UIImage(data: imgData.data) {
          let mpImage = MPImage(uiImage: img)
          try session.addImage(mpImage)
        }
        if let audioData = args["audio"] as? FlutterStandardTypedData {
          let floats = convertPcm16ToFloat32(audioData.data)
          try session.addAudioChunk(floats)
        }
        for chunk in bufferedAudio { try session.addAudioChunk(chunk) }
        bufferedAudio.removeAll()
        let text = try session.finish()
        result(text)
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
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - FlutterStreamHandler
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    guard let args = arguments as? [String: Any] else {
      return FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil)
    }
    eventSink = events
    let type = args["type"] as? String
    if type == "transcription" {
      handleStreamTranscription(args)
    } else if type == "multimodal" {
      handleStreamMultimodal(args)
    } else {
      return FlutterError(code: "INVALID_ARGUMENT", message: "Unknown stream type", details: nil)
    }
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func handleStreamTranscription(_ args: [String: Any]) {
    guard let audioData = args["audio"] as? FlutterStandardTypedData,
          let llm = llmInference else {
      eventSink?(FlutterError(code: "NOT_READY", message: "Model not loaded or missing audio", details: nil))
      return
    }
    let floats = convertPcm16ToFloat32(audioData.data)
    do {
      let session = try llm.createSession()
      try session.addAudioChunk(floats)
      try session.generateResponseAsync { [weak self] partial, done in
        if let text = partial { self?.eventSink?(text) }
        if done { self?.eventSink?(FlutterEndOfEventStream) }
      }
    } catch {
      eventSink?(FlutterError(code: "STREAM_FAILED", message: error.localizedDescription, details: nil))
    }
  }

  private func handleStreamMultimodal(_ args: [String: Any]) {
    guard let llm = llmInference else {
      eventSink?(FlutterError(code: "NOT_READY", message: "Model not loaded", details: nil))
      return
    }
    do {
      let opts = LlmInferenceSessionOptions()
      if args["image"] != nil { opts.graphOptions.enableVisionModality = true }
      let session = try llm.createSession(options: opts)
      if let text = args["text"] as? String { try session.addQueryChunk(text) }
      if let imgData = args["image"] as? FlutterStandardTypedData, let img = UIImage(data: imgData.data) {
        let mpImage = MPImage(uiImage: img)
        try session.addImage(mpImage)
      }
      if let audioData = args["audio"] as? FlutterStandardTypedData {
        let floats = convertPcm16ToFloat32(audioData.data)
        try session.addAudioChunk(floats)
      }
      try session.generateResponseAsync { [weak self] partial, done in
        if let text = partial { self?.eventSink?(text) }
        if done { self?.eventSink?(FlutterEndOfEventStream) }
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
}

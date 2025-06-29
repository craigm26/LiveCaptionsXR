import Flutter
import UIKit
import MediaPipeTasksGenAI

public class Gemma3nMultimodalFlutterPlugin: NSObject, FlutterPlugin {
    private var llmInferenceInstances = [String: LlmInference]()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "gemma3n_multimodal_flutter", binaryMessenger: registrar.messenger())
        let instance = Gemma3nMultimodalFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "create":
            guard let args = call.arguments as? [String: Any],
                  let assetPath = args["assetPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Asset path is required", details: nil))
                return
            }
            let modelPath = Bundle.main.path(forResource: assetPath, ofType: nil)!
            let options = LlmInferenceOptions(modelPath: modelPath)
            do {
                let llmInference = try LlmInference(options: options)
                llmInferenceInstances[assetPath] = llmInference
                result(nil)
            } catch {
                result(FlutterError(code: "MODEL_CREATION_FAILED", message: error.localizedDescription, details: nil))
            }
        case "createSession":
            result(nil)
        case "addQueryChunk":
            result(nil)
        case "getResponse":
            guard let args = call.arguments as? [String: Any],
                  let assetPath = args["assetPath"] as? String,
                  let queryMessages = args["query"] as? [[String: Any?]] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Asset path and query are required", details: nil))
                return
            }
            guard let llmInference = llmInferenceInstances[assetPath] else {
                result(FlutterError(code: "MODEL_NOT_FOUND", message: "Model not found for asset path: \(assetPath)", details: nil))
                return
            }

            let textParts = queryMessages.compactMap { $0["text"] as? String }
            let imageParts = queryMessages.compactMap { $0["imageBytes"] as? FlutterStandardTypedData }.compactMap { UIImage(data: $0.data) }

            do {
                let response = try llmInference.generateResponse(inputText: textParts.joined(separator: " "), images: imageParts)
                result(response)
            } catch {
                result(FlutterError(code: "INFERENCE_FAILED", message: error.localizedDescription, details: nil))
            }
        case "close":
            guard let args = call.arguments as? [String: Any],
                  let assetPath = args["assetPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Asset path is required", details: nil))
                return
            }
            llmInferenceInstances.removeValue(forKey: assetPath)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

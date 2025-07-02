import Flutter
import UIKit

public class Gemma3nMultimodalPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "gemma3n_multimodal", binaryMessenger: registrar.messenger())
    let instance = Gemma3nMultimodalPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "loadModel":
      // Placeholder for model loading
      result("Model loading not implemented yet")
    case "unloadModel":
      result("Model unloaded")
    case "isModelLoaded":
      result(false)
    case "transcribeAudio":
      result("Audio transcription not implemented yet")
    case "runMultimodal":
      result("Multimodal inference not implemented yet")
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

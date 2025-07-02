import Flutter
import UIKit
import ARKit
import SceneKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var visualSpeakerIdentifier: VisualSpeakerIdentifier?
    private var arAnchorManager: ARAnchorManager?
    private let arSession = ARSession()
    private let sceneView = ARSCNView()
    private var hybridLocalizationEngine: HybridLocalizationEngine? = nil

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        StereoAudioCapturePlugin.register(with: self)
        SpeechLocalizerPlugin.register(with: self)
        ARAnchorManager.register(with: self)
        ARAnchorManager.arSession = arSession

        guard let controller = window?.rootViewController as? FlutterViewController else {
            fatalError("rootViewController is not type FlutterViewController")
        }

        let visualChannel = FlutterMethodChannel(name: "com.craig.livecaptions/visual",
                                                 binaryMessenger: controller.binaryMessenger)
        
        if #available(iOS 14.0, *) {
            self.visualSpeakerIdentifier = VisualSpeakerIdentifier(channel: visualChannel)
            self.arAnchorManager = ARAnchorManager(session: arSession, sceneView: sceneView)
        }

        visualChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let self = self else { return }
            
            if #available(iOS 14.0, *) {
                switch call.method {
                case "startDetection":
                    self.visualSpeakerIdentifier?.startDetection()
                    result(nil)
                case "stopDetection":
                    self.visualSpeakerIdentifier?.stopDetection()
                    result(nil)
                case "captureFrame":
                    let frameData = self.visualSpeakerIdentifier?.captureFrame()
                    result(frameData)
                case "createAnchorFromAngle":
                    if let args = call.arguments as? [String: Any],
                       let angle = args["angle"] as? Double,
                       let distance = args["distance"] as? Double,
                       let text = args["text"] as? String {
                        self.arAnchorManager?.createAnchor(at: Float(angle), distance: Float(distance), text: text)
                    }
                    result(nil)
                case "createAnchorFromTransform":
                    if let args = call.arguments as? [String: Any],
                       let transformArray = args["transform"] as? [Float],
                       let text = args["text"] as? String {
                        let transform = simd_float4x4(rows: [
                            SIMD4<Float>(transformArray[0], transformArray[1], transformArray[2], transformArray[3]),
                            SIMD4<Float>(transformArray[4], transformArray[5], transformArray[6], transformArray[7]),
                            SIMD4<Float>(transformArray[8], transformArray[9], transformArray[10], transformArray[11]),
                            SIMD4<Float>(transformArray[12], transformArray[13], transformArray[14], transformArray[15])
                        ])
                        self.arAnchorManager?.createAnchor(at: transform, text: text)
                    }
                    result(nil)
                // Example of how audio service would notify vision service
                case "setSpeechDetected":
                    if let isDetected = call.arguments as? Bool {
                        self.visualSpeakerIdentifier?.setSpeechDetected(isDetected)
                    }
                    result(nil)
                default:
                    result(FlutterMethodNotImplemented)
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        let hybridChannel = FlutterMethodChannel(name: "live_captions_xr/hybrid_localization_methods", binaryMessenger: controller.binaryMessenger)
        self.hybridLocalizationEngine = HybridLocalizationEngine()
        hybridChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self, let engine = self.hybridLocalizationEngine else {
                result(FlutterError(code: "NO_ENGINE", message: "HybridLocalizationEngine not available", details: nil))
                return
            }
            switch call.method {
            case "predict":
                engine.predict()
                result(nil)
            case "updateWithAudioMeasurement":
                if let args = call.arguments as? [String: Any],
                   let angle = args["angle"] as? Double,
                   let confidence = args["confidence"] as? Double,
                   let tfArray = args["deviceTransform"] as? [Double], tfArray.count == 16 {
                    let matrix = simd_float4x4(rows: [
                        SIMD4<Float>(Float(tfArray[0]), Float(tfArray[1]), Float(tfArray[2]), Float(tfArray[3])),
                        SIMD4<Float>(Float(tfArray[4]), Float(tfArray[5]), Float(tfArray[6]), Float(tfArray[7])),
                        SIMD4<Float>(Float(tfArray[8]), Float(tfArray[9]), Float(tfArray[10]), Float(tfArray[11])),
                        SIMD4<Float>(Float(tfArray[12]), Float(tfArray[13]), Float(tfArray[14]), Float(tfArray[15]))
                    ])
                    engine.updateWithAudioMeasurement(angle: Float(angle), confidence: Float(confidence), deviceTransform: matrix)
                    result(nil)
                } else {
                    result(FlutterError(code: "BAD_ARGS", message: "Invalid arguments for updateWithAudioMeasurement", details: nil))
                }
            case "updateWithVisualMeasurement":
                if let args = call.arguments as? [String: Any],
                   let tfArray = args["transform"] as? [Double], tfArray.count == 16,
                   let confidence = args["confidence"] as? Double {
                    let matrix = simd_float4x4(rows: [
                        SIMD4<Float>(Float(tfArray[0]), Float(tfArray[1]), Float(tfArray[2]), Float(tfArray[3])),
                        SIMD4<Float>(Float(tfArray[4]), Float(tfArray[5]), Float(tfArray[6]), Float(tfArray[7])),
                        SIMD4<Float>(Float(tfArray[8]), Float(tfArray[9]), Float(tfArray[10]), Float(tfArray[11])),
                        SIMD4<Float>(Float(tfArray[12]), Float(tfArray[13]), Float(tfArray[14]), Float(tfArray[15]))
                    ])
                    engine.updateWithVisualMeasurement(transform: matrix, confidence: Float(confidence))
                    result(nil)
                } else {
                    result(FlutterError(code: "BAD_ARGS", message: "Invalid arguments for updateWithVisualMeasurement", details: nil))
                }
            case "getFusedTransform":
                let tf = engine.fusedTransform
                let arr: [Double] = [
                    Double(tf.columns.0.x), Double(tf.columns.0.y), Double(tf.columns.0.z), Double(tf.columns.0.w),
                    Double(tf.columns.1.x), Double(tf.columns.1.y), Double(tf.columns.1.z), Double(tf.columns.1.w),
                    Double(tf.columns.2.x), Double(tf.columns.2.y), Double(tf.columns.2.z), Double(tf.columns.2.w),
                    Double(tf.columns.3.x), Double(tf.columns.3.y), Double(tf.columns.3.z), Double(tf.columns.3.w)
                ]
                result(arr)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

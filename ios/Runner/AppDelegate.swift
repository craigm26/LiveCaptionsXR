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

        // Register the stereo audio capture plugin
        StereoAudioCapturePlugin.register(with: self)

        // Register the speech localizer plugin
        SpeechLocalizerPlugin.register(with: self)

        // Register the AR anchor manager plugin for ARKit integration
        ARAnchorManager.register(with: self)
        // TODO: Set the ARKit session from your ARViewController:
        // ARAnchorManager.arSession = yourARSession

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
                   let deviceTransform = args["deviceTransform"] as? [Double],
                   deviceTransform.count == 16 {
                    let m = deviceTransform.map { Float($0) }
                    let tf = simd_float4x4(rows: [
                        SIMD4<Float>(m[0], m[1], m[2], m[3]),
                        SIMD4<Float>(m[4], m[5], m[6], m[7]),
                        SIMD4<Float>(m[8], m[9], m[10], m[11]),
                        SIMD4<Float>(m[12], m[13], m[14], m[15])
                    ])
                    engine.updateWithAudioMeasurement(angle: Float(angle), confidence: Float(confidence), deviceTransform: tf)
                    result(nil)
                } else {
                    result(FlutterError(code: "BAD_ARGS", message: "Invalid arguments for updateWithAudioMeasurement", details: nil))
                }
            case "updateWithVisualMeasurement":
                if let args = call.arguments as? [String: Any],
                   let transform = args["transform"] as? [Double],
                   let confidence = args["confidence"] as? Double,
                   transform.count == 16 {
                    let m = transform.map { Float($0) }
                    let tf = simd_float4x4(rows: [
                        SIMD4<Float>(m[0], m[1], m[2], m[3]),
                        SIMD4<Float>(m[4], m[5], m[6], m[7]),
                        SIMD4<Float>(m[8], m[9], m[10], m[11]),
                        SIMD4<Float>(m[12], m[13], m[14], m[15])
                    ])
                    engine.updateWithVisualMeasurement(transform: tf, confidence: Float(confidence))
                    result(nil)
                } else {
                    result(FlutterError(code: "BAD_ARGS", message: "Invalid arguments for updateWithVisualMeasurement", details: nil))
                }
            case "getFusedTransform":
                let tf = engine.fusedTransform
                // simd_float4x4 to [Double] (row-major)
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

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

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

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

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

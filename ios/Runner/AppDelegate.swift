import Flutter
import UIKit
import ARKit
import simd
import SceneKit
import Foundation

// CaptionNode is defined in CaptionNode.swift

// ARAnchorManager class for AR anchor management
@objc class ARAnchorManager: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "live_captions_xr/ar_anchor_methods", binaryMessenger: registrar.messenger())
        let instance = ARAnchorManager()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    // Reference to the ARSession (should be set from your ARViewController)
    static weak var arSession: ARSession?
    static var anchorMap: [String: ARAnchor] = [:]

    private let session: ARSession
    private let sceneView: ARSCNView

    // Default initializer for plugin registration
    override init() {
        self.session = ARSession()
        self.sceneView = ARSCNView()
        super.init()
    }

    init(session: ARSession, sceneView: ARSCNView) {
        self.session = session
        self.sceneView = sceneView
        super.init()
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "createAnchorAtAngle":
            guard let args = call.arguments as? [String: Any],
                  let angle = args["angle"] as? Double,
                  let distance = args["distance"] as? Double,
                  let session = ARAnchorManager.arSession,
                  let camera = session.currentFrame?.camera else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing angle, distance, or ARSession", details: nil))
                return
            }
            let cameraTransform = camera.transform
            let yRotation = simd_float4x4(SCNMatrix4MakeRotation(Float(angle), 0, 1, 0))
            let translation = simd_float4x4(SCNMatrix4MakeTranslation(0, 0, -Float(distance)))
            let anchorTransform = simd_mul(cameraTransform, simd_mul(yRotation, translation))
            let anchor = ARAnchor(transform: anchorTransform)
            session.add(anchor: anchor)
            let id = anchor.identifier.uuidString
            ARAnchorManager.anchorMap[id] = anchor
            result(id)
        case "createAnchorAtWorldTransform":
            guard let args = call.arguments as? [String: Any],
                  let transformArray = args["transform"] as? [Double],
                  transformArray.count == 16,
                  let session = ARAnchorManager.arSession else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing or invalid transform/ARSession", details: nil))
                return
            }
            var matrix = matrix_identity_float4x4
            for row in 0..<4 {
                for col in 0..<4 {
                    matrix[row][col] = Float(transformArray[row * 4 + col])
                }
            }
            let anchor = ARAnchor(transform: matrix)
            session.add(anchor: anchor)
            let id = anchor.identifier.uuidString
            ARAnchorManager.anchorMap[id] = anchor
            result(id)
        case "removeAnchor":
            guard let args = call.arguments as? [String: Any],
                  let identifier = args["identifier"] as? String,
                  let session = ARAnchorManager.arSession,
                  let anchor = ARAnchorManager.anchorMap[identifier] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing identifier or anchor", details: nil))
                return
            }
            session.remove(anchor: anchor)
            ARAnchorManager.anchorMap.removeValue(forKey: identifier)
            result(nil)
        case "getDeviceOrientation":
            guard let session = ARAnchorManager.arSession,
                  let camera = session.currentFrame?.camera else {
                result(FlutterError(code: "NO_SESSION", message: "ARSession or camera not available", details: nil))
                return
            }
            let m = camera.transform
            let flat: [Float] = [
                m[0][0], m[0][1], m[0][2], m[0][3],
                m[1][0], m[1][1], m[1][2], m[1][3],
                m[2][0], m[2][1], m[2][2], m[2][3],
                m[3][0], m[3][1], m[3][2], m[3][3]
            ]
            result(flat)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func createAnchor(at angle: Float, distance: Float = 2.0, text: String) {
        guard let frame = session.currentFrame else { return }
        let cameraTransform = frame.camera.transform
        
        // Create a rotation matrix from the angle
        let rotation = simd_float4x4(SCNMatrix4MakeRotation(angle, 0, 1, 0))
        
        // Create a translation matrix from the distance
        let translation = simd_float4x4(SCNMatrix4MakeTranslation(0, 0, -distance))
        
        // Combine the transforms
        let transform = simd_mul(simd_mul(cameraTransform, translation), rotation)
        
        let anchor = ARAnchor(transform: transform)
        session.add(anchor: anchor)

        if #available(iOS 14.0, *) {
            let captionNode = CaptionNode(text: text)
            sceneView.scene.rootNode.addChildNode(captionNode)
            captionNode.position = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        }
    }

    func createAnchor(at worldTransform: simd_float4x4, text: String) {
        let anchor = ARAnchor(transform: worldTransform)
        session.add(anchor: anchor)

        if #available(iOS 14.0, *) {
            let captionNode = CaptionNode(text: text)
            sceneView.scene.rootNode.addChildNode(captionNode)
            captionNode.position = SCNVector3(worldTransform.columns.3.x, worldTransform.columns.3.y, worldTransform.columns.3.z)
        }
    }

    func removeAnchor(_ anchor: ARAnchor) {
        session.remove(anchor: anchor)
        // TODO: Remove the corresponding CaptionNode from the scene
    }
}

// Simple HybridLocalizationEngine implementation
class HybridLocalizationEngine {
    // Simple state tracking - position only for now
    private var position = simd_float3(0, 0, 0)
    private var lastUpdate: Date = Date()
    
    // Prediction step - simplified
    func predict() {
        // For now, just update timestamp
        lastUpdate = Date()
    }

    // Update with audio (angle, confidence, deviceTransform)
    func updateWithAudioMeasurement(angle: Float, confidence: Float, deviceTransform: simd_float4x4) {
        // Convert angle to a 3D point in world space using deviceTransform
        let distance: Float = 2.0 // Assume default distance
        
        // Create rotation matrix for Y-axis rotation
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)
        let rotationMatrix = simd_float4x4(
            simd_float4(cosAngle, 0, sinAngle, 0),
            simd_float4(0, 1, 0, 0),
            simd_float4(-sinAngle, 0, cosAngle, 0),
            simd_float4(0, 0, 0, 1)
        )
        
        // Create translation matrix
        let translationMatrix = simd_float4x4(
            simd_float4(1, 0, 0, 0),
            simd_float4(0, 1, 0, 0),
            simd_float4(0, 0, 1, 0),
            simd_float4(0, 0, -distance, 1)
        )
        
        let worldTransform = deviceTransform * rotationMatrix * translationMatrix
        
        // Update position with simple weighted average
        let newPosition = simd_float3(worldTransform.columns.3.x, worldTransform.columns.3.y, worldTransform.columns.3.z)
        let weight = confidence * 0.3 // Audio has lower weight
        position = position * (1.0 - weight) + newPosition * weight
    }

    // Update with vision (3D transform, confidence)
    func updateWithVisualMeasurement(transform: simd_float4x4, confidence: Float) {
        let newPosition = simd_float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        let weight = confidence * 0.7 // Vision has higher weight
        position = position * (1.0 - weight) + newPosition * weight
    }

    // Output: fused world transform for AR anchor
    var fusedTransform: simd_float4x4 {
        var transform = matrix_identity_float4x4
        transform.columns.3 = simd_float4(position.x, position.y, position.z, 1.0)
        return transform
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var hybridLocalizationEngine: HybridLocalizationEngine?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        // Register custom plugins - use registrar for proper plugin registration
        if let registrar = self.registrar(forPlugin: "ARAnchorManager") {
            ARAnchorManager.register(with: registrar)
        }
        
        if let registrar = self.registrar(forPlugin: "VisualObjectPlugin") {
            VisualObjectPlugin.register(with: registrar)
        }
        
        // Set up AR navigation method channel
        if let controller = window?.rootViewController as? FlutterViewController {
            let arNavigationChannel = FlutterMethodChannel(
                name: "live_captions_xr/ar_navigation",
                binaryMessenger: controller.binaryMessenger
            )
            
            arNavigationChannel.setMethodCallHandler { [weak self] (call, result) in
                switch call.method {
                case "showARView":
                    self?.showARView(from: controller, result: result)
                default:
                    result(FlutterMethodNotImplemented)
                }
            }
            
            // Set up hybrid localization method channel
            let hybridChannel = FlutterMethodChannel(
                name: "live_captions_xr/hybrid_localization_methods",
                binaryMessenger: controller.binaryMessenger
            )
            
            self.hybridLocalizationEngine = HybridLocalizationEngine()
            hybridChannel.setMethodCallHandler { [weak self] (call, result) in
                guard let self = self, let engine = self.hybridLocalizationEngine else {
                    result(FlutterError(
                        code: "NO_ENGINE",
                        message: "HybridLocalizationEngine not available",
                        details: nil
                    ))
                    return
                }
                
                switch call.method {
                case "predict":
                    engine.predict()
                    result(nil)
                case "updateWithAudioMeasurement":
                    self.handleAudioMeasurementUpdate(call: call, result: result, engine: engine)
                case "updateWithVisualMeasurement":
                    self.handleVisualMeasurementUpdate(call: call, result: result, engine: engine)
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
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func handleAudioMeasurementUpdate(call: FlutterMethodCall, result: @escaping FlutterResult, engine: HybridLocalizationEngine) {
        guard let args = call.arguments as? [String: Any],
              let angle = args["angle"] as? Double,
              let confidence = args["confidence"] as? Double,
              let tfArray = args["deviceTransform"] as? [Double],
              tfArray.count == 16 else {
            result(FlutterError(
                code: "BAD_ARGS",
                message: "Invalid arguments for updateWithAudioMeasurement",
                details: nil
            ))
            return
        }
        
        let matrix = simd_float4x4(rows: [
            SIMD4<Float>(Float(tfArray[0]), Float(tfArray[1]), Float(tfArray[2]), Float(tfArray[3])),
            SIMD4<Float>(Float(tfArray[4]), Float(tfArray[5]), Float(tfArray[6]), Float(tfArray[7])),
            SIMD4<Float>(Float(tfArray[8]), Float(tfArray[9]), Float(tfArray[10]), Float(tfArray[11])),
            SIMD4<Float>(Float(tfArray[12]), Float(tfArray[13]), Float(tfArray[14]), Float(tfArray[15]))
        ])
        
        engine.updateWithAudioMeasurement(angle: Float(angle), confidence: Float(confidence), deviceTransform: matrix)
        result(nil)
    }
    
    private func handleVisualMeasurementUpdate(call: FlutterMethodCall, result: @escaping FlutterResult, engine: HybridLocalizationEngine) {
        guard let args = call.arguments as? [String: Any],
              let tfArray = args["transform"] as? [Double],
              tfArray.count == 16,
              let confidence = args["confidence"] as? Double else {
            result(FlutterError(
                code: "BAD_ARGS",
                message: "Invalid arguments for updateWithVisualMeasurement",
                details: nil
            ))
            return
        }
        
        let matrix = simd_float4x4(rows: [
            SIMD4<Float>(Float(tfArray[0]), Float(tfArray[1]), Float(tfArray[2]), Float(tfArray[3])),
            SIMD4<Float>(Float(tfArray[4]), Float(tfArray[5]), Float(tfArray[6]), Float(tfArray[7])),
            SIMD4<Float>(Float(tfArray[8]), Float(tfArray[9]), Float(tfArray[10]), Float(tfArray[11])),
            SIMD4<Float>(Float(tfArray[12]), Float(tfArray[13]), Float(tfArray[14]), Float(tfArray[15]))
        ])
        
        engine.updateWithVisualMeasurement(transform: matrix, confidence: Float(confidence))
        result(nil)
    }
    
    private func showARView(from controller: FlutterViewController, result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            // Check if ARKit is available on device
            guard ARWorldTrackingConfiguration.isSupported else {
                result(FlutterError(
                    code: "AR_NOT_SUPPORTED",
                    message: "ARKit is not supported on this device",
                    details: nil
                ))
                return
            }
            
            // Launch actual ARViewController
            let arViewController = ARViewController()
            arViewController.modalPresentationStyle = .fullScreen
            controller.present(arViewController, animated: true) {
                result(nil)
            }
        }
    }
}

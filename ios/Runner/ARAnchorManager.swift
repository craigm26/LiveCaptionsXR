import Foundation
import Flutter
import ARKit
import SceneKit

@available(iOS 14.0, *)
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
                  let distance = args["distance"] as? Double else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing angle or distance", details: nil))
                return
            }
            
            guard let session = ARAnchorManager.arSession else {
                result(FlutterError(code: "NO_SESSION", message: "ARSession not available", details: nil))
                return
            }
            
            guard let camera = session.currentFrame?.camera,
                  case .normal = camera.trackingState else {
                result(FlutterError(code: "SESSION_NOT_READY", message: "ARSession not ready - no camera frame or tracking not normal", details: nil))
                return
            }
            
            // The camera.transform is a 4x4 matrix representing the device's orientation and position in world space.
            // This matrix is IMU-fused and updated in real time by ARKit.
            // We use it as the base for all anchor placement to ensure world-accurate positioning.
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
            NSLog("🔗 ARAnchorManager.createAnchorAtWorldTransform called")
            guard let args = call.arguments as? [String: Any],
                  let transformArray = args["transform"] as? [Double],
                  transformArray.count == 16 else {
                NSLog("❌ Invalid arguments for createAnchorAtWorldTransform")
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing or invalid transform array", details: nil))
                return
            }
            
            NSLog("📊 Transform array received with %ld elements", transformArray.count)
            
            guard let session = ARAnchorManager.arSession else {
                NSLog("❌ CRITICAL: ARAnchorManager.arSession is nil")
                result(FlutterError(code: "NO_SESSION", message: "ARSession not available", details: nil))
                return
            }
            
            NSLog("✅ ARAnchorManager.arSession exists")
            
            // Check if ARSession is tracking and has at least one frame
            guard session.currentFrame != nil else {
                NSLog("❌ ARSession.currentFrame is nil")
                result(FlutterError(code: "SESSION_NOT_READY", message: "ARSession not ready - no camera frame", details: nil))
                return
            }
            
            NSLog("✅ ARSession.currentFrame exists")
            
            guard case .normal = session.currentFrame?.camera.trackingState else {
                NSLog("❌ ARSession camera tracking state is not normal")
                result(FlutterError(code: "SESSION_NOT_READY", message: "ARSession not ready - tracking not normal", details: nil))
                return
            }
            
            NSLog("✅ ARSession camera tracking state is normal")
            
            var matrix = matrix_identity_float4x4
            for row in 0..<4 {
                for col in 0..<4 {
                    matrix[row][col] = Float(transformArray[row * 4 + col])
                }
            }
            
            NSLog("🎯 Creating ARAnchor with transform...")
            let anchor = ARAnchor(transform: matrix)
            session.add(anchor: anchor)
            let id = anchor.identifier.uuidString
            ARAnchorManager.anchorMap[id] = anchor
            NSLog("✅ ARAnchor created successfully with ID: %@", id)
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
            NSLog("📱 ARAnchorManager.getDeviceOrientation called for session validation")
            
            // Check if session exists
            guard let session = ARAnchorManager.arSession else {
                NSLog("❌ Session validation failed: ARAnchorManager.arSession is nil")
                result(FlutterError(code: "NO_SESSION", message: "ARSession not available", details: nil))
                return
            }
            
            NSLog("✅ Session validation: ARAnchorManager.arSession exists")
            
            // Check if session is running
            guard session.currentFrame != nil else {
                NSLog("❌ Session validation failed: no current frame available")
                result(FlutterError(code: "SESSION_NOT_READY", message: "ARSession not ready - no camera frame", details: nil))
                return
            }
            
            NSLog("✅ Session validation: camera frame exists")
            
            // Check camera tracking state
            guard let camera = session.currentFrame?.camera else {
                NSLog("❌ Session validation failed: no camera in current frame")
                result(FlutterError(code: "SESSION_NOT_READY", message: "ARSession not ready - no camera", details: nil))
                return
            }
            
            // Allow limited tracking state as well since it may be temporary
            guard case .normal = camera.trackingState else {
                NSLog("❌ Session validation failed: camera tracking state is not normal")
                result(FlutterError(code: "SESSION_NOT_READY", message: "ARSession not ready - tracking not normal", details: nil))
                return
            }
            
            NSLog("✅ Session validation: camera tracking state is normal")
            
            let m = camera.transform
            let flat: [Float] = [
                m[0][0], m[0][1], m[0][2], m[0][3],
                m[1][0], m[1][1], m[1][2], m[1][3],
                m[2][0], m[2][1], m[2][2], m[2][3],
                m[3][0], m[3][1], m[3][2], m[3][3]
            ]
            NSLog("✅ Session validation successful, returning device orientation")
            result(flat)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

}

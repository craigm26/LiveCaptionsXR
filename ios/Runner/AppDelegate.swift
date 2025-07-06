import Flutter
import UIKit
import ARKit
import simd
import SceneKit
import Foundation

// CaptionNode is defined in CaptionNode.swift

// ARAnchorManager is defined in ARAnchorManager.swift

// Simple HybridLocalizationEngine implementation
class HybridLocalizationEngine {
    // Simple state tracking - position only for now
    // Default to 2 meters in front of device at eye level
    private var position = simd_float3(0, 0, -2.0)
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

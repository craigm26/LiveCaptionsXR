import Flutter
import UIKit
import ARKit
import simd
import SceneKit
import Foundation

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
        
        if let registrar = self.registrar(forPlugin: "StereoAudioCapturePlugin") {
            StereoAudioCapturePlugin.register(with: registrar)
        }
        
        if let registrar = self.registrar(forPlugin: "SpeechLocalizerPlugin") {
            SpeechLocalizerPlugin.register(with: registrar)
        }
        
        // Set up AR navigation method channel
        if let controller = window?.rootViewController as? FlutterViewController {
            print("📡 Setting up AR navigation method channel...")
            let arNavigationChannel = FlutterMethodChannel(
                name: "live_captions_xr/ar_navigation",
                binaryMessenger: controller.binaryMessenger
            )
            
            arNavigationChannel.setMethodCallHandler { [weak self] (call, result) in
                print("📨 AR navigation method call received: \(call.method)")
                switch call.method {
                case "showARView":
                    print("🎯 Handling showARView method call")
                    self?.showARView(from: controller, result: result)
                default:
                    print("❓ Unknown AR navigation method: \(call.method)")
                    result(FlutterMethodNotImplemented)
                }
            }
            print("✅ AR navigation method channel setup complete")
            
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
        print("📺 AppDelegate.showARView() called")
        DispatchQueue.main.async {
            // Check if ARKit is available on device
            guard ARWorldTrackingConfiguration.isSupported else {
                print("❌ ARWorldTrackingConfiguration not supported")
                result(FlutterError(
                    code: "AR_NOT_SUPPORTED",
                    message: "ARKit is not supported on this device",
                    details: nil
                ))
                return
            }
            
            print("✅ ARWorldTrackingConfiguration is supported")
            print("🏗️ Creating ARViewController...")
            
            // Launch actual ARViewController
            let arViewController = ARViewController()
            arViewController.modalPresentationStyle = .fullScreen
            
            var hasCompleted = false
            
            print("🔗 Setting up ARViewController session ready callback...")
            
            // Set completion callback to notify when AR session is truly ready
            arViewController.onSessionReady = { [weak arViewController] in
                print("📞 ARViewController.onSessionReady callback triggered")
                guard !hasCompleted else { 
                    print("⚠️ Callback already completed, ignoring")
                    return 
                }
                hasCompleted = true
                
                // Ensure the session is actually set and ready
                if ARAnchorManager.arSession != nil {
                    print("✅ Session ready callback: ARAnchorManager.arSession is available")
                    result(nil)
                } else {
                    print("❌ Session ready callback: ARAnchorManager.arSession is nil!")
                    result(FlutterError(
                        code: "SESSION_INIT_FAILED",
                        message: "ARSession failed to initialize properly",
                        details: nil
                    ))
                }
            }
            
            print("⏰ Setting up 5-second timeout for AR session initialization...")
            
            // Add timeout to prevent hanging if session never becomes ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                guard !hasCompleted else { 
                    print("✅ Timeout avoided - session was ready in time")
                    return 
                }
                hasCompleted = true
                print("⏰ ARSession initialization timed out after 5 seconds")
                result(FlutterError(
                    code: "SESSION_TIMEOUT",
                    message: "ARSession initialization timed out",
                    details: nil
                ))
            }
            
            print("🚀 Presenting ARViewController...")
            controller.present(arViewController, animated: true, completion: {
                print("✅ ARViewController presentation completed")
            })
        }
    }
}

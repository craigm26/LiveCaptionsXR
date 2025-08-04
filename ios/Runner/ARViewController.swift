import UIKit
import ARKit
import Flutter

@available(iOS 14.0, *)
class ARViewController: UIViewController, ARSCNViewDelegate {
    var sceneView: ARSCNView!
    var captionChannel: FlutterMethodChannel?
    var onSessionReady: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSLog("🏗️ [NATIVE] ARViewController.viewDidLoad() called")
        
        // Check if ARKit is available before setting up ARSCNView
        guard ARWorldTrackingConfiguration.isSupported else {
            print("❌ ARWorldTrackingConfiguration not supported on this device")
            showARNotSupportedMessage()
            return
        }
        
        print("✅ ARWorldTrackingConfiguration is supported")
        
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.backgroundColor = .clear
        // Lighting features disabled for optimal performance with AI processing
        // sceneView.automaticallyUpdatesLighting = true
        // sceneView.autoenablesDefaultLighting = true
        view.addSubview(sceneView)
        sceneView.delegate = self
        sceneView.session = ARSession()
        
        print("🎮 ARSession created and assigned to sceneView")
        
        // Set the session in ARAnchorManager for plugin access
        ARAnchorManager.arSession = sceneView.session
        print("🔗 ARSession assigned to ARAnchorManager.arSession")
        
        let config = ARWorldTrackingConfiguration()
        print("📐 Starting ARSession with ARWorldTrackingConfiguration...")
        sceneView.session.run(config)
        print("▶️ ARSession.run() called")
        NSLog("▶️ [NATIVE] ARSession.run() called - session running: %@", sceneView.session.configuration != nil ? "YES" : "NO")
        
        // NOTE: Test caption removed, focusing on real caption placement via method channel
        
        // Notify that the session is ready after ensuring proper initialization
        // Use a longer delay to ensure the session is fully stable
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            print("🕐 First session readiness check (after 1.5s)...")
            self?.checkSessionReadiness(attempt: 1)
        }
    }
    
    // Add a test caption to verify caption display works
    private func addTestCaption() {
        print("📝 [NATIVE] Adding test caption to verify caption display...")
        NSLog("📝 [NATIVE] Adding test caption to verify caption display...")
        
        if #available(iOS 14.0, *) {
            // Create a test caption at the EXACT same position as sphere
            let testCaption = CaptionNode(text: "BIG TEST", fontSize: 1.0, bubbleWidth: 4.0)
            testCaption.position = SCNVector3(x: 0, y: 0, z: -1) // EXACT same position as sphere
            testCaption.name = "test_caption"
            
            // Add directly to scene
            sceneView.scene.rootNode.addChildNode(testCaption)
            print("✅ [NATIVE] Test caption added at position (0, 0, -1)")
            NSLog("✅ [NATIVE] Test caption added. Scene now has %d nodes", sceneView.scene.rootNode.childNodes.count)
            
            // Remove after 30 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) { [weak testCaption] in
                testCaption?.removeFromParentNode()
                print("📝 [NATIVE] Test caption removed")
            }
        } else {
            print("❌ [NATIVE] iOS 14.0+ required for test caption")
        }
    }
    
    // Method to check session readiness with retry logic
    private func checkSessionReadiness(attempt: Int, maxAttempts: Int = 5) {
        guard let session = ARAnchorManager.arSession else {
            print("❌ Session readiness check failed: ARAnchorManager.arSession is nil (attempt \(attempt))")
            if attempt < maxAttempts {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.checkSessionReadiness(attempt: attempt + 1, maxAttempts: maxAttempts)
                }
            } else {
                print("❌ Session readiness check failed after \(maxAttempts) attempts")
                onSessionReady?()
            }
            return
        }
        
        guard let camera = session.currentFrame?.camera else {
            print("⚠️ Session exists but no current frame yet (attempt \(attempt))")
            if attempt < maxAttempts {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.checkSessionReadiness(attempt: attempt + 1, maxAttempts: maxAttempts)
                }
            } else {
                print("⚠️ Session ready check timed out, but proceeding anyway")
                onSessionReady?()
            }
            return
        }
        
        // Check if camera tracking is at least limited (not necessarily normal)
        switch camera.trackingState {
        case .normal:
            print("✅ ARSession is ready with normal tracking")
            onSessionReady?()
        case .limited(_):
            print("✅ ARSession is ready with limited tracking (proceeding anyway)")
            onSessionReady?()
        case .notAvailable:
            print("⚠️ ARSession camera tracking not available (attempt \(attempt))")
            if attempt < maxAttempts {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.checkSessionReadiness(attempt: attempt + 1, maxAttempts: maxAttempts)
                }
            } else {
                print("⚠️ Camera tracking check timed out, but proceeding anyway")
                onSessionReady?()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NSLog("🎬 [NATIVE] ARViewController.viewDidAppear - sceneView frame: %@", NSCoder.string(for: sceneView.frame))
        NSLog("🎬 [NATIVE] sceneView.isHidden: %@, alpha: %f", sceneView.isHidden ? "YES" : "NO", sceneView.alpha)
        
        // Add close button
        setupCloseButton()
        
        // Set up MethodChannels for captions and AR frames
        if let appDelegate = UIApplication.shared.delegate as? FlutterAppDelegate,
           let controller = appDelegate.window?.rootViewController as? FlutterViewController {
            // Caption method channel
            captionChannel = FlutterMethodChannel(name: "live_captions_xr/caption_methods", binaryMessenger: controller.binaryMessenger)
            NSLog("📡 [NATIVE] Caption method channel created with name: live_captions_xr/caption_methods")
            captionChannel?.setMethodCallHandler { [weak self] (call, result) in
                NSLog("📨 [NATIVE] Method channel received call: %@", call.method)
                if call.method == "placeCaption" {
                    guard let args = call.arguments as? [String: Any] else {
                        NSLog("❌ [NATIVE] Failed to cast arguments to dictionary")
                        result(FlutterError(code: "BAD_ARGS", message: "Arguments not a dictionary", details: nil))
                        return
                    }
                    
                    NSLog("📦 [NATIVE] Arguments: %@", args)
                    
                    guard let transform = args["transform"] as? [Double],
                          let text = args["text"] as? String else {
                        NSLog("❌ [NATIVE] Missing required arguments - transform: %@, text: %@", args["transform"] != nil ? "YES" : "NO", args["text"] != nil ? "YES" : "NO")
                        result(FlutterError(code: "BAD_ARGS", message: "Missing transform or text", details: nil))
                        return
                    }
                    
                    guard transform.count == 16 else {
                        NSLog("❌ [NATIVE] Transform array has wrong size: %ld, expected 16", transform.count)
                        result(FlutterError(code: "BAD_ARGS", message: "Transform must have 16 elements", details: nil))
                        return
                    }
                    
                    NSLog("✅ [NATIVE] Valid arguments received - text: \"%@\", transform count: %ld", text, transform.count)
                    
                    var matrix = matrix_identity_float4x4
                    for row in 0..<4 {
                        for col in 0..<4 {
                            matrix[row][col] = Float(transform[row * 4 + col])
                        }
                    }
                    self?.placeCaption(at: matrix, text: text)
                    result(nil)
                } else {
                    NSLog("❌ [NATIVE] Unhandled method: %@", call.method)
                    result(FlutterMethodNotImplemented)
                }
            }
            
            // AR Frame capture method channel
            let arFrameChannel = FlutterMethodChannel(name: "live_captions_xr/ar_frames", binaryMessenger: controller.binaryMessenger)
            arFrameChannel.setMethodCallHandler { [weak self] (call, result) in
                if call.method == "captureFrame" {
                    self?.captureCurrentARFrame { frameData in
                        DispatchQueue.main.async {
                            result(frameData)
                        }
                    }
                } else {
                    result(FlutterMethodNotImplemented)
                }
            }
        }
    }

    private func setupCloseButton() {
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        closeButton.layer.cornerRadius = 8
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 60),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func closeButtonTapped() {
        print("🚪 ARViewController close button tapped")
        
        // First notify Dart that the AR view is closing so it can stop all services
        if let appDelegate = UIApplication.shared.delegate as? FlutterAppDelegate,
           let controller = appDelegate.window?.rootViewController as? FlutterViewController {
            let arNavigationChannel = FlutterMethodChannel(name: "live_captions_xr/ar_navigation", binaryMessenger: controller.binaryMessenger)
            
            // Use invokeMethod with completion handler to wait for Dart cleanup
            arNavigationChannel.invokeMethod("arViewWillClose", arguments: nil) { [weak self] result in
                DispatchQueue.main.async {
                    self?.performARCleanup()
                }
            }
        } else {
            // Fallback if channel is not available
            performARCleanup()
        }
    }
    
    private func performARCleanup() {
        print("🧹 Starting AR cleanup after service shutdown...")
        
        // Wait a brief moment to ensure all background threads have stopped
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            print("⏸️ Pausing ARSession...")
            self.sceneView.session.pause()
            print("✅ ARSession paused")
            
            // Clear the session reference in ARAnchorManager after ensuring services are stopped
            ARAnchorManager.arSession = nil
            ARAnchorManager.anchorMap.removeAll()
            print("🧹 ARAnchorManager session and anchors cleared")
            
            self.dismiss(animated: true, completion: nil)
            print("✅ ARViewController dismissed")
        }
    }

    private func showARNotSupportedMessage() {
        let alert = UIAlertController(
            title: "AR Not Supported", 
            message: "ARKit features are not available on this device. The app will continue with audio-only features.", 
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.dismiss(animated: true, completion: nil)
        })
        present(alert, animated: true, completion: nil)
    }

    // ARSCNViewDelegate: Called when a new anchor is added
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Check if this is a caption anchor
        if let captionContainer = captionNodes[anchor] {
            print("🎯 [NATIVE] Positioning caption node for anchor: \(anchor.identifier)")
            NSLog("🎯 [NATIVE] Positioning caption node for anchor: %@", anchor.identifier.uuidString)
            // Move the caption container to the anchor's node
            captionContainer.removeFromParentNode()
            node.addChildNode(captionContainer)
            print("✅ [NATIVE] Caption positioned at anchor location")
            NSLog("✅ [NATIVE] Caption positioned at anchor location - node has %d children", node.childNodes.count)
            
            // Clean up the reference after some time
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                self?.captionNodes.removeValue(forKey: anchor)
            }
        } else {
            // Regular anchor detection
            let label = "ARAnchor"
            let confidence = 0.9
            let boundingBox: [Double] = [0, 0, 100, 100] // TODO: Use real bounding box if available
            VisualObjectPlugin.sendVisualObjectDetected(anchor: anchor, label: label, confidence: confidence, boundingBox: boundingBox)
        }
    }

    // TODO: Implement didUpdate for dynamic objects, and use real detection logic

    func placeCaption(at transform: simd_float4x4, text: String) {
        print("🎯 [NATIVE] placeCaption called with text: \"\(text)\"")
        NSLog("🎯 [NATIVE] placeCaption called with text: \"%@\"", text)
        print("📐 [NATIVE] Transform: \(transform)")
        
        // FORCE caption to the same position as test sphere for testing
        let position = SCNVector3(x: 0, y: 0.2, z: -1) // Slightly above test sphere
        print("📍 [NATIVE] Caption FORCED to sphere position (slightly above): x=\(position.x), y=\(position.y), z=\(position.z)")
        
        // Check if we have a current camera position
        if let cameraTransform = sceneView.session.currentFrame?.camera.transform {
            let cameraPos = SCNVector3(x: cameraTransform.columns.3.x, y: cameraTransform.columns.3.y, z: cameraTransform.columns.3.z)
            print("📷 [NATIVE] Camera position: x=\(cameraPos.x), y=\(cameraPos.y), z=\(cameraPos.z)")
            
            let distance = sqrt(pow(position.x - cameraPos.x, 2) + pow(position.y - cameraPos.y, 2) + pow(position.z - cameraPos.z, 2))
            print("📏 [NATIVE] Distance from camera: \(distance) meters")
        }
        
        // Create a unique identifier for this caption anchor
        let anchorID = UUID()
        let anchor = ARAnchor(name: "caption_\(anchorID)", transform: transform)
        sceneView.session.add(anchor: anchor)
        print("✅ [NATIVE] AR anchor added to session with ID: \(anchorID)")
        
        if #available(iOS 14.0, *) {
            // Create caption node with HUGE settings for visibility
            let captionNode = CaptionNode(text: text, fontSize: 1.0, bubbleWidth: 4.0)
            // Use original simdTransform but force position near red sphere
            var forcedTransform = transform
            forcedTransform.columns.3.x = 0    // x = 0 (same as sphere)
            forcedTransform.columns.3.y = 0.2  // y = 0.2 (slightly above sphere)
            forcedTransform.columns.3.z = -1   // z = -1 (same as sphere)
            captionNode.simdTransform = forcedTransform
            captionNode.name = "direct_caption_\(anchorID)"
            
            // Add directly to scene root - no anchor needed for testing
            sceneView.scene.rootNode.addChildNode(captionNode)
            
            print("✅ [NATIVE] CaptionNode created DIRECTLY at transform position")
            NSLog("✅ [NATIVE] Caption added directly to scene. Scene has %d nodes", sceneView.scene.rootNode.childNodes.count)
            
            // Auto-remove caption after some time
            captionNode.fadeOutAndRemove(after: 10.0)
            print("⏲️ [NATIVE] Caption will fade out after 10 seconds")
        } else {
            print("❌ [NATIVE] iOS 14.0+ required for CaptionNode")
        }
    }
    
    // Store caption nodes associated with anchors
    private var captionNodes: [ARAnchor: SCNNode] = [:]
    
    // MARK: - ARKit Frame Capture
    private func captureCurrentARFrame(completion: @escaping (FlutterStandardTypedData?) -> Void) {
        guard let currentFrame = sceneView.session.currentFrame else {
            print("❌ No current ARFrame available")
            completion(nil)
            return
        }
        
        let pixelBuffer = currentFrame.capturedImage
        
        // Convert CVPixelBuffer to UIImage (reusing logic from VisualSpeakerIdentifier)
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            print("❌ Failed to create CGImage from CVPixelBuffer")
            completion(nil)
            return
        }
        let uiImage = UIImage(cgImage: cgImage)
        
        // Convert UIImage to JPEG data
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert UIImage to JPEG data")
            completion(nil)
            return
        }
        
        print("✅ ARKit frame captured: \(jpegData.count) bytes")
        let flutterData = FlutterStandardTypedData(bytes: jpegData)
        completion(flutterData)
    }
}
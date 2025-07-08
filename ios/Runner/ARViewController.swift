import UIKit
import ARKit
import Flutter

class ARViewController: UIViewController, ARSCNViewDelegate {
    var sceneView: ARSCNView!
    var captionChannel: FlutterMethodChannel?
    var onSessionReady: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("🏗️ ARViewController.viewDidLoad() called")
        
        // Check if ARKit is available before setting up ARSCNView
        guard ARWorldTrackingConfiguration.isSupported else {
            print("❌ ARWorldTrackingConfiguration not supported on this device")
            showARNotSupportedMessage()
            return
        }
        
        print("✅ ARWorldTrackingConfiguration is supported")
        
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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
        
        // Notify that the session is ready after a brief delay to ensure initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            print("🕐 First session readiness check (after 0.5s)...")
            // Verify that the session is actually ready for anchor operations
            guard let self = self,
                  let session = ARAnchorManager.arSession,
                  session.currentFrame != nil else {
                print("⚠️ Session not ready on first check, waiting another 0.5s...")
                // If not ready, wait a bit more and try again
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    print("🕑 Second session readiness check (after 1.0s total)...")
                    if let session = ARAnchorManager.arSession {
                        if session.currentFrame != nil {
                            print("✅ ARSession is ready with current frame")
                        } else {
                            print("⚠️ ARSession exists but no current frame yet")
                        }
                    } else {
                        print("❌ ARAnchorManager.arSession is nil")
                    }
                    self?.onSessionReady?()
                }
                return
            }
            print("✅ ARSession ready on first check")
            self.onSessionReady?()
        }
        
        // Add close button
        setupCloseButton()
        
        // Set up MethodChannel for captions
        if let appDelegate = UIApplication.shared.delegate as? FlutterAppDelegate,
           let controller = appDelegate.window?.rootViewController as? FlutterViewController {
            captionChannel = FlutterMethodChannel(name: "live_captions_xr/caption_methods", binaryMessenger: controller.binaryMessenger)
            captionChannel?.setMethodCallHandler { [weak self] (call, result) in
                if call.method == "placeCaption" {
                    guard let args = call.arguments as? [String: Any],
                          let transform = args["transform"] as? [Double],
                          let text = args["text"] as? String, transform.count == 16 else {
                        result(FlutterError(code: "BAD_ARGS", message: "Invalid arguments", details: nil))
                        return
                    }
                    var matrix = matrix_identity_float4x4
                    for row in 0..<4 {
                        for col in 0..<4 {
                            matrix[row][col] = Float(transform[row * 4 + col])
                        }
                    }
                    self?.placeCaption(at: matrix, text: text)
                    result(nil)
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
        sceneView.session.pause()
        print("⏸️ ARSession paused")
        
        // Clear the session reference in ARAnchorManager
        ARAnchorManager.arSession = nil
        ARAnchorManager.anchorMap.removeAll()
        print("🧹 ARAnchorManager session and anchors cleared")
        
        dismiss(animated: true, completion: nil)
        print("✅ ARViewController dismissed")
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
        // Example: Send detected anchor to Dart
        let label = "ARAnchor"
        let confidence = 0.9
        let boundingBox: [Double] = [0, 0, 100, 100] // TODO: Use real bounding box if available
        VisualObjectPlugin.sendVisualObjectDetected(anchor: anchor, label: label, confidence: confidence, boundingBox: boundingBox)
    }

    // TODO: Implement didUpdate for dynamic objects, and use real detection logic

    func placeCaption(at transform: simd_float4x4, text: String) {
        let anchor = ARAnchor(transform: transform)
        sceneView.session.add(anchor: anchor)
        if #available(iOS 14.0, *) {
            let captionNode = CaptionNode(text: text)
            sceneView.scene.rootNode.addChildNode(captionNode)
            captionNode.simdTransform = transform
        }
    }
}
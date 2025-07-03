import UIKit
import ARKit
import Flutter

class ARViewController: UIViewController, ARSCNViewDelegate {
    var sceneView: ARSCNView!
    var captionChannel: FlutterMethodChannel?

    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView = ARSCNView(frame: view.bounds)
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(sceneView)
        sceneView.delegate = self
        sceneView.session = ARSession()
        
        // Set the session in ARAnchorManager for plugin access
        ARAnchorManager.arSession = sceneView.session
        
        let config = ARWorldTrackingConfiguration()
        sceneView.session.run(config)
        
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
        sceneView.session.pause()
        
        // Clear the session reference in ARAnchorManager
        ARAnchorManager.arSession = nil
        ARAnchorManager.anchorMap.removeAll()
        
        dismiss(animated: true, completion: nil)
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
        let captionNode = CaptionNode(text: text)
        sceneView.scene.rootNode.addChildNode(captionNode)
        captionNode.simdTransform = transform
    }
}
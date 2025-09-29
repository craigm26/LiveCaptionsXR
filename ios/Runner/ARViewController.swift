import UIKit
import ARKit
import Flutter

@available(iOS 14.0, *)
class ARViewController: UIViewController, ARSCNViewDelegate {
    var sceneView: ARSCNView!
    var captionChannel: FlutterMethodChannel?
    var onSessionReady: (() -> Void)?
    private var hasShownSafetyWarning = false
    private var safetyOverlayView: UIView?

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
        
        // Note: SpatialCaptionsPlugin sceneView assignment now handled via method channel
        // The plugin will call back to get the sceneView reference when needed
        print("🗨️ SpatialCaptionsPlugin will be initialized via method channel")
        
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

        // Show AR safety warning immediately when AR experience begins
        presentSafetyWarningIfNeeded()

        // Set up MethodChannels for captions and AR frames
        if let appDelegate = UIApplication.shared.delegate as? FlutterAppDelegate,
           let controller = appDelegate.window?.rootViewController as? FlutterViewController {
            // Note: Caption placement now handled by spatial_captions plugin
            
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

    private func presentSafetyWarningIfNeeded() {
        guard !hasShownSafetyWarning else { return }
        hasShownSafetyWarning = true

        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        view.addSubview(overlay)
        safetyOverlayView = overlay

        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 16
        container.alignment = .center
        container.translatesAutoresizingMaskIntoConstraints = false
        overlay.addSubview(container)

        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            container.leadingAnchor.constraint(greaterThanOrEqualTo: overlay.leadingAnchor, constant: 24),
            container.trailingAnchor.constraint(lessThanOrEqualTo: overlay.trailingAnchor, constant: -24)
        ])

        let titleLabel = UILabel()
        titleLabel.text = "Stay safe while using AR"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        titleLabel.textAlignment = .center

        let messageLabel = UILabel()
        messageLabel.text = "Use AR with a parent or guardian if you're under 13. Always stay aware of your surroundings."
        messageLabel.textColor = .white
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center

        let continueButton = UIButton(type: .system)
        continueButton.setTitle("I Understand", for: .normal)
        continueButton.setTitleColor(.black, for: .normal)
        continueButton.backgroundColor = .white
        continueButton.layer.cornerRadius = 10
        continueButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        continueButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        continueButton.addTarget(self, action: #selector(dismissSafetyWarning), for: .touchUpInside)

        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(messageLabel)
        container.addArrangedSubview(continueButton)
    }

    @objc private func dismissSafetyWarning() {
        UIView.animate(withDuration: 0.25, animations: {
            self.safetyOverlayView?.alpha = 0
        }, completion: { _ in
            self.safetyOverlayView?.removeFromSuperview()
            self.safetyOverlayView = nil
        })
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
        // Regular anchor detection for visual objects
        let label = "ARAnchor" 
        let confidence = 0.9
        let boundingBox: [Double] = [0, 0, 100, 100] // TODO: Use real bounding box if available
        VisualObjectPlugin.sendVisualObjectDetected(anchor: anchor, label: label, confidence: confidence, boundingBox: boundingBox)
    }

    // TODO: Implement didUpdate for dynamic objects, and use real detection logic

    
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
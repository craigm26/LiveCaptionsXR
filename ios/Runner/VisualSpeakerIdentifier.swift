import AVFoundation
import Vision
import Combine
import Flutter

@available(iOS 14.0, *)
class VisualSpeakerIdentifier: NSObject {
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.craig.livecaptions.sessionQueue")
    private let visionQueue = DispatchQueue(label: "com.craig.livecaptions.visionQueue")

    private var channel: FlutterMethodChannel
    private var isAudioSpeechDetected = false // This should be updated from audio service
    private var lastKnownSpeaker: VNFaceObservation?

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
        setupCaptureSession()
    }

    func startDetection() {
        sessionQueue.async {
            self.captureSession.startRunning()
        }
    }

    func stopDetection() {
        sessionQueue.async {
            self.captureSession.stopRunning()
        }
    }
    
    // This would be called from the audio service via the platform channel
    func setSpeechDetected(_ isDetected: Bool) {
        self.isAudioSpeechDetected = isDetected
    }

    private func setupCaptureSession() {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("❌ No front camera found")
            return
        }

        captureSession.beginConfiguration()

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            print("❌ Failed to create camera input: \(error)")
            captureSession.commitConfiguration()
            return
        }

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            videoOutput.setSampleBufferDelegate(self, queue: visionQueue)
        }

        captureSession.commitConfiguration()
    }

    private func processFrame(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: self.handleFaceLandmarks)
        
        do {
            try VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([faceLandmarksRequest])
        } catch {
            print("❌ Vision request failed: \(error)")
        }
    }

    private func handleFaceLandmarks(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNFaceObservation] else { return }

        var activeSpeaker: VNFaceObservation?
        var maxMouthMovement: CGFloat = 0.0

        for face in results {
            guard let landmarks = face.landmarks else { continue }
            
            let mouthMovement = calculateMouthMovement(landmarks: landmarks)
            
            if mouthMovement > maxMouthMovement {
                maxMouthMovement = mouthMovement
                activeSpeaker = face
            }
        }
        
        // Only update if speech is detected from the audio side
        if isAudioSpeechDetected && maxMouthMovement > 0.1 { // Threshold to avoid noise
             self.lastKnownSpeaker = activeSpeaker
        } else {
             self.lastKnownSpeaker = nil
        }
        
        DispatchQueue.main.async {
            self.reportSpeakerUpdate(self.lastKnownSpeaker)
        }
    }
    
    private func calculateMouthMovement(landmarks: VNFaceLandmarks2D) -> CGFloat {
        guard let innerLips = landmarks.innerLips, let outerLips = landmarks.outerLips else {
            return 0.0
        }
        // A simple metric: average distance between corresponding top and bottom lip points
        let topInner = innerLips.normalizedPoints[9] // A point on the top inner lip
        let bottomInner = innerLips.normalizedPoints[3] // A point on the bottom inner lip
        let movement = topInner.distance(to: bottomInner)
        return movement
    }

    private func reportSpeakerUpdate(_ speaker: VNFaceObservation?) {
        guard let speaker = speaker else {
            channel.invokeMethod("onSpeakerUpdated", arguments: nil)
            return
        }
        
        // Convert bounding box to Flutter's logical pixels
        let boundingBox = speaker.boundingBox
        let arguments: [String: Any] = [
            "x": boundingBox.origin.x,
            "y": 1.0 - boundingBox.origin.y - boundingBox.height, // Vision's origin is bottom-left
            "width": boundingBox.width,
            "height": boundingBox.height,
            "confidence": speaker.confidence
        ]
        channel.invokeMethod("onSpeakerUpdated", arguments: arguments)
    }
}

@available(iOS 14.0, *)
extension VisualSpeakerIdentifier: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processFrame(sampleBuffer: sampleBuffer)
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return hypot(self.x - point.x, self.y - point.y)
    }
}

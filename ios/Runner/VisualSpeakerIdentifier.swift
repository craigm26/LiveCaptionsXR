import AVFoundation
import Vision
import Combine
import Flutter

@available(iOS 14.0, *)
class VisualSpeakerIdentifier: NSObject, FlutterPlugin {
    // Required by FlutterPlugin protocol
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.craig.livecaptions/visual", binaryMessenger: registrar.messenger())
        let instance = VisualSpeakerIdentifier(channel: channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.craig.livecaptions.sessionQueue")

    private var latestPixelBuffer: CVPixelBuffer?
    private var captureContinuation: CheckedContinuation<FlutterStandardTypedData?, Never>?

    init(channel: FlutterMethodChannel) {
        super.init()
        setupCaptureSession()
    }

    func captureFrame() async -> FlutterStandardTypedData? {
        return await withCheckedContinuation { continuation in
            sessionQueue.async {
                self.captureSession.startRunning()
                self.captureContinuation = continuation

                // Timeout to prevent hanging
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if self.captureContinuation != nil {
                        self.captureContinuation?.resume(returning: nil)
                        self.captureContinuation = nil
                        self.captureSession.stopRunning()
                    }
                }
            }
        }
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
            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        }

        captureSession.commitConfiguration()
    }
}

@available(iOS 14.0, *)
extension VisualSpeakerIdentifier: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer), self.captureContinuation != nil else {
            return
        }

        // Convert CVPixelBuffer to a UIImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            self.captureContinuation?.resume(returning: nil)
            self.captureContinuation = nil
            self.captureSession.stopRunning()
            return
        }
        let uiImage = UIImage(cgImage: cgImage)

        // Convert UIImage to JPEG data
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.8) else {
            self.captureContinuation?.resume(returning: nil)
            self.captureContinuation = nil
            self.captureSession.stopRunning()
            return
        }

        let flutterData = FlutterStandardTypedData(bytes: jpegData)
        self.captureContinuation?.resume(returning: flutterData)
        self.captureContinuation = nil
        self.captureSession.stopRunning()
    }
}

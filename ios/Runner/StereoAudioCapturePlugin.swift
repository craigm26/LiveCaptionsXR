import Foundation
import AVFoundation
import Flutter

@objc class StereoAudioCapturePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var audioEngine: AVAudioEngine?
    private var eventSink: FlutterEventSink?
    private var isRecording = false
    private let sampleRate: Double = 16000.0
    private let bufferSize: AVAudioFrameCount = 1024

    static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: "live_captions_xr/audio_capture_methods", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "live_captions_xr/audio_capture_events", binaryMessenger: registrar.messenger())
        let instance = StereoAudioCapturePlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    // MARK: - MethodChannel
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startRecording":
            startRecording(result: result)
        case "stopRecording":
            stopRecording(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - EventChannel
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    // MARK: - Audio Capture
    private func startRecording(result: @escaping FlutterResult) {
        guard !isRecording else {
            result(nil)
            return
        }
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            guard granted else {
                result(FlutterError(code: "PERMISSION_DENIED", message: "Microphone permission denied", details: nil))
                return
            }
            DispatchQueue.main.async {
                do {
                    try self.configureSession()
                    self.audioEngine = AVAudioEngine()
                    guard let input = self.audioEngine?.inputNode else {
                        result(FlutterError(code: "NO_INPUT", message: "No audio input node", details: nil))
                        return
                    }
                    let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: self.sampleRate, channels: 2, interleaved: true)!
                    input.installTap(onBus: 0, bufferSize: self.bufferSize, format: format) { buffer, _ in
                        self.handleAudioBuffer(buffer: buffer)
                    }
                    self.audioEngine?.prepare()
                    try self.audioEngine?.start()
                    self.isRecording = true
                    result(nil)
                } catch {
                    result(FlutterError(code: "AUDIO_ERROR", message: "\(error)", details: nil))
                }
            }
        }
    }

    private func stopRecording(result: @escaping FlutterResult) {
        guard isRecording else {
            result(nil)
            return
        }
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isRecording = false
        result(nil)
    }

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setPreferredSampleRate(sampleRate)
        try session.setPreferredIOBufferDuration(Double(bufferSize) / sampleRate)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func handleAudioBuffer(buffer: AVAudioPCMBuffer) {
        guard let eventSink = eventSink, isRecording else { return }
        guard let floatChannelData = buffer.floatChannelData, buffer.format.channelCount == 2 else { return }
        let frameLength = Int(buffer.frameLength)
        let left = floatChannelData[0]
        let right = floatChannelData[1]
        // Interleave L/R into a single Float32List
        var interleaved = [Float](repeating: 0, count: frameLength * 2)
        for i in 0..<frameLength {
            interleaved[i * 2] = left[i]
            interleaved[i * 2 + 1] = right[i]
        }
        let data = Data(buffer: UnsafeBufferPointer(start: &interleaved, count: interleaved.count))
        eventSink(FlutterStandardTypedData(bytes: data))
    }
} 
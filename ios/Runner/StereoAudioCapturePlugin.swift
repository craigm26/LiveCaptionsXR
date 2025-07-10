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
                    
                    // Remove any existing taps before installing new ones
                    input.removeTap(onBus: 0)
                    
                    // Use the input node's native format instead of forcing our own
                    let inputFormat = input.inputFormat(forBus: 0)
                    
                    // Create a compatible format for our processing
                    // Fall back to mono if stereo is not available
                    let channelCount = min(inputFormat.channelCount, 2)
                    guard let format = AVAudioFormat(
                        commonFormat: .pcmFormatFloat32,
                        sampleRate: inputFormat.sampleRate,
                        channels: channelCount,
                        interleaved: true
                    ) else {
                        result(FlutterError(code: "AUDIO_FORMAT_ERROR", message: "Cannot create compatible audio format", details: nil))
                        return
                    }
                    
                    // Install tap with proper format validation
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
        
        // Safely remove tap
        if let inputNode = audioEngine?.inputNode {
            inputNode.removeTap(onBus: 0)
        }
        
        audioEngine?.stop()
        audioEngine = nil
        isRecording = false
        result(nil)
    }

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        
        // Configure for recording with playback capability
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
        
        // Try to set preferred sample rate, but don't fail if it's not supported
        do {
            try session.setPreferredSampleRate(sampleRate)
        } catch {
            print("Warning: Could not set preferred sample rate: \(error)")
        }
        
        // Try to set preferred buffer duration
        do {
            try session.setPreferredIOBufferDuration(Double(bufferSize) / sampleRate)
        } catch {
            print("Warning: Could not set preferred IO buffer duration: \(error)")
        }
        
        // Activate the session
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func handleAudioBuffer(buffer: AVAudioPCMBuffer) {
        guard let eventSink = eventSink, isRecording else { return }
        guard let floatChannelData = buffer.floatChannelData else { return }

        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)

        // Create a new Float32 array to hold the interleaved audio data.
        var interleavedData = [Float32](repeating: 0.0, count: frameLength * 2)

        if channelCount == 1 {
            // If the audio is mono, duplicate the channel to create a stereo effect.
            let monoChannel = floatChannelData[0]
            for i in 0..<frameLength {
                interleavedData[2 * i] = monoChannel[i]
                interleavedData[2 * i + 1] = monoChannel[i]
            }
        } else if channelCount >= 2 {
            // If the audio is stereo or has more than two channels, use the first two channels.
            let leftChannel = floatChannelData[0]
            let rightChannel = floatChannelData[1]
            for i in 0..<frameLength {
                interleavedData[2 * i] = leftChannel[i]
                interleavedData[2 * i + 1] = rightChannel[i]
            }
        } else {
            // If there are no channels, do not send any data.
            return
        }

        // Convert the interleaved data to a Data object.
        let byteCount = interleavedData.count * MemoryLayout<Float32>.size
        let data = Data(bytes: &interleavedData, count: byteCount)

        // Send the data to the Flutter side.
        eventSink(FlutterStandardTypedData(bytes: data))
    }
} 
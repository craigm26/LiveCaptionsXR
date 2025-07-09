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
        
        // Handle both mono and stereo formats
        var interleaved = [Float]()
        
        if channelCount == 1 {
            // Mono: duplicate to create stereo
            let mono = floatChannelData[0]
            interleaved.reserveCapacity(frameLength * 2)
            for i in 0..<frameLength {
                interleaved.append(mono[i])
                interleaved.append(mono[i])
            }
        } else if channelCount >= 2 {
            // Stereo or multi-channel: use first two channels
            let left = floatChannelData[0]
            let right = floatChannelData[1]
            interleaved.reserveCapacity(frameLength * 2)
            for i in 0..<frameLength {
                interleaved.append(left[i])
                interleaved.append(right[i])
            }
        } else {
            // No channels, return empty
            return
        }
        
        // Ensure we have an even number of samples for stereo processing
        // Fix any odd sample count by truncating the last sample if needed
        if interleaved.count % 2 != 0 {
            print("⚠️ Audio buffer has odd sample count (\(interleaved.count)), truncating last sample for stereo compatibility")
            interleaved.removeLast()
        }
        
        // Ensure we have exactly the expected number of samples
        let expectedSampleCount = frameLength * 2
        guard interleaved.count == expectedSampleCount || interleaved.count == expectedSampleCount - 1 else {
            print("⚠️ Audio buffer size mismatch: expected \(expectedSampleCount), got \(interleaved.count)")
            return
        }
        
        // Create Data buffer with proper byte size calculation
        let byteCount = interleaved.count * MemoryLayout<Float>.size
        let data = Data(bytes: interleaved, count: byteCount)
        
        // Validate the data size before sending
        let expectedByteCount = interleaved.count * MemoryLayout<Float>.size
        guard data.count == expectedByteCount else {
            print("⚠️ Data size mismatch: expected \(expectedByteCount) bytes, got \(data.count) bytes")
            return
        }
        
        eventSink(FlutterStandardTypedData(bytes: data))
    }
} 
# 📱 On-Device Speech Localization and AR Captioning (iOS)

This guide outlines a prototype approach for running **Gemma 3n** on an iPhone to capture speech, localize the speaker and render captions in AR. Modern iPhones provide stereo microphones, high quality cameras and ARKit which enable this entirely on-device.

## Overview of the Flow

1. **Capture Stereo Audio** – Configure `AVAudioSession` for the built-in mics so that left/right channels reflect sound direction.
2. **Estimate Direction** – Compute the level difference (or time delay) between stereo channels to derive a horizontal angle to the speaker.
3. **Transcribe with Gemma 3n** – Down‑mix to mono and feed audio buffers into a Gemma 3n ASR instance for realtime transcripts.
4. **Visual Localization (optional)** – Use Vision or ARKit to detect faces and refine the speaker position.
5. **Display Captions** – Show subtitles either as 2D overlays on the camera feed or as 3D bubbles anchored in ARKit.

## Swift Skeleton

```swift
import AVFoundation

class SpeechLocalizer {
    private let gemmaModel = Gemma3nASR() // pseudo class
    private let audioEngine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private let audioFormat: AVAudioFormat

    init() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, options: [])
        try session.setMode(.measurement)
        try session.setActive(true)

        if let builtIn = session.availableInputs?.first(where: { $0.portType == .builtInMic }) {
            try session.setPreferredInput(builtIn)
            if let dataSource = builtIn.dataSources?.first(where: { $0.orientation == .front }) {
                if dataSource.supportedPolarPatterns?.contains(.stereo) == true {
                    try dataSource.setPreferredPolarPattern(.stereo)
                }
                try builtIn.setPreferredDataSource(dataSource)
            }
        }
        inputNode = audioEngine.inputNode
        audioFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: audioFormat) { [weak self] buffer, _ in
            self?.process(buffer)
        }
    }

    func start() throws {
        audioEngine.prepare(); try audioEngine.start()
    }

    private func process(_ buffer: AVAudioPCMBuffer) {
        guard let channels = buffer.floatChannelData, buffer.format.channelCount == 2 else { return }
        let left = channels[0], right = channels[1]
        let frames = Int(buffer.frameLength)
        var leftSum: Float = 0, rightSum: Float = 0
        vDSP_measqv(left, 1, &leftSum, UInt(frames))
        vDSP_measqv(right, 1, &rightSum, UInt(frames))
        let angle = (leftSum - rightSum) / (leftSum + rightSum) * (.pi/2)

        let mono = downmix(buffer)
        gemmaModel.transcribeAsync(audioPCM: mono) { [weak self] text in
            self?.onTranscription(text, angle)
        }
    }

    private func downmix(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer { /* ... */ }
    var onTranscription: (_ text: String, _ angle: Float) -> Void = { _, _ in }
}
```

## Displaying Captions

- **2D Mode** – Overlay a `UILabel` near the detected face or map the angle to a screen position.
- **3D Mode** – Use ARKit to create an `ARAnchor` in the direction of the sound and attach a `SceneKit` text bubble. A billboard constraint keeps the text facing the camera.

```swift
func anchorForSpeaker(angle: Float, distance: Float = 2.0) -> ARAnchor {
    guard let frame = sceneView.session.currentFrame else {
        return ARAnchor(transform: matrix_identity_float4x4)
    }
    var dir = simd_float4(0, 0, -1, 0)
    let rot = simd_float4x4(SCNMatrix4MakeRotation(angle, 0, 1, 0))
    dir = rot * dir
    var transform = matrix_identity_float4x4
    transform.columns.3.x = dir.x * distance
    transform.columns.3.z = dir.z * distance
    return ARAnchor(transform: frame.camera.transform * transform)
}
```

The caption node can be a `SCNText` geometry with a semi‑transparent `SCNPlane` background, fading in and out as speech is detected.

---

This document complements the main PRD by illustrating how the **Gemma 3n** audio model can be paired with ARKit on iOS. Together these components enable live, spatial captions that appear next to the speaker—useful both for experimentation on iPhone and for informing future cross‑platform work.

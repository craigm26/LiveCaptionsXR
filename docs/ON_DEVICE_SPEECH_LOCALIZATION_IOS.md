# 📱 On-Device Speech Localization and AR Captioning (iOS)

This guide outlines the iOS-specific implementation details for the speech localization and AR captioning features of `live_captions_xr`, following the architecture defined in `ARCHITECTURE.md`.

## Overview of the iOS Implementation

The iOS implementation leverages Apple's native frameworks for audio capture, computer vision, and augmented reality, which are called from the Dart service layer via platform channels.

1.  **Stereo Audio Capture (`AVAudioEngine` + `StereoAudioCapture`):** The native Swift code configures an `AVAudioSession` for stereo recording and uses `AVAudioEngine` to capture high-quality stereo PCM buffers. These buffers are streamed to Dart through the `StereoAudioCapture` class.
2.  **Direction Estimation (Accelerate Framework):** The stereo buffers are analyzed to estimate the speaker's direction. This can be done using a basic amplitude comparison or a more advanced TDOA/GCC-PHAT algorithm (as defined in PRD #3), implemented efficiently using the Accelerate framework.
3.  **Gemma 3n Inference (`MediaPipeTasks`):** The audio is downmixed to mono and, along with any visual context, is sent to the `MediaPipeTasks` framework to be processed by the Gemma 3n model for transcription.
4.  **Visual Localization (`Vision` & `ARKit`):** The camera feed is processed by the Vision framework to detect faces and identify the active speaker. ARKit is used to determine the 3D position of the detected face.
5.  **AR Caption Rendering (`ARKit` & `SceneKit`/`RealityKit`):** The final transcription and position are used to create and place a 3D caption bubble in the AR scene using `ARKit`.

## Swift Implementation Snippet (Conceptual)

This snippet illustrates how the native iOS components work together.

```swift
import AVFoundation
import MediaPipeTasksGenAI
import ARKit

// This class would be called from the Flutter app via platform channels.
class LocalizationAndCaptioningEngine {
    private let gemmaHelper: Gemma3nInference // Manages MediaPipe
    private let arSession: ARSession
    
    // ... initialization ...

    // Called when a new audio buffer is available from AVAudioEngine
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // 1. Estimate direction from the stereo buffer
        let angle = estimateDirection(from: buffer) // Implements TDOA
        
        // 2. Get transcription from Gemma 3n via MediaPipe
        let monoBuffer = downmixToMono(buffer: buffer)
        gemmaHelper.transcribeAsync(audioPCM: monoBuffer) { [weak self] text in
            // 3. Once transcription is ready, get the latest AR frame
            guard let self = self, let frame = self.arSession.currentFrame else { return }
            
            // 4. (Optional) Find the speaker's face in the frame
            let faceTransform = self.findSpeakerFace(in: frame)
            
            // 5. Create an AR anchor and send its ID back to Flutter
            let anchor = self.createAnchor(angle: angle, faceTransform: faceTransform, cameraTransform: frame.camera.transform)
            self.arSession.add(anchor: anchor)
            
            // 6. Send the final data (text and anchor ID) back to Flutter
            self.sendResultToFlutter(text: text, anchorID: anchor.identifier)
        }
    }
    
    // ... other helper methods for TDOA, AR anchor creation, etc. ...
}
```

This native Swift code handles the high-performance, real-time processing, while the Flutter app manages the UI and overall application logic. This approach ensures a responsive user experience by keeping heavy computations off the main Dart thread.

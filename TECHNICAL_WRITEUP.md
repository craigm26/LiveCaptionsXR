# live_captions_xr: Technical Writeup

**Real-time, spatially-aware closed captioning powered by on-device multimodal AI with Gemma 3n and MediaPipe.**

---

## Executive Summary

`live_captions_xr` represents a pioneering application of Google's Gemma 3n multimodal AI model to solve a critical accessibility challenge: providing real-time, spatially-aware closed captioning for the Deaf and Hard of Hearing (D/HH) community. By leveraging Gemma 3n's ability to process audio, visual, and textual inputs simultaneously—all orchestrated through the high-performance Google MediaPipe framework—we've created a robust, on-device solution that transforms traditional flat captioning into an immersive, contextual communication aid.

**Key Innovation**: Rather than simply transcribing speech, `live_captions_xr` provides spatial captioning with contextual understanding. It fuses multimodal data streams through Gemma 3n to answer not just "what was said," but "who said it," "where are they," and "what is the context?"

---

## Architecture Overview

### System Architecture

The system employs a layered architecture centered around the MediaPipe framework for efficient, on-device inference.

```
[Microphone Array] ──┐
                    ├──► [MediaPipe Inference Engine] ──► [Gemma 3n Core] ──► [Spatial Caption]
[Camera Feed] ───────┤
                    │
[User Context] ─────┘
```

### Technical Stack Selection

| **Component**        | **Technology Choice**        | **Rationale**                                                                                             |
| -------------------- | ---------------------------- | --------------------------------------------------------------------------------------------------------- |
| **Frontend Framework** | Flutter 3.x with Dart 3      | Single codebase for iOS/Android, native performance, excellent accessibility support.                     |
| **AI Model**         | Google Gemma 3n (`.task`)    | State-of-the-art on-device multimodal model.                                                              |
| **Model Runtime**    | Google MediaPipe Tasks       | Official, optimized framework for running Google's AI models on-device with hardware acceleration.        |
| **State Management** | flutter_bloc (Cubit pattern) | Predictable state management for complex AI workflows.                                                    |
| **Service Architecture** | Dependency Injection (get_it) | Clean separation of concerns and a testable service layer.                                                |

---

## Gemma 3n Integration via MediaPipe: A Technical Deep Dive

### Why MediaPipe is the Right Choice

The core of our technical strategy is the use of **Google's MediaPipe Tasks library** as the inference engine.

*   **Performance:** MediaPipe is specifically designed for high-performance, on-device ML. It provides optimized, hardware-accelerated execution on both Android (via NNAPI and GPU delegates) and iOS (via CoreML and Metal delegates).
*   **Simplicity:** It provides a high-level API for loading `.task` models, preparing data, and running inference, abstracting away the complexities of the underlying TFLite runtime.
*   **Official Support:** As Google's official framework for on-device AI, it ensures compatibility and access to the latest features and optimizations for models like Gemma 3n.

### Multimodal Fusion Workflow

1.  **Audio Stream Processing:**
    *   Continuous audio capture from the device's stereo microphones.
    *   Real-time sound localization via Time Difference of Arrival (TDOA) analysis.
    *   The audio stream is fed into the MediaPipe session via the `GemmaASR` service for streaming ASR.

2.  **Visual Context Acquisition:**
    *   The camera feed is analyzed to detect faces and identify active speakers.
    *   The current visual frame is provided to the MediaPipe session as context.

3.  **Contextual Intelligence with MediaPipe:**
    *   The native MediaPipe session receives the audio stream, the visual frame, and any text context from the Flutter app.
    *   Gemma 3n processes these inputs simultaneously to generate a contextually aware transcription.

### Example Native Implementation (Conceptual Swift)

```swift
// Swift code on the iOS side using MediaPipe
import MediaPipeTasksGenAI

class Gemma3nInference {
    var llmInference: LlmInference
    
    // Initialize with the .task model
    init(modelPath: String) {
        let options = LlmInferenceOptions()
        options.modelPath = modelPath
        self.llmInference = LlmInference(options: options)
    }
    
    // Run inference with multimodal inputs
    func generateResponse(text: String, image: MPImage, audio: [Float]) -> String {
        // Simplified for clarity: actual implementation would handle streaming audio
        let session = llmInference.createSession()
        session.addQuery(text: text)
        session.addQuery(image: image)
        // session.addQuery(audio: audio) // Conceptual
        
        let result = session.generateResponse()
        return result.text
    }
}
```

This native code is then called from the Flutter `Gemma3nService` via a platform channel.

---

## Implementation Architecture

### Service Layer Design

The application follows a clean architecture pattern with a clear separation between the Flutter (Dart) and native (Kotlin/Swift) code.

*   **Dart Services:**
    *   `AudioService`: Manages audio capture and TDOA analysis in Dart.
    *   `VisualService`: Manages the camera and face detection in Dart.
    *   `Gemma3nService`: Orchestrates the process, sending the prepared data to the native layer via a platform channel and receiving the results.
*   **Native Platform Code:**
    *   Handles all MediaPipe-related tasks: model loading, session management, and inference.
    *   Receives data from Flutter, runs it through the Gemma 3n model, and returns the result.

This separation allows us to leverage the strengths of each environment: Flutter for building a beautiful, cross-platform UI, and native code for high-performance, hardware-accelerated ML inference.

---

## Accessibility-First Design Decisions

Our design process is guided by the principle of "nothing about us without us," involving the D/HH community in testing and feedback.

*   **Visual Interface:** High-contrast themes, scalable text, and clear spatial indicators.
*   **Haptic Feedback:** A custom haptic system conveys directional and contextual information, turning the device into a tactile awareness tool.

---

## Performance Optimization

*   **Hardware Acceleration:** Fully utilizing the GPU and ML accelerators on iOS and Android via MediaPipe.
*   **Efficient Data Transfer:** Minimizing the amount of data passed over the platform channel.
*   **Asynchronous Processing:** All inference and heavy processing are done on background threads to keep the UI smooth.

---

## New Features (2025 Update)
- **Hybrid Localization Engine:** Fuses audio, vision, and IMU data using a Kalman filter for robust, real-time speaker localization.
- **ARKit/ARCore Plugin Integration:** Native plugins for AR anchor management, visual object detection, and caption placement, with Dart wrappers and MethodChannel communication.
- **Real-time AR Caption Placement:** Captions are anchored in AR at the fused speaker position as soon as speech is recognized.
- **Streaming ASR & Multimodal Fusion:** On-device Gemma 3n model for low-latency, privacy-preserving speech recognition and multimodal context.
- **Dart-Native Communication:** New MethodChannels for AR navigation, caption placement, hybrid localization, and visual object detection.

## End-to-End Pipeline
1. **Audio & Vision Capture:** Real-time stereo audio and camera frames.
2. **Direction Estimation:** Audio direction (RMS, GCC-PHAT) and visual speaker identification.
3. **Hybrid Localization Fusion:** Kalman filter fuses all modalities for 3D world position.
4. **Streaming ASR:** Real-time speech transcription.
5. **AR Caption Placement:** Fused transform and caption sent to native AR view for 3D anchoring.

## MethodChannels
- `live_captions_xr/ar_navigation`: Launch native AR view.
- `live_captions_xr/caption_methods`: Place captions in AR.
- `live_captions_xr/hybrid_localization_methods`: Hybrid localization engine API.
- `live_captions_xr/visual_object_methods`: Visual object detection from native.

## How Captions Are Anchored
- The hybrid localization engine provides a fused 3D transform for the speaker.
- When a final transcript is available, the caption and transform are sent to native AR for placement.
- Captions appear in AR at the correct spatial location, following the speaker.

---

## Conclusion

`live_captions_xr` demonstrates a robust, production-ready approach to deploying advanced multimodal AI models like Gemma 3n on mobile devices. By using Google's official MediaPipe framework, we achieve the performance and stability necessary for a real-time accessibility application, while our layered architecture ensures the system is maintainable and scalable.

**Technical Achievement**: Successfully implementing a high-performance, on-device, multimodal AI pipeline that solves a real-world accessibility problem.

**Impact Goal**: Empowering independence and communication accessibility for the 466 million people worldwide with hearing loss.

---
See [ARCHITECTURE.md](ARCHITECTURE.md), [README.md](README.md), and [prd/](prd/) for more.

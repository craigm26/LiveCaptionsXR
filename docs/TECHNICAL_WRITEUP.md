# Live Captions XR: Technical Writeup

**Real-time, spatially-aware closed captioning powered by on-device multimodal AI with Gemma 3n and MediaPipe.**

---

## Executive Summary

`Live Captions XR` represents a pioneering application of Google's Gemma 3n multimodal AI model to solve a critical accessibility challenge: providing real-time, spatially-aware closed captioning for the Deaf and Hard of Hearing (D/HH) community. By leveraging Gemma 3n's ability to process audio, visual, and textual inputs simultaneously—all orchestrated through the high-performance Google MediaPipe framework—we've created a robust, on-device solution that transforms traditional flat captioning into an immersive, contextual communication aid.

**Key Innovation**: Rather than simply transcribing speech, `Live Captions XR` provides spatial captioning with contextual understanding. It fuses multimodal data streams through Gemma 3n to answer not just "what was said," but "who said it," "where are they," and "what is the context?"

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

## Speaker Localization Strategy

The core challenge is to accurately place captions in 3D space corresponding to the speaker's location. This is achieved through a **Hybrid Localization Engine**.

- **Multimodal Data Fusion:** The engine fuses data from multiple on-device sensors:
    - **Audio:** Direction is estimated from the stereo microphone array using techniques like RMS and GCC-PHAT.
    - **Vision:** The camera is used for visual detection of potential speakers.
    - **Inertial:** The **IMU** provides device orientation data.
- **Kalman Filter:** A Kalman filter is employed to merge these data streams, providing a robust and real-time estimation of the speaker's 3D position.

## On-Device AI & Speech Recognition

- **Speech-to-Text:** The app uses a **Gemma 3n `.task` model** for streaming, on-device Automatic Speech Recognition (ASR).
- **Inference Engine:** The **MediaPipe LLM Inference API** is used to run the Gemma model efficiently on-device.
- **Multimodal Context:** The system is designed for multimodal fusion, using both audio and vision to provide context for the ASR engine.
- **Privacy:** A key design principle is **privacy**. All sensor data (camera, microphone) is processed locally on the device and is not sent to the cloud.

## Key MethodChannels

The following MethodChannels are critical for the app's functionality. Gemini should be aware of their purpose when analyzing code or implementing new features.

- `live_captions_xr/ar_navigation`: Used to initiate and manage the transition from the Flutter UI to the native AR view.
- `live_captions_xr/caption_methods`: The primary channel for sending finalized text and the corresponding 3D transform to the native layer for rendering AR captions.
- `live_captions_xr/hybrid_localization_methods`: Facilitates communication between the Dart layer and the native Hybrid Localization Engine.
- `live_captions_xr/visual_object_methods`: Sends information about visually detected objects (e.g., faces) from the native AR view back to the Dart application logic.

---

## Conclusion

`Live Captions XR` demonstrates a robust, production-ready approach to deploying advanced multimodal AI models like Gemma 3n on mobile devices. By using Google's official MediaPipe framework, we achieve the performance and stability necessary for a real-time accessibility application, while our layered architecture ensures the system is maintainable and scalable.

**Technical Achievement**: Successfully implementing a high-performance, on-device, multimodal AI pipeline that solves a real-world accessibility problem.

**Impact Goal**: Empowering independence and communication accessibility for the 466 million people worldwide with hearing loss.

---
See [ARCHITECTURE.md](ARCHITECTURE.md), [README.md](README.md), and [prd/](prd/) for more.

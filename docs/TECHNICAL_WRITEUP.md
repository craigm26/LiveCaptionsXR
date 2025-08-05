# Live Captions XR: Technical Writeup

**Real-time, spatially-aware closed captioning powered by on-device AI.**

---

## Executive Summary

`Live Captions XR` represents a pioneering application of on-device AI to solve a critical accessibility challenge: providing real-time, spatially-aware closed captioning for the Deaf and Hard of Hearing (D/HH) community. By leveraging the `whisper_ggml` package for high-performance, on-device speech recognition and `flutter_gemma` for contextual enhancement, we've created a robust solution that transforms traditional flat captioning into an immersive, contextual communication aid.

**Key Innovation**: Rather than simply transcribing speech, `Live Captions XR` provides spatial captioning with contextual understanding. It fuses multimodal data streams to answer not just "what was said," but "who said it," and "where are they."

---

## Architecture Overview

### System Architecture

The system employs a layered architecture centered around platform-specific speech recognition for efficient, on-device processing, enhanced by `flutter_gemma` for contextual understanding.

```
[Microphone Array] ──┐
                    ├──► [Hybrid Localization Engine] ──► [3D Position] ──► [Spatial Caption]
[Camera Feed] ───────┤
                    │
[IMU] ──────────────┘

[Audio Stream] ──► [Platform Speech Recognition] ──► [Raw Transcript] ──► [flutter_gemma/Gemma3n] ──► [Enhanced Caption]
```

### Technical Stack Selection

| **Component** | **Technology Choice** | **Rationale** |
| --- | --- | --- |
| **Frontend Framework** | Flutter 3.x with Dart 3 | Single codebase for iOS/Android, native performance, excellent accessibility support. |
| **Speech Recognition**| **Platform-specific** | **Android**: `whisper_ggml` (on-device Whisper), **iOS**: Apple Speech Recognition (native) |
| **Text Enhancement** | `flutter_gemma` | On-device contextual enhancement using Gemma 3n model. |
| **State Management** | flutter_bloc (Cubit pattern) | Predictable state management for complex AI workflows. |
| **Service Architecture** | Dependency Injection (get_it) | Clean separation of concerns and a testable service layer. |
| **AR** | ARKit (iOS), ARCore (Android) | Native AR frameworks for the best performance and features. |
| **Permissions** | `permission_handler` | A reliable way to request and manage device permissions. |
| **Camera** | `camera` | The official Flutter camera plugin. |
| **Audio Capture** | `flutter_sound` | Robust audio capture and streaming capabilities. |

---

## Platform-Specific Speech Recognition: A Technical Deep Dive

### Android: `whisper_ggml` Integration

For Android devices, the core of our technical strategy is the use of **the `whisper_ggml` package** as the speech recognition engine.

*   **Performance:** `whisper_ggml` is specifically designed for high-performance, on-device speech recognition. It provides optimized inference using GGML (Graphical Language Model) format, making it perfect for mobile devices.
*   **Offline Capability:** Unlike cloud-based solutions, `whisper_ggml` operates entirely on-device, ensuring privacy and reliability even without internet connectivity.
*   **Model Flexibility:** Supports multiple Whisper model sizes (tiny, base, small, medium, large) allowing us to balance accuracy and performance based on device capabilities.
*   **Real-time Processing:** Designed for streaming audio input with low-latency transcription results.

### Speech Recognition Workflow

1.  **Audio Stream Processing:**
    *   Continuous audio capture from the device's stereo microphones using `flutter_sound`.
    *   The audio stream is fed into the `WhisperService` for real-time processing.

2.  **Speech Recognition (Platform-Specific):**
*   **Android**: The `WhisperService` initializes the `whisper_ggml` plugin with the appropriate model.
*   **iOS**: The `AppleSpeechService` uses the native Apple Speech Recognition framework.
    *   It processes audio chunks in real-time and provides streaming transcription results.

### Example Dart Implementation

```dart
// Dart code using the whisper_ggml package
import 'package:whisper_ggml/whisper_ggml.dart';

class WhisperService {
  Whisper? _whisper;
  
  Future<void> initialize() async {
    _whisper = Whisper();
    await _whisper!.loadModel('whisper-base');
  }
  
  Future<SpeechResult> processAudioBuffer(Uint8List audioData) async {
    final result = await _whisper!.transcribe(audioData);
    return SpeechResult(
      text: result.text,
      confidence: result.confidence,
      isFinal: result.isFinal,
      timestamp: DateTime.now(),
    );
  }
}
```

---

## `flutter_gemma` Integration: Contextual Enhancement

### Why `flutter_gemma` for Enhancement

We use **`flutter_gemma`** with the Gemma 3n model to enhance raw transcriptions with contextual understanding.

*   **Contextual Enhancement:** Gemma 3n can improve punctuation, grammar, and contextual clarity of raw transcriptions.
*   **On-device Processing:** All enhancement happens locally, maintaining privacy and reducing latency.
*   **Multimodal Capabilities:** Gemma 3n can process text, audio, and images, enabling future multimodal enhancements.
*   **Real-time Enhancement:** Designed for streaming text input with efficient inference.

### Enhancement Workflow

1. **Raw Transcription:** Platform-specific speech recognition provides initial transcription
2. **Contextual Enhancement:** `flutter_gemma` processes the text to improve readability
3. **Spatial Placement:** Enhanced captions are placed in 3D space using the Hybrid Localization Engine

### Example Enhancement Implementation

```dart
// Dart code using the flutter_gemma package
import 'package:flutter_gemma/flutter_gemma.dart';

class Gemma3nService {
  InferenceModel? _inferenceModel;
  
  Future<String> enhanceText(String rawText) async {
    final session = await _inferenceModel!.createSession();
    await session.addQueryChunk(Message.text(text: _buildEnhancementPrompt(rawText)));
    final response = await session.getResponse();
    await session.close();
    return _cleanEnhancedText(response);
  }
}
```

---

## Implementation Architecture

### Service Layer Design

The application follows a clean architecture pattern with a clear separation between the Flutter (Dart) and native (Kotlin/Swift) code.

*   **Dart Services:**
    *   `AudioCaptureService`: Manages audio capture using `flutter_sound`.
    *   `WhisperService`: Handles speech recognition on Android using `whisper_ggml`.
*   `AppleSpeechService`: Handles speech recognition on iOS using Apple Speech Recognition.
    *   `Gemma3nService`: Manages text enhancement using `flutter_gemma`.
    *   `EnhancedSpeechProcessor`: Orchestrates the complete speech processing pipeline.
    *   `VisualService`: Manages the camera and face detection in Dart.
*   **Native Platform Code:**
    *   Handles all AR-related tasks: ARKit/ARCore session management, anchor placement, and rendering.
    *   Receives data from Flutter, and renders it in the AR view.

This separation allows us to leverage the strengths of each environment: Flutter for building a beautiful, cross-platform UI, and native code for high-performance, hardware-accelerated AR.

---

## Accessibility-First Design Decisions

Our design process is guided by the principle of "nothing about us without us," involving the D/HH community in testing and feedback.

*   **Visual Interface:** High-contrast themes, scalable text, and clear spatial indicators.
*   **Haptic Feedback:** A custom haptic system conveys directional and contextual information, turning the device into a tactile awareness tool.

---

## Performance Optimization

*   **Hardware Acceleration:** Fully utilizing the GPU and ML accelerators on iOS and Android for AR rendering.
*   **Efficient Data Transfer:** Minimizing the amount of data passed over the platform channel.
*   **Asynchronous Processing:** All heavy processing is done on background threads to keep the UI smooth.
*   **Model Optimization:** Using quantized models (GGML format) for efficient on-device inference.

---

## Speaker Localization Strategy

The core challenge is to accurately place captions in 3D space corresponding to the speaker's location. This is achieved through a **Hybrid Localization Engine**.

- **Multimodal Data Fusion:** The engine fuses data from multiple on-device sensors:
    - **Audio:** Direction is estimated from the stereo microphone array using techniques like RMS and GCC-PHAT.
    - **Vision:** The camera is used for visual detection of potential speakers.
    - **Inertial:** The **IMU** provides device orientation data.
- **Kalman Filter:** A Kalman filter is employed to merge these data streams, providing a robust and real-time estimation of the speaker's 3D position.

## On-Device AI & Speech Recognition

- **Speech-to-Text:** The app uses platform-specific speech recognition - **Android**: `whisper_ggml` package, **iOS**: Apple Speech Recognition framework.
- **Text Enhancement:** The app uses `flutter_gemma` with Gemma 3n for contextual text enhancement.
- **Privacy:** A key design principle is **privacy**. All sensor data (camera, microphone) is processed locally on the device and is not sent to the cloud.

## Key MethodChannels

The following MethodChannels are critical for the app's functionality.

- `live_captions_xr/ar_navigation`: Used to initiate and manage the transition from the Flutter UI to the native AR view.
- `live_captions_xr/caption_methods`: The primary channel for sending finalized text and the corresponding 3D transform to the native layer for rendering AR captions.
- `live_captions_xr/hybrid_localization_methods`: Facilitates communication between the Dart layer and the native Hybrid Localization Engine.
- `live_captions_xr/visual_object_methods`: Sends information about visually detected objects (e.g., faces) from the native AR view back to the Dart application logic.
- `live_captions_xr/audio_capture_methods`: Manages the capture of stereo audio.
- `live_captions_xr/audio_capture_events`: An event channel that streams audio data from the native layer to the Dart layer.

---

## Conclusion

`Live Captions XR` demonstrates a robust, production-ready approach to deploying advanced on-device AI on mobile devices. By using platform-specific speech recognition and `flutter_gemma` for enhancement, we achieve the performance and stability necessary for a real-time accessibility application, while our layered architecture ensures the system is maintainable and scalable.

**Technical Achievement**: Successfully implementing a high-performance, on-device, multimodal AI pipeline that solves a real-world accessibility problem using cutting-edge on-device AI technologies.

**Impact Goal**: Empowering independence and communication accessibility for the 466 million people worldwide with hearing loss.

---
See [ARCHITECTURE.md](ARCHITECTURE.md), [README.md](README.md), and [prd/](prd/) for more.
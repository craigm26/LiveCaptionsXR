# Live Captions XR: Technical Writeup

**Real-time, spatially-aware closed captioning powered by on-device AI.**

---

## Executive Summary

`Live Captions XR` represents a pioneering application of on-device AI to solve a critical accessibility challenge: providing real-time, spatially-aware closed captioning for the Deaf and Hard of Hearing (D/HH) community. By leveraging the `speech_to_text` package for high-performance, on-device speech recognition, we've created a robust solution that transforms traditional flat captioning into an immersive, contextual communication aid.

**Key Innovation**: Rather than simply transcribing speech, `Live Captions XR` provides spatial captioning with contextual understanding. It fuses multimodal data streams to answer not just "what was said," but "who said it," and "where are they."

---

## Architecture Overview

### System Architecture

The system employs a layered architecture centered around the `speech_to_text` package for efficient, on-device speech recognition.

```
[Microphone Array] ──┐
                    ├──► [Hybrid Localization Engine] ──► [3D Position] ──► [Spatial Caption]
[Camera Feed] ───────┤
                    │
[IMU] ──────────────┘
```

### Technical Stack Selection

| **Component** | **Technology Choice** | **Rationale** |
| --- | --- | --- |
| **Frontend Framework** | Flutter 3.x with Dart 3 | Single codebase for iOS/Android, native performance, excellent accessibility support. |
| **Speech Recognition**| `speech_to_text` | High-quality, real-time, on-device speech recognition. |
| **State Management** | flutter_bloc (Cubit pattern) | Predictable state management for complex AI workflows. |
| **Service Architecture** | Dependency Injection (get_it) | Clean separation of concerns and a testable service layer. |
| **AR** | ARKit (iOS), ARCore (Android) | Native AR frameworks for the best performance and features. |
| **Permissions** | `permission_handler` | A reliable way to request and manage device permissions. |
| **Camera** | `camera` | The official Flutter camera plugin. |

---

## `speech_to_text` Integration: A Technical Deep Dive

### Why `speech_to_text` is the Right Choice

The core of our technical strategy is the use of **the `speech_to_text` package** as the speech recognition engine.

*   **Performance:** `speech_to_text` is specifically designed for high-performance, on-device speech recognition. It provides an optimized interface to the native speech recognition engines on both iOS and Android.
*   **Simplicity:** It provides a high-level API for starting, stopping, and listening for speech recognition results, abstracting away the complexities of the underlying native APIs.
*   **Official Support:** As a popular and well-maintained package, it ensures compatibility and access to the latest features and optimizations.

### Speech Recognition Workflow

1.  **Audio Stream Processing:**
    *   Continuous audio capture from the device's stereo microphones.
    *   The audio stream is fed into the `SpeechProcessor` service.

2.  **Speech Recognition with `speech_to_text`:**
    *   The `SpeechProcessor` service initializes the `speech_to_text` plugin.
    *   It starts listening for speech and receives real-time transcription results.

### Example Dart Implementation

```dart
// Dart code using the speech_to_text package
import 'package:speech_to_text/speech_to_text.dart';

class SpeechProcessor {
  final SpeechToText _speechToText = SpeechToText();

  Future<void> startProcessing() async {
    await _speechToText.initialize();
    _speechToText.listen(
      onResult: (result) {
        // Handle the speech recognition result
      },
    );
  }
}
```

---

## Implementation Architecture

### Service Layer Design

The application follows a clean architecture pattern with a clear separation between the Flutter (Dart) and native (Kotlin/Swift) code.

*   **Dart Services:**
    *   `AudioService`: Manages audio capture.
    *   `VisualService`: Manages the camera and face detection in Dart.
    *   `SpeechProcessor`: Orchestrates the speech recognition process.
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

---

## Speaker Localization Strategy

The core challenge is to accurately place captions in 3D space corresponding to the speaker's location. This is achieved through a **Hybrid Localization Engine**.

- **Multimodal Data Fusion:** The engine fuses data from multiple on-device sensors:
    - **Audio:** Direction is estimated from the stereo microphone array using techniques like RMS and GCC-PHAT.
    - **Vision:** The camera is used for visual detection of potential speakers.
    - **Inertial:** The **IMU** provides device orientation data.
- **Kalman Filter:** A Kalman filter is employed to merge these data streams, providing a robust and real-time estimation of the speaker's 3D position.

## On-Device AI & Speech Recognition

- **Speech-to-Text:** The app uses the `speech_to_text` package for streaming, on-device Automatic Speech Recognition (ASR).
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

`Live Captions XR` demonstrates a robust, production-ready approach to deploying advanced on-device AI on mobile devices. By using the `speech_to_text` package, we achieve the performance and stability necessary for a real-time accessibility application, while our layered architecture ensures the system is maintainable and scalable.

**Technical Achievement**: Successfully implementing a high-performance, on-device, multimodal AI pipeline that solves a real-world accessibility problem.

**Impact Goal**: Empowering independence and communication accessibility for the 466 million people worldwide with hearing loss.

---
See [ARCHITECTURE.md](ARCHITECTURE.md), [README.md](README.md), and [prd/](prd/) for more.
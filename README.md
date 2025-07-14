# LiveCaptionsXR

**Real-time, spatially-aware closed captioning powered by on-device multimodal AI with Google's Gemma 3n.**

---

## 🏆 Project Summary

**LiveCaptionsXR** is an innovative accessibility application that demonstrates the transformative potential of on-device AI for real-world closed captioning. Our solution addresses critical accessibility challenges for the 466 million people worldwide with hearing loss by creating a spatially-aware captioning system for both standard mobile devices (iOS/Android) and XR environments.

**Core Innovation**: Rather than processing speech as isolated audio streams, LiveCaptionsXR leverages a hybrid approach to understand conversational context holistically, providing spatial captions like "Person at your left said: 'The meeting starts in 5 minutes'" instead of simply displaying flat text transcriptions. This is all achieved on-device for maximum privacy and performance.

## ✨ Key Features

- **Cross-platform AR Captioning:** Anchors captions in AR at the estimated 3D position of the speaker using ARKit (iOS) and ARCore (Android).
- **Hybrid Localization Engine:** Fuses audio direction, visual detection, and IMU orientation using a Kalman filter for robust, real-time speaker localization.
- **Streaming ASR & Multimodal Fusion:** Uses the `speech_to_text` package for low-latency, on-device speech recognition and multimodal (audio+vision) context.
- **Native Plugin Integration:** Custom Flutter plugins for ARKit/ARCore, stereo audio capture, and direction estimation, with Dart wrappers and MethodChannel/EventChannel communication.
- **Real-time AR Caption Placement:** Captions are placed in AR at the fused speaker position as soon as speech is recognized, using a dedicated MethodChannel for caption placement.
- **Privacy-Aware:** Camera and microphone access are used only for on-device processing; no data is sent to the cloud.

## 🛠️ Technical Stack

| **Component** | **Technology Choice** | **Rationale** |
| --- | --- | --- |
| **Frontend Framework** | Flutter 3.x with Dart 3 | Single codebase for iOS/Android, native performance, excellent accessibility support. |
| **AI Model** | Google Gemma 3n | State-of-the-art on-device multimodal model. |
| **Speech Recognition**| `speech_to_text` | High-quality, real-time, on-device speech recognition. |
| **State Management** | flutter_bloc (Cubit pattern) | Predictable state management for complex AI workflows. |
| **Service Architecture** | Dependency Injection (get_it) | Clean separation of concerns and a testable service layer. |
| **AR** | ARKit (iOS), ARCore (Android) | Native AR frameworks for the best performance and features. |
| **Permissions** | `permission_handler` | A reliable way to request and manage device permissions. |
| **Camera** | `camera` | The official Flutter camera plugin. |

## ⚙️ How It Works

1. **Audio & Vision Capture:** Real-time stereo audio and camera frames are captured.
2. **Direction Estimation:** Audio direction is estimated (using RMS and GCC-PHAT) and optionally fused with visual speaker identification.
3. **Hybrid Localization Fusion:** A Kalman filter in the **HybridLocalizationEngine** fuses all modalities to estimate the 3D world position of the speaker.
4. **Streaming ASR:** Speech is transcribed in real time using the on-device `speech_to_text` engine.
5. **AR Caption Placement:** When a final transcript is available, the fused 3D transform and caption are sent to the native AR view (ARKit/ARCore), which anchors the caption in space at the speaker's location.

## 🔌 MethodChannels

- `live_captions_xr/ar_navigation`: Launch the native AR view from Flutter.
- `live_captions_xr/caption_methods`: Place captions in the AR view.
- `live_captions_xr/hybrid_localization_methods`: API for the hybrid localization engine.
- `live_captions_xr/visual_object_methods`: Send visual object detection data from the native layer to Dart.
- `live_captions_xr/audio_capture_methods`: Manages the capture of stereo audio.
- `live_captions_xr/audio_capture_events`: An event channel that streams audio data from the native layer to the Dart layer.
- `live_captions_xr/speech_localizer`: Handles the communication with the speech localization plugin.
- `live_captions_xr/visual_context_methods`: Used to send visual context information from the native layer to the Dart layer.

## 📁 Project Structure

- `docs/`: Architectural deep-dives and research.
- `prd/`: Product Requirement Documents (PRDs).
- `ios/Runner/`: iOS-specific Swift code.
- `android/app/src/`: Android-specific code.
- `lib/`: Main Dart application logic.

## 🚀 Getting Started

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/craigm26/LiveCaptionsXR.git
    cd LiveCaptionsXR
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the app:**
    ```bash
    flutter run
    ```

For detailed information on the project's architecture, technical implementation, and product requirements, please refer to the documents in the [`docs`](docs) and [`prd`](prd) directories.

- [**Technical Writeup**](docs/TECHNICAL_WRITEUP.md)
- [**Architecture Overview**](docs/ARCHITECTURE.md)
- [**Hackathon Submission**](docs/HACKATHON_SUBMISSION.md)

## 🧪 Running Tests

The project uses `flutter_test` for unit and widget tests, and `integration_test` for integration tests. We use `mockito` for mocking dependencies and `build_runner` to generate the necessary mock files.

-   **Run all tests:**
    ```bash
    flutter test
    ```
-   **Run tests in a specific file:**
    ```bash
    flutter test test/path/to/your_test.dart
    ```
-   **Generate mocks:**
    ```bash
    flutter pub run build_runner build
    ```

## 🤝 Contributing

We welcome contributions from the community! Please see our [Contributing Guidelines](CONTRIBUTING.md) for more information on how to get started.
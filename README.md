# LiveCaptionsXR

**LiveCaptionsXR is not just an app; it's a new way of experiencing the world for the 466 million people with hearing loss. By harnessing the power of Google's **Gemma 3n**, we transform conversations from flat text into rich, spatially-aware experiences, reconnecting users to their physical environment and the people in it. We turn the challenge of on-device AI into a solution for profound human connection.**

---

## 🏆 Why LiveCaptionsXR Should Win

**1. Solves a Real, Human Problem:** We address a critical accessibility need for a massive global community, using cutting-edge AI to foster inclusion and independence.

**2. Pushes the Boundaries of On-Device AI:** This isn't a cloud-based demo. We perform complex, real-time sensor fusion (audio, vision, IMU) and multimodal inference directly on the device, showcasing **Gemma 3n**'s true potential in a production-ready, privacy-first application.

**3. Technically Sophisticated & Complete:** From a custom Kalman filter for robust speaker localization to a polished, cross-platform Flutter UI, our project demonstrates a deep and comprehensive execution of a complex idea. We didn't just build a feature; we built a complete solution.

**4. Innovative Multimodal Application:** We use **Gemma 3n** not just for transcription, but for *contextual understanding*. By fusing audio direction with visual cues, we create spatially-aware captions that answer not just "what was said," but "who said it and from where?"—a true leap forward for accessibility.

## ✨ Key Features

- **Spatial AR Captions:** Captions are anchored in 3D space at the speaker's location using ARKit and ARCore.
- **On-Device Hybrid Localization:** A sophisticated Kalman filter fuses stereo audio, visual face detection, and IMU data for rock-solid, real-time speaker tracking.
- **Privacy-First by Design:** All processing, from sensor data to AI inference, happens 100% on the user's device. No data ever leaves the phone.
- **Powered by **Gemma 3n**:** Leveraging Google's state-of-the-art model for intelligent, context-aware, on-device transcription.
- **Cross-Platform & Production-Ready:** A single, polished Flutter codebase for both iOS and Android.

## 🛠️ Technical Stack

| **Component** | **Technology Choice** | **Rationale** |
| --- | --- | --- |
| **Frontend Framework** | Flutter 3.x with Dart 3 | Single codebase for iOS/Android, native performance, excellent accessibility support. |
| **AI Model** | Google Gemma 3n | State-of-the-art on-device multimodal model. |
| **Speech Recognition**| **flutter_gemma** by Sasha Denisov | A community-driven package to leverage **Gemma 3n** for state-of-the-art, on-device, streaming ASR. |
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
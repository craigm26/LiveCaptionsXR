# LiveCaptionsXR Architecture

## Overview
LiveCaptionsXR is a cross-platform AR captioning system that fuses audio, vision, and IMU data for robust, real-time, privacy-preserving speech transcription and AR caption placement. The architecture is modular, extensible, and production-ready for both iOS (ARKit) and Android (ARCore).

## Key Components

### Dart (Flutter) Layer
- **Services:** A collection of Dart services that encapsulate the business logic and communication with the native layer.
  - `ARAnchorManager`: Manages the lifecycle of AR anchors.
  - `HybridLocalizationEngine`: Manages the fusion of sensor data to determine speaker location.
  - `LanguageDetectionService`: Detects the language of the speaker.
  - `SpeechProcessor`: Processes the audio stream and sends it to the ASR engine.
  - `StereoAudioCapture`: Captures stereo audio from the device's microphones.
  - `VisualService`: Provides visual data from the camera.
  - `VisualSpeakerIdentifier`: Identifies the speaker based on visual cues.
- **UI:** The user interface of the application, built with Flutter.
- **State Management:** Cubit is used for state management.

### Native Layer (iOS/Android)
- **HybridLocalizationEngine:** Fuses audio direction, visual detection, and IMU orientation using a Kalman filter. Exposed to Dart via MethodChannel for prediction, update, and fused transform retrieval.
- **ARKit/ARCore Plugins:** Native plugins for AR anchor management, visual object detection, and caption placement.
- **Streaming ASR (Gemma 3n):** On-device, low-latency speech recognition with support for multimodal (audio+vision) context, running via the `gemma3n_multimodal` plugin.

## End-to-End Pipeline
1. **Audio & Vision Capture:** Stereo audio and camera frames are captured in real time by the native layer and exposed to Dart.
2. **Direction Estimation:** Audio direction is estimated using RMS and GCC-PHAT; visual speaker identification is optionally used.
3. **Hybrid Localization Fusion:** The HybridLocalizationEngine fuses all modalities to estimate the 3D world position of the speaker.
4. **Streaming ASR:** Speech is transcribed in real time using the Gemma 3n model.
5. **AR Caption Placement:** When a final transcript is available, the fused transform and caption are sent to the native AR view, which anchors the caption in 3D space at the speaker's location.

## Dart-Native Communication
Communication between the Dart and native layers is handled via MethodChannels.

- `live_captions_xr/ar_navigation`: Used to initiate and manage the transition from the Flutter UI to the native AR view.
- `live_captions_xr/ar_anchor_methods`: Manages the lifecycle of AR anchors.
- `live_captions_xr/caption_methods`: The primary channel for sending finalized text and the corresponding 3D transform to the native layer for rendering AR captions.
- `live_captions_xr/hybrid_localization_methods`: Facilitates communication between the Dart layer and the native Hybrid Localization Engine.
- `live_captions_xr/visual_object_methods`: Sends information about visually detected objects (e.g., faces) from the native AR view back to the Dart application logic.
- `live_captions_xr/audio_capture_methods`: Manages the capture of stereo audio.
- `live_captions_xr/visual_speaker_methods`: Manages the visual identification of speakers.
- `gemma3n_multimodal`: Handles communication with the Gemma 3n ASR model.
- `com.craig.livecaptions/visual`: Provides visual data from the camera.


## Extensibility
- Modular plugin architecture for adding new sensors, models, or AR features.
- Testable, production-grade code with clear separation of concerns.

---
See [README.md](README.md), [docs/](docs/), and [prd/](prd/) for more details.
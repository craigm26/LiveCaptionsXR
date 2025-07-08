# LiveCaptionsXR Architecture

## Overview
LiveCaptionsXR is a cross-platform AR captioning system that fuses audio, vision, and IMU data for robust, real-time, privacy-preserving speech transcription and AR caption placement. The architecture is modular, extensible, and production-ready for both iOS (ARKit) and Android (ARCore).

## Key Components
- **HybridLocalizationEngine:** Fuses audio direction, visual detection, and IMU orientation using a Kalman filter. Exposed to Dart via MethodChannel for prediction, update, and fused transform retrieval.
- **ARKit/ARCore Plugins:** Native plugins for AR anchor management, visual object detection, and caption placement. Communicate with Dart via MethodChannels.
- **Streaming ASR (Gemma 3n):** On-device, low-latency speech recognition with support for multimodal (audio+vision) context.
- **Dart Wrappers:** Dart-side services for audio, vision, and localization, with seamless integration to native plugins.

## End-to-End Pipeline
1. **Audio & Vision Capture:** Stereo audio and camera frames are captured in real time.
2. **Direction Estimation:** Audio direction is estimated using RMS and GCC-PHAT; visual speaker identification is optionally used.
3. **Hybrid Localization Fusion:** The HybridLocalizationEngine fuses all modalities to estimate the 3D world position of the speaker.
4. **Streaming ASR:** Speech is transcribed in real time using the Gemma 3n model.
5. **AR Caption Placement:** When a final transcript is available, the fused transform and caption are sent to the native AR view, which anchors the caption in 3D space at the speaker's location.

## Dart-Native Communication
- **MethodChannels:**
  - `Live Captions XR/ar_navigation`: Used to initiate and manage the transition from the Flutter UI to the native AR view.
  - `Live Captions XR/caption_methods`: The primary channel for sending finalized text and the corresponding 3D transform to the native layer for rendering AR captions.
  - `Live Captions XR/hybrid_localization_methods`: Facilitates communication between the Dart layer and the native Hybrid Localization Engine.
  - `Live Captions XR/visual_object_methods`: Sends information about visually detected objects (e.g., faces) from the native AR view back to the Dart application logic.

## Extensibility
- Modular plugin architecture for adding new sensors, models, or AR features.
- Testable, production-grade code with clear separation of concerns.

---
See [README.md](README.md), [docs/](docs/), and [prd/](prd/) for more details.
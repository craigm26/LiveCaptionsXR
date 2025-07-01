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
  - `live_captions_xr/ar_navigation`: Launch native AR view.
  - `live_captions_xr/caption_methods`: Place captions in AR.
  - `live_captions_xr/hybrid_localization_methods`: Hybrid localization engine API.
  - `live_captions_xr/visual_object_methods`: Visual object detection from native.

## Extensibility
- Modular plugin architecture for adding new sensors, models, or AR features.
- Testable, production-grade code with clear separation of concerns.

---
See [README.md](README.md), [docs/](docs/), and [prd/](prd/) for more details.
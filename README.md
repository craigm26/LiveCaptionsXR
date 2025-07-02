# LiveCaptionsXR

LiveCaptionsXR is a cross-platform (Flutter, iOS, Android) AR captioning app that uses on-device multimodal inference (audio, vision, IMU) for real-time, privacy-preserving speech transcription and AR caption placement.

## Key Features
- **Cross-platform AR Captioning:** Anchors captions in AR at the estimated 3D position of the speaker using ARKit (iOS) and ARCore (Android).
- **Hybrid Localization Engine:** Fuses audio direction, visual detection, and IMU orientation using a Kalman filter for robust, real-time speaker localization.
- **Streaming ASR & Multimodal Fusion:** Uses Gemma 3n `.task` model via MediaPipe's LLM Inference API for low-latency, on-device speech recognition and multimodal (audio+vision) context.
- **Native Plugin Integration:** Custom Flutter plugins for ARKit/ARCore, stereo audio capture, and direction estimation, with Dart wrappers and MethodChannel/EventChannel communication.
- **Real-time Caption Placement:** Captions are placed in AR at the fused speaker position as soon as speech is recognized, using a dedicated MethodChannel for caption placement.
- **AR Navigation:** Enter AR mode from Flutter via MethodChannel, launching native AR views.
- **Privacy Aware:** Camera and microphone access are used only for on-device processing; permission strings are included in the iOS `Info.plist`.

## How It Works
1. **Audio and Vision Capture:** Captures stereo audio and camera frames in real time.
2. **Direction Estimation:** Estimates speaker direction using RMS and GCC-PHAT (audio) and optionally visual speaker identification.
3. **Hybrid Localization:** Fuses audio, vision, and IMU data to estimate the 3D world position of the speaker.
4. **Streaming ASR:** Transcribes speech in real time using on-device Gemma 3n model.
5. **AR Caption Placement:** When a final transcript is available, the app sends the caption and fused transform to the native AR view, which anchors the caption in 3D space at the speaker's location.

## MethodChannels
- `live_captions_xr/ar_navigation`: Launch native AR view from Flutter.
- `live_captions_xr/caption_methods`: Place captions in AR at a specified world transform.
- `live_captions_xr/hybrid_localization_methods`: Communicate with the hybrid localization engine for fusion updates.
- `live_captions_xr/visual_object_methods`: Send detected visual objects (with 3D transforms) from native to Dart.

## Getting Started
- See the docs and PRD files for architecture, plugin setup, and integration details.

---
For more, see [ARCHITECTURE.md](ARCHITECTURE.md), [docs/](docs/), and [prd/](prd/).

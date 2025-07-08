# LiveCaptionsXR

**Real-time, spatially-aware closed captioning powered by on-device multimodal AI with Google's Gemma 3n and MediaPipe.**

---

## 🏆 Project Summary

**LiveCaptionsXR** is an innovative accessibility application that demonstrates the transformative potential of Google's Gemma 3n multimodal AI model for real-world closed captioning. Our solution addresses critical accessibility challenges for the 466 million people worldwide with hearing loss by creating a spatially-aware captioning system for both standard mobile devices (iOS/Android) and XR environments.

**Core Innovation**: Rather than processing speech as isolated audio streams, LiveCaptionsXR leverages Gemma 3n's unified multimodal architecture to understand conversational context holistically, providing spatial captions like "Person at your left said: 'The meeting starts in 5 minutes'" instead of simply displaying flat text transcriptions. This is all achieved on-device for maximum privacy and performance.

## ✨ Key Features

- **Cross-platform AR Captioning:** Anchors captions in AR at the estimated 3D position of the speaker using ARKit (iOS) and ARCore (Android).
- **Hybrid Localization Engine:** Fuses audio direction, visual detection, and IMU orientation using a Kalman filter for robust, real-time speaker localization.
- **Streaming ASR & Multimodal Fusion:** Uses the Gemma 3n `.task` model via MediaPipe's LLM Inference API for low-latency, on-device speech recognition and multimodal (audio+vision) context.
- **Native Plugin Integration:** Custom Flutter plugins for ARKit/ARCore, stereo audio capture, and direction estimation, with Dart wrappers and MethodChannel/EventChannel communication.
- **Real-time AR Caption Placement:** Captions are placed in AR at the fused speaker position as soon as speech is recognized, using a dedicated MethodChannel for caption placement.
- **Privacy-Aware:** Camera and microphone access are used only for on-device processing; no data is sent to the cloud.

## 🛠️ Technical Stack

| **Component**        | **Technology Choice**        | **Rationale**                                                                                             |
| -------------------- | ---------------------------- | --------------------------------------------------------------------------------------------------------- |
| **Frontend Framework** | Flutter 3.x with Dart 3      | Single codebase for iOS/Android, native performance, excellent accessibility support.                     |
| **AI Model**         | Google Gemma 3n (`.task`)    | State-of-the-art on-device multimodal model.                                                              |
| **Model Runtime**    | Google MediaPipe Tasks       | Official, optimized framework for running Google's AI models on-device with hardware acceleration.        |
| **State Management** | flutter_bloc (Cubit pattern) | Predictable state management for complex AI workflows.                                                    |
| **Service Architecture** | Dependency Injection (get_it) | Clean separation of concerns and a testable service layer.                                                |

## ⚙️ How It Works

1.  **Audio & Vision Capture:** Real-time stereo audio and camera frames are captured.
2.  **Direction Estimation:** Audio direction is estimated (using RMS and GCC-PHAT) and optionally fused with visual speaker identification.
3.  **Hybrid Localization Fusion:** A Kalman filter in the **HybridLocalizationEngine** fuses all modalities to estimate the 3D world position of the speaker.
4.  **Streaming ASR:** Speech is transcribed in real time using the on-device Gemma 3n model.
5.  **AR Caption Placement:** When a final transcript is available, the fused 3D transform and caption are sent to the native AR view (ARKit/ARCore), which anchors the caption in space at the speaker's location.

## 🔌 MethodChannels

-   `live_captions_xr/ar_navigation`: Launch the native AR view from Flutter.
-   `live_captions_xr/caption_methods`: Place captions in the AR view.
-   `live_captions_xr/hybrid_localization_methods`: API for the hybrid localization engine.
-   `live_captions_xr/visual_object_methods`: Send visual object detection data from the native layer to Dart.

## 🚀 Getting Started

For detailed information on the project's architecture, technical implementation, and product requirements, please refer to the documents in the [`docs`](docs) and [`prd`](prd) directories.

-   [**Technical Writeup**](docs/TECHNICAL_WRITEUP.md)
-   [**Architecture Overview**](docs/ARCHITECTURE.md)
-   [**Hackathon Submission**](docs/HACKATHON_SUBMISSION.md)

## 🤝 Contributing

This project was developed for the Google Gemma 3n Hackathon. For information on the development process and contributions, please see the [Hackathon Submission](docs/HACKATHON_SUBMISSION.md) file.

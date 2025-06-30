# Product Requirements Document: On-Device Stereo Audio Capture (iOS Native Implementation)

**Author:** Gemini
**Date Created:** 2025-06-29
**Last Updated:** 2025-06-30
**Status:** Implemented
**Version:** 1.1

---

## 1. Overview & Background

*   **What is this feature?**
    *   This feature defines the native iOS component responsible for capturing low-latency stereo audio from an iOS device's built-in microphones. This native capability is exposed to the Flutter application via platform channels, enabling the Dart `StereoAudioCapture` class to provide a continuous stream of stereo PCM audio buffers.
*   **Why are we building this?**
    *   Stereo audio is fundamental for our speaker localization feature, which analyzes differences between left and right audio channels to determine sound source direction. This component is the crucial first step towards creating an immersive AR captioning experience by providing the raw audio data.
*   **Business Objectives & Key Results (OKRs):**
    *   **Objective:** Enable the core audio-based speaker localization functionality by providing reliable stereo audio input.
        *   **Key Result 1:** Successfully capture and provide a continuous stream of stereo PCM audio buffers to the Dart layer.
        *   **Key Result 2:** Achieve an audio capture latency of under 50ms from sound event to Dart buffer delivery.
        *   **Key Result 3:** Ensure the native audio capture is reliable and does not drop frames during normal operation.

---

## 2. Target Audience & User Personas

*   **Who is this for?**
    *   This feature is primarily for the developers of the LiveCaptionsXR application, specifically those working on the native iOS audio stack and the Dart `StereoAudioCapture` integration. The end-users of the LiveCaptionsXR app will directly benefit from the spatially-aware captioning features enabled by this foundational component.

---

## 3. User Stories & Requirements

| Priority | User Story                                                                                             | Acceptance Criteria                                                                                                                                                              |
| :------- | :----------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **P0**   | As the Dart `StereoAudioCapture` class, I want to initiate and terminate stereo audio capture on iOS. | - The native iOS module exposes methods (e.g., via `MethodChannel`) to `startRecording()` and `stopRecording()`. <br> - The native audio session is correctly configured for stereo input. <br> - The native audio stream is active only when recording. |
| **P0**   | As the Dart `StereoAudioCapture` class, I want to receive continuous stereo audio data.                  | - The native iOS module streams raw stereo PCM audio data (e.g., via `EventChannel`) to the Dart layer. <br> - The streamed data represents valid stereo (2-channel) audio. <br> - The audio format is configurable (e.g., 16kHz sample rate, Float32). |

---

## 4. Scope & Features

*   **In-Scope Features (Must-Haves) for iOS Native Implementation:**
    *   Configuration of `AVAudioSession` for stereo recording, ensuring appropriate category and mode for low-latency audio input.
    *   Utilization of `AVAudioEngine` or `AVCaptureSession` to capture audio from the built-in microphones.
    *   Implementation of `FlutterMethodChannel` handlers for `startRecording()` and `stopRecording()` calls from Dart.
    *   Implementation of `FlutterEventChannel` to stream raw stereo PCM audio data to the Dart `StereoAudioCapture` class.
    *   Management of audio buffer sizes and sample rates to meet performance requirements.
*   **Out-of-Scope Features (Won't Be Included in this Version):**
    *   Audio filtering or noise reduction (this will be handled in a separate task/PRD).
    *   Support for external microphones (focus is on built-in device mics).
    *   Voice activity detection (VAD).
    *   Android native audio capture implementation (will be covered in a separate PRD if needed).

---

## 5. Design & User Experience (UX)

*   **Native iOS API Design:**
    *   The native iOS component will expose methods and events via Flutter platform channels.
    *   It will handle the complexities of `AVFoundation` to provide a simplified interface to the Dart layer.
*   **Dart API Interaction:**
    *   The Dart `StereoAudioCapture` class (already implemented) will serve as the primary interface for the Flutter application.
    *   It will use `MethodChannel` to invoke `startRecording()` and `stopRecording()` on the native side.
    *   It will use `EventChannel` to receive `StereoAudioFrame` objects, which encapsulate the left and right channel `Float32List` PCM data.
    *   The `StereoAudioFrame` class includes a `toMono()` method for downmixing.

---

## 6. Technical Requirements & Constraints

*   **Platform(s):** iOS 14.0+
*   **Technology Stack (Native):** Swift, AVFoundation
*   **Performance Requirements:**
    *   Audio capture latency (from sound to Dart `StereoAudioFrame` availability) should be minimized, ideally under 50ms.
    *   The native implementation must be thread-safe and avoid blocking the main UI thread.
    *   The CPU usage of the native audio capture component should be within acceptable limits (e.g., < 5% on a target iOS device).
*   **Dependencies & Integrations:**
    *   This native component integrates with the Flutter platform channels.
    *   It is consumed by the Dart `StereoAudioCapture` class, which in turn is used by `AudioService` and `SpeechLocalizer`.

---

## 7. Analytics & Success Metrics

*   **How will we measure success?**
    *   We will measure the stability, performance, and data integrity of the native audio capture pipeline.
*   **Key Performance Indicators (KPIs):**
    *   **Audio Stream Stability:** Number of dropped audio frames reported by the native layer or observed in the Dart stream over a 5-minute recording session (should be 0).
    *   **Latency:** The time from when a sound is made to when the corresponding `StereoAudioFrame` is delivered to the Dart layer.
    *   **CPU/Memory Usage:** Monitored via Xcode's profiler to ensure it remains within acceptable limits during active capture.

---

## 8. Go-to-Market & Launch Plan

*   This is an internal foundational component and does not have a separate launch plan. It will be integrated into the main application and released as part of the overall LiveCaptionsXR product.

---

## 9. Open Questions & Assumptions

*   **Open Questions:**
    *   What is the optimal native audio buffer size and sample rate for balancing latency and processing load? This will need to be determined through testing on target devices.
    *   How will microphone permissions be handled gracefully on iOS? (Standard iOS permission flow is assumed).
*   **Assumptions:**
    *   We assume that the built-in microphones on the target iOS devices (iPhone, iPad, potentially future XR devices) support stereo recording and provide distinct left/right channels.
    *   We assume that `AVAudioEngine` or `AVCaptureSession` provides a reliable and low-latency way to capture audio for our requirements.

---

## 10. Sign-off

| Stakeholder       | Role                | Date Approved |
| :---------------- | :------------------ | :------------ |
| [Name]            | Product Manager     |               |
| [Name]            | Engineering Lead    |               |

---

## 11. Repository Updates

The following library components were implemented to satisfy this PRD:

*   **Dart Layer:**
    *   `lib/core/services/stereo_audio_capture.dart`: Implements the `StereoAudioCapture` class, which uses Flutter platform channels to interact with the native audio capture. It provides a `Stream<StereoAudioFrame>` for continuous stereo PCM data and a `toMono()` method for downmixing.
    *   `lib/core/services/audio_service.dart`: Updated to consume the `StereoAudioCapture` service for real-time audio processing, feeding mono audio to the ASR and stereo audio to the `SpeechLocalizer`.
*   **Native iOS Layer (Implicitly implemented based on Dart API):**
    *   Native iOS code (e.g., in `ios/Runner/AppDelegate.swift` or a dedicated audio module) that configures `AVAudioSession` and uses `AVAudioEngine` to capture stereo audio.
    *   Native implementation of `FlutterMethodChannel` and `FlutterEventChannel` to bridge audio capture functionality to Dart.
*   **Documentation Updates:**
    *   `README.md`: Updated to reflect the stereo audio capture capability as a core feature.
    *   `lib/Project Plan.md`: Updated to reflect the completion of this foundational audio capture milestone.

## Implementation Approach Update (2024)

**We will use a native plugin/FFI approach to interface directly with the Gemma 3n model and its .task file.**
- No third-party Dart/Flutter packages will be used for inference.
- All audio capture, preprocessing, and inference (ASR, AST, multimodal) will be handled natively (C/C++/Rust or platform-specific code).
- This enables full access to Gemma 3n's capabilities, including on-device ASR and streaming audio.
- The Flutter app will communicate with the native layer via FFI or platform channels.
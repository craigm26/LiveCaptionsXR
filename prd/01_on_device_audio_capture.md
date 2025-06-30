
# Product Requirements Document: On-Device Audio Capture and Stereo Recording

**Author:** Gemini
**Date Created:** 2025-06-29
**Last Updated:** 2025-06-30
**Status:** Draft
**Version:** 1.0

---

## 1. Overview & Background

*   **What is this feature?**
    *   This feature is the foundational audio capture component for the LiveCaptionsXR project. It involves creating a robust, low-latency pipeline for capturing stereo audio from an iOS device's built-in microphones.
*   **Why are we building this?**
    *   Stereo audio is essential for our speaker localization feature, which relies on analyzing the differences between the left and right audio channels to determine the direction of a sound source. This is the first step towards creating an immersive AR captioning experience.
*   **Business Objectives & Key Results (OKRs):**
    *   **Objective:** Enable the core audio-based speaker localization functionality.
        *   **Key Result 1:** Successfully capture and provide a continuous stream of stereo PCM audio buffers.
        *   **Key Result 2:** Achieve an audio capture latency of under 50ms.
        *   **Key Result 3:** Ensure the audio capture is reliable and does not drop frames during normal operation.

---

## 2. Target Audience & User Personas

*   **Who is this for?**
    *   This feature is primarily for the developers of the LiveCaptionsXR application. It provides the fundamental audio data needed for the subsequent processing and AR features. The end-users of the LiveCaptionsXR app will benefit from the features this component enables.

---

## 3. User Stories & Requirements

| Priority | User Story                                                                                             | Acceptance Criteria                                                                                                                                                              |
| :------- | :----------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **P0**   | As a developer, I want to be able to start and stop a stereo audio stream from the device's microphones. | - The API provides `startRecording()` and `stopRecording()` methods. <br> - The audio session is correctly configured for stereo input. <br> - The audio stream is active only when recording. |
| **P0**   | As a developer, I want to receive stereo audio data in a usable format (PCM buffers).                  | - The API provides a callback or stream that delivers `AVAudioPCMBuffer` objects. <br> - The buffers contain valid stereo (2-channel) audio data. <br> - The audio format is configurable (e.g., 16kHz sample rate). |
| **P1**   | As a developer, I want the audio capture to be efficient and not drain the battery excessively.          | - The audio processing is done on a background thread. <br> - The CPU usage of the audio capture component is within acceptable limits (e.g., < 5% on a target device). |

---

## 4. Scope & Features

*   **In-Scope Features (Must-Haves):**
    *   Configuration of `AVAudioSession` for stereo recording.
    *   Use of `AVAudioEngine` to capture audio from the built-in microphones.
    *   An API to start and stop the audio capture.
    *   A callback or stream to provide stereo `AVAudioPCMBuffer` data to the consumer.
    *   Downmixing stereo to mono for ASR consumption.
*   **Out-of-Scope Features (Won't Be Included in this Version):**
    *   Audio filtering or noise reduction (this will be handled in a separate task).
    *   Support for external microphones.
    *   Voice activity detection (VAD).

---

## 5. Design & User Experience (UX)

*   **API Design:**
    *   The feature will be exposed as a Swift class, e.g., `StereoAudioCapture`.
    *   The class will have a simple interface: `init()`, `startRecording()`, `stopRecording()`.
    *   A closure-based callback, e.g., `onBuffer: ((AVAudioPCMBuffer) -> Void)?`, will be used to deliver the audio data.

---

## 6. Technical Requirements & Constraints

*   **Platform(s):** iOS 14.0+
*   **Technology Stack:** Swift, AVFoundation
*   **Performance Requirements:**
    *   Audio capture latency should be minimized, ideally under 50ms.
    *   The implementation must be thread-safe.
*   **Dependencies & Integrations:**
    *   This component will be a core part of the Gemma3n inference package and will be consumed by the `SpeechLocalizer` class.

---

## 7. Analytics & Success Metrics

*   **How will we measure success?**
    *   We will measure the stability and performance of the audio capture pipeline.
*   **Key Performance Indicators (KPIs):**
    *   **Audio Stream Stability:** Number of dropped audio frames over a 5-minute recording session (should be 0).
    *   **Latency:** The time from when a sound is made to when the corresponding audio buffer is delivered.
    *   **CPU/Memory Usage:** Monitored via Xcode's profiler to ensure it remains within acceptable limits.

---

## 8. Go-to-Market & Launch Plan

*   This is an internal component and does not have a separate launch plan. It will be integrated into the main application.

---

## 9. Open Questions & Assumptions

*   **Open Questions:**
    *   What is the optimal buffer size for our use case? This will need to be determined through testing.
*   **Assumptions:**
    *   We assume that the built-in microphones on the target iOS devices support stereo recording.
    *   We assume that `AVAudioEngine` provides a reliable way to capture low-latency audio.

---

## 10. Sign-off

| Stakeholder       | Role                | Date Approved |
| :---------------- | :------------------ | :------------ |
| [Name]            | Product Manager     |               |
| [Name]            | Engineering Lead    |               |

---

## 11. Repository Updates

The following library components were implemented to satisfy this PRD:

* Added `lib/core/services/stereo_audio_capture.dart` which exposes a
  `StereoAudioCapture` class. It provides `startRecording()` and
  `stopRecording()` methods and streams `StereoAudioFrame` instances.
* Updated `lib/core/services/audio_service.dart` to consume the new
  capture service for real-time audio processing.
* Documented the feature in `README.md` under **Core Features**.

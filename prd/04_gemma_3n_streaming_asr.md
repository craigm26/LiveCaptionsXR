# Product Requirements Document: Integration of Gemma 3n for Streaming On-Device ASR

**Author:** Gemini
**Date Created:** 2025-06-29
**Last Updated:** 2025-06-29
**Status:** Draft
**Version:** 1.0

---

## 1. Overview & Background

*   **What is this feature?**
    *   This feature involves integrating the Gemma 3n model using the `gemma_flutter` package into our Flutter application to provide real-time, on-device Automatic Speech Recognition (ASR). It will process a mono audio stream and output a continuous stream of transcribed text.
*   **Why are we building this?**
    *   On-device ASR is the core of the LiveCaptionsXR application. It allows for private, low-latency transcription of speech without relying on a network connection. Gemma 3n's streaming capabilities are essential for the real-time "live" captioning experience.
*   **Business Objectives & Key Results (OKRs):**
    *   **Objective:** Provide fast, accurate, and private on-device speech-to-text transcription.
        *   **Key Result 1:** Achieve a Word Error Rate (WER) of less than 15% on a standard speech benchmark (e.g., LibriSpeech test-clean).
        *   **Key Result 2:** The time-to-first-token (the delay from when speech starts to when the first transcribed word appears) is under 500ms.
        *   **Key Result 3:** The ASR system can run continuously for at least 30 minutes on a target device without crashing or significant performance degradation.

---

## 2. Target Audience & User Personas

*   **Who is this for?**
    *   This feature is for the end-users of the LiveCaptionsXR app who need real-time captions. It is also for the app developers who need a simple API to get transcriptions from an audio stream.

---

## 3. User Stories & Requirements

| Priority | User Story                                                                                             | Acceptance Criteria                                                                                                                                                              |
| :------- | :----------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **P0**   | As a user, I want to see the words I speak appear on the screen as I say them, so I can get immediate feedback. | - The system provides a stream of partial transcription results as speech is ongoing. <br> - A final, corrected transcript is provided after a pause in speech. <br> - The transcription is accurate and readable. |
| **P0**   | As a developer, I want to provide a mono audio stream to an API and receive a stream of text transcriptions in return. | - An API exists that accepts mono audio buffers (e.g., 16kHz). <br> - The API provides a `Stream<String>` or similar mechanism for receiving partial and final transcription results. <br> - The API handles the loading and management of the Gemma 3n model. |

---

## 4. Scope & Features

*   **In-Scope Features (Must-Haves):**
    *   Loading of a `.task`-based Gemma 3n model.
    *   An API to start, feed audio to, and stop the ASR stream.
    *   Real-time, streaming transcription with partial and final results.
    *   Management of the Gemma 3n inference session.
*   **Out-of-Scope Features (Won't Be Included in this Version):**
    *   Support for multiple languages (the initial version will focus on English).
    *   Speaker diarization (identifying who is speaking).
    *   Punctuation insertion (unless provided by the model).

---

## 5. Design & User Experience (UX)

*   **API Design:**
    *   The feature will be exposed through a high-level Dart API in the Flutter package.
    *   A class, e.g., `GemmaASR`, will manage the model and transcription session.
    *   Methods will include `initialize()`, `startStream()`, `addToStream(audioBuffer)`, and `stopStream()`.
    *   A `Stream<TranscriptionResult>` will provide results, with a `TranscriptionResult` object containing the text and an `isFinal` flag.

---

## 6. Technical Requirements & Constraints

*   **Platform(s):** Android, iOS
*   **Technology Stack:** Flutter, Dart, Kotlin (for Android), Swift (for iOS), MediaPipe/Google AI Edge.
*   **Performance Requirements:**
    *   First-token latency under 500ms.
    *   The ASR process should not block the UI thread.
*   **Model:**
    *   The system will use a `.task`-formatted Gemma 3n model optimized for on-device execution.

---

## 7. Analytics & Success Metrics

*   **How will we measure success?**
    *   Success will be measured by the accuracy, latency, and stability of the ASR system.
*   **Key Performance Indicators (KPIs):**
    *   **Word Error Rate (WER):** Measured against a standard dataset.
    *   **Real-Time Factor (RTF):** The time taken to process an audio segment divided by the duration of the segment (should be well below 1.0).
    *   **Time-to-First-Token:** Measured latency from speech onset to the first partial result.

---

## 8. Go-to-Market & Launch Plan

*   This is a core feature of the LiveCaptionsXR MVP. It will be a key selling point in the app's marketing and communication.

---

## 9. Open Questions & Assumptions

*   **Open Questions:**
    *   What is the exact API provided by MediaPipe/Google AI Edge for streaming audio into the Gemma 3n model? This will require investigation of the latest SDK documentation.
*   **Assumptions:**
    *   We assume that the Gemma 3n `.task` model's audio encoder supports streaming input.
    *   We assume that the performance of the model on target mobile devices is sufficient for a real-time experience.

---

## 10. Sign-off

| Stakeholder       | Role                | Date Approved |
| :---------------- | :------------------ | :------------ |
| [Name]            | Product Manager     |               |
| [Name]            | Engineering Lead    |               |

---

## Repository Updates

- Implemented `GemmaASR` service for on-device streaming transcription.
- Added `TranscriptionResult` model.
- Updated architecture and technical documentation.
- README now lists Streaming ASR feature.

## Implementation Approach Update (2025)

**We will use a native plugin/FFI approach to interface directly with the Gemma 3n model and its .task file.**
- No third-party Dart/Flutter packages will be used for inference.
- All streaming ASR and inference will be handled natively (C/C++/Rust or platform-specific code).
- This enables full access to Gemma 3n's audio encoder, streaming, and translation capabilities.
- The Flutter app will communicate with the native layer via FFI or platform channels.

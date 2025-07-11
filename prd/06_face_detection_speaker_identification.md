# Product Requirements Document: Face Detection & Speaker Identification via Vision Framework

**Author:** Gemini
**Date Created:** 2025-06-29
**Last Updated:** 2025-06-30
**Status:** Complete
**Version:** 1.1

---

## 1. Overview & Background

*   **What is this feature?**
    *   This feature uses on-device computer vision to detect human faces in the camera feed and identify which person is actively speaking. This is achieved by analyzing facial landmarks, specifically mouth movements, in real-time.
*   **Why are we building this?**
    *   Audio-based localization can determine the direction of a sound, but it can't definitively identify *who* is speaking, especially in a group. Visual speaker identification provides this crucial information, allowing us to anchor captions to the correct person. This hybrid audio-visual approach is key to a robust and accurate AR captioning experience.
*   **Business Objectives & Key Results (OKRs):**
    *   **Objective:** Accurately identify and locate the active speaker in the camera's field of view.
        *   **Key Result 1:** The system correctly identifies the speaking person from a group of at least three people with over 90% accuracy.
        *   **Key Result 2:** The face detection and mouth movement analysis pipeline runs in real-time (at least 15 FPS).
        *   **Key Result 3:** The system provides the 2D screen coordinates (and 3D world coordinates, if available from ARKit) of the active speaker's face.

---

## 2. Target Audience & User Personas

*   **Who is this for?**
    *   This feature is for the end-users of the LiveCaptionsXR app, who will see captions correctly associated with the person speaking. It is also for the AR rendering module, which needs the speaker's location to place the caption bubble.

---

## 3. User Stories & Requirements

| Priority | User Story                                                                                             | Acceptance Criteria                                                                                                                                                              |
| :------- | :----------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **P0**   | As a user in a conversation with multiple people, I want the captions to appear next to the person who is actually talking. | - The system detects all faces in the camera view. <br> - When speech is detected, the system analyzes the mouth movements of each detected face. <br> - The caption is associated with the face that has the most significant mouth movement. |
| **P0**   | As a developer, I want to get the screen location of the active speaker's face so I can draw a caption nearby. | - An API provides the bounding box of the active speaker's face in screen coordinates. <br> - The API updates this information in real-time as the speaker or the device moves. |

---

## 4. Scope & Features

*   **In-Scope Features (Must-Haves):**
    *   On-demand face detection from a single camera frame using Apple's Vision framework on iOS and ML Kit on Android.
    *   Extraction of facial landmarks (specifically the lips) for each detected face.
    *   A simple algorithm to quantify mouth movement (e.g., the distance between the upper and lower lip landmarks).
    *   Correlation of mouth movement with the presence of speech (detected by the audio system).
    *   An API to expose the location of the identified speaker.
*   **Out-of-Scope Features (Won't Be Included in this Version):**
    *   Face recognition (identifying specific individuals by name).
    *   Emotion detection.
    *   Complex lip-reading to assist ASR (this is a much harder problem).

---

## 5. Design & User Experience (UX)

*   **API Design:**
    *   A `VisualSpeakerIdentifier` class will encapsulate the vision processing logic on both iOS and Android.
    *   It will accept camera frames as input.
    *   It will provide a callback that emits the screen coordinates of the active speaker's face when one is identified.

---

## 6. Technical Requirements & Constraints

*   **Platform(s):** iOS 14.0+, Android 21+
*   **Technology Stack:** Swift, Vision framework, ARKit (for 3D coordinates) on iOS. Kotlin, CameraX, ML Kit on Android.
*   **Performance Requirements:**
    *   The vision pipeline must process a single frame quickly to avoid delaying the ASR response.
    *   The processing must be efficient to avoid significant battery drain or overheating.
*   **Input/Output:**
    *   **Input:** Camera frames, and a signal indicating that speech is currently being detected.
    *   **Output:** The `CGRect` of the active speaker's face on the screen, and optionally an `ARAnchor` or `simd_float4x4` transform for their 3D position.

---

## 7. Analytics & Success Metrics

*   **How will we measure success?**
    *   Success will be measured by the accuracy and performance of the speaker identification.
*   **Key Performance Indicators (KPIs):**
    *   **Identification Accuracy:** Percentage of correct speaker identifications in a test video with multiple speakers.
    *   **Processing Framerate (FPS):** The rate at which the vision pipeline can process camera frames.
    *   **CPU/GPU Usage:** Monitored via Xcode's profiler and Android Studio's profiler.

---

## 8. Go-to-Market & Launch Plan

*   This feature is a critical component of the hybrid localization strategy and will be highlighted as a key technological innovation in the app.

---

## 9. Open Questions & Assumptions

*   **Open Questions:**
    *   What is the most reliable and efficient way to quantify "mouth movement" from the Vision framework's landmarks and ML Kit's landmarks?
*   **Assumptions:**
    *   We assume that the Vision framework's and ML Kit's face and landmark detection is fast and accurate enough for this real-time task.
    *   We assume that in most cases, the person with the most mouth movement is the active speaker.

---

## 10. Sign-off

| Stakeholder       | Role                | Date Approved |
| :---------------- | :------------------ | :------------ |
| [Name]            | Product Manager     |               |
| [Name]            | Engineering Lead    |               |

---

## Repository Updates

- Implemented `VisualSpeakerIdentifier.swift` on iOS using the Vision framework to detect faces and analyze mouth movement.
- Implemented `VisualSpeakerIdentifier.kt` on Android using CameraX and ML Kit to detect faces and analyze mouth movement.
- Updated `VisualService` to use the native implementations on both platforms.
- Updated architecture and technical documentation.
- README now lists Visual Speaker Identification feature.

## Implementation Approach Update (2025)

**We will use a native plugin/FFI approach to interface directly with the Gemma 3n model and its .task file.**
- No third-party Dart/Flutter packages will be used for inference.
- All face detection and speaker identification will be handled natively (C/C++/Rust or platform-specific code).
- This enables full access to Gemma 3n's multimodal and audio encoders.
- The Flutter app will communicate with the native layer via FFI or platform channels.


# Product Requirements Document: Face Detection & Speaker Identification via Vision Framework

**Author:** Gemini
**Date Created:** 2025-06-29
**Last Updated:** 2025-06-29
**Status:** Draft
**Version:** 1.0

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
    *   Real-time face detection using Apple's Vision framework.
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
    *   A `VisualSpeakerIdentifier` class will encapsulate the vision processing logic.
    *   It will accept camera frames (`CVPixelBuffer`) as input.
    *   It will provide a callback or a Combine publisher that emits the screen coordinates (and potentially 3D transform) of the active speaker's face when one is identified.

---

## 6. Technical Requirements & Constraints

*   **Platform(s):** iOS 14.0+
*   **Technology Stack:** Swift, Vision framework, ARKit (for 3D coordinates).
*   **Performance Requirements:**
    *   The vision pipeline must process frames at a rate that feels real-time (e.g., >= 15 FPS) to avoid noticeable lag in caption placement.
    *   The processing must be efficient to avoid significant battery drain or overheating.
*   **Input/Output:**
    *   **Input:** `CVPixelBuffer` from the camera, and a signal indicating that speech is currently being detected.
    *   **Output:** The `CGRect` of the active speaker's face on the screen, and optionally an `ARAnchor` or `simd_float4x4` transform for their 3D position.

---

## 7. Analytics & Success Metrics

*   **How will we measure success?**
    *   Success will be measured by the accuracy and performance of the speaker identification.
*   **Key Performance Indicators (KPIs):**
    *   **Identification Accuracy:** Percentage of correct speaker identifications in a test video with multiple speakers.
    *   **Processing Framerate (FPS):** The rate at which the vision pipeline can process camera frames.
    *   **CPU/GPU Usage:** Monitored via Xcode's profiler.

---

## 8. Go-to-Market & Launch Plan

*   This feature is a critical component of the hybrid localization strategy and will be highlighted as a key technological innovation in the app.

---

## 9. Open Questions & Assumptions

*   **Open Questions:**
    *   What is the most reliable and efficient way to quantify "mouth movement" from the Vision framework's landmarks?
*   **Assumptions:**
    *   We assume that the Vision framework's face and landmark detection is fast and accurate enough for this real-time task.
    *   We assume that in most cases, the person with the most mouth movement is the active speaker.

---

## 10. Sign-off

| Stakeholder       | Role                | Date Approved |
| :---------------- | :------------------ | :------------ |
| [Name]            | Product Manager     |               |
| [Name]            | Engineering Lead    |               |

---

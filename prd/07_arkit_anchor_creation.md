
# Product Requirements Document: ARKit Anchor Creation and Placement for Speaker Localization

**Author:** Gemini
**Date Created:** 2025-06-29
**Last Updated:** 2025-06-29
**Status:** Draft
**Version:** 1.0

---

## 1. Overview & Background

*   **What is this feature?**
    *   This feature is responsible for creating and placing `ARAnchor` objects in the 3D world at the precise location of a speaker. It translates the directional angle from audio localization and/or the 3D position from visual identification into a stable AR anchor that the rendering engine can use.
*   **Why are we building this?**
    *   To display captions in a 3D AR environment, we need a stable point in space to attach them to. `ARAnchor` is the fundamental ARKit object for this purpose. This feature bridges the gap between our localization data (audio/visual) and the AR world, enabling the core 3D captioning experience.
*   **Business Objectives & Key Results (OKRs):**
    *   **Objective:** Reliably place and maintain AR anchors at the real-world locations of speakers.
        *   **Key Result 1:** An anchor is created within 10cm of the true speaker location when visual identification is used.
        *   **Key Result 2:** An anchor created from audio-only data is placed in the correct direction relative to the device.
        *   **Key Result 3:** Anchors remain stable and do not drift more than 5cm per minute as the user moves around the environment.

---

## 2. Target Audience & User Personas

*   **Who is this for?**
    *   This feature is for the AR rendering module of the LiveCaptionsXR app. It provides the foundational `ARAnchor` objects upon which 3D caption bubbles will be built.

---

## 3. User Stories & Requirements

| Priority | User Story                                                                                             | Acceptance Criteria                                                                                                                                                              |
| :------- | :----------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **P0**   | As a developer, I want to create an AR anchor based on a directional angle and an estimated distance, so I can place a caption when only audio data is available. | - A function exists that takes a horizontal angle and a distance as input. <br> - The function calculates a 3D world transform relative to the current camera position. <br> - An `ARAnchor` is created at the calculated transform and added to the AR session. |
| **P0**   | As a developer, I want to create an AR anchor based on the 3D world coordinates of a detected face, so I can place a caption with high precision. | - A function exists that takes the 3D world coordinates of a speaker's face. <br> - An `ARAnchor` is created at that precise 3D location. |
| **P1**   | As a developer, I want the anchors to be managed efficiently, so that old anchors are removed when they are no longer needed. | - The system has a mechanism to track active caption anchors. <br> - Anchors associated with completed captions are removed from the AR session to prevent clutter. |

---

## 4. Scope & Features

*   **In-Scope Features (Must-Haves):**
    *   A function to create an `ARAnchor` from a directional angle and a default distance.
    *   A function to create an `ARAnchor` from a precise 3D world position (obtained from visual tracking).
    *   Logic to add and remove anchors from the `ARSession`.
    *   Use of ARKit's raycasting or hit-testing to refine the distance estimate when possible.
*   **Out-of-Scope Features (Won't Be Included in this Version):**
    *   Persistent anchors that are saved across app sessions.
    *   Sharing anchors between multiple devices.
    *   Complex anchor smoothing or filtering beyond what ARKit provides by default.

---

## 5. Design & User Experience (UX)

*   **API Design:**
    *   An `ARAnchorManager` class will handle the creation and lifecycle of caption anchors.
    *   Methods will include `createAnchor(at angle: Float, distance: Float = 2.0)` and `createAnchor(at worldTransform: simd_float4x4)`.
    *   A method `removeAnchor(_ anchor: ARAnchor)` will be provided for cleanup.

---

## 6. Technical Requirements & Constraints

*   **Platform(s):** iOS 14.0+
*   **Technology Stack:** Swift, ARKit.
*   **Performance Requirements:**
    *   Anchor creation and placement must be fast enough to not introduce noticeable lag.
*   **Dependencies:**
    *   This feature depends on the output of the audio localization (Task 2/3) and visual identification (Task 6) modules.

---

## 7. Analytics & Success Metrics

*   **How will we measure success?**
    *   Success will be measured by the accuracy and stability of the placed anchors.
*   **Key Performance Indicators (KPIs):**
    *   **Placement Accuracy:** The measured distance between the anchor's position and the actual speaker's position.
    *   **Anchor Stability (Drift):** The amount an anchor moves in the world over time, measured in cm/minute.
    *   **Creation Latency:** The time taken to create and add an anchor to the session after receiving localization data.

---

## 8. Go-to-Market & Launch Plan

*   This is a critical internal component for the 3D mode of the app.

---

## 9. Open Questions & Assumptions

*   **Open Questions:**
    *   What is the best strategy for estimating distance when only audio data is available? Should it be a fixed default, or can we use audio properties (like volume) to make a rough guess?
*   **Assumptions:**
    *   We assume that ARKit's world tracking is stable and accurate enough for our needs.
    *   We assume that we can get reliable 3D position data for faces from our visual identification module, potentially using ARKit's scene depth or raycasting features.

---

## 10. Sign-off

| Stakeholder       | Role                | Date Approved |
| :---------------- | :------------------ | :------------ |
| [Name]            | Product Manager     |               |
| [Name]            | Engineering Lead    |               |

---

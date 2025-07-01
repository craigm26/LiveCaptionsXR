# Product Requirements Document: 3D Caption Rendering (AR Bubble Mode)

**Author:** Gemini
**Date Created:** 2025-06-29
**Last Updated:** 2025-06-30
**Status:** Complete
**Version:** 1.1

---

## 1. Overview & Background

*   **What is this feature?**
    *   This is the core Augmented Reality feature of the LiveCaptionsXR app. It involves rendering transcribed speech as 3D text "bubbles" that are anchored in the real world at the location of the speaker. The captions will appear to float in space next to the person who is talking.
*   **Why are we building this?**
    *   This feature provides a truly immersive and futuristic captioning experience. By placing captions directly in the 3D scene, we create a powerful spatial connection between the speaker and their words. This is the key differentiator and "wow" factor for the application.
*   **Business Objectives & Key Results (OKRs):**
    *   **Objective:** Deliver a compelling and immersive AR captioning experience.
        *   **Key Result 1:** 3D captions are correctly rendered at the location of their corresponding `ARAnchor`.
        *   **Key Result 2:** The 3D captions are always readable and facing the user, regardless of the user's position and orientation.
        *   **Key Result 3:** The AR rendering maintains a smooth frame rate (at least 30 FPS) on target devices.

---

## 2. Target Audience & User Personas

*   **Who is this for?**
    *   This feature is for users who want to experience the full power of Augmented Reality captioning. It is designed for users with AR-capable devices who are in an environment where they can safely move around and view the 3D scene.

---

## 3. User Stories & Requirements

| Priority | User Story                                                                                             | Acceptance Criteria                                                                                                                                                              |
| :------- | :----------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **P0**   | As a user, I want to see captions appear in the 3D space next to the person who is talking, so it feels like the words are coming from them. | - A 3D node is created for each new caption. <br> - The node is attached to the `ARAnchor` representing the speaker's location. <br> - The 3D caption is visible and correctly positioned in the AR view. |
| **P0**   | As a user, I want to be able to read the 3D captions easily, no matter where I am standing.               | - The 3D text always faces the camera (billboarding). <br> - The text has a high-contrast background to ensure readability against complex real-world scenes. |
| **P1**   | As a user, I want the 3D captions to look good and not like basic, flat text.                             | - The 3D text has some depth and is rendered with a clean, modern material. <br> - The background is a rounded 3D plane, creating a "bubble" effect. <br> - The caption node animates in and out smoothly. |

---

## 4. Scope & Features

*   **In-Scope Features (Must-Haves):**
    *   A function to procedurally generate a 3D caption node (e.g., using SceneKit or RealityKit).
    *   The 3D node will consist of a 3D text geometry and a 3D plane for the background.
    *   A billboarding constraint to ensure the caption always faces the user.
    *   Logic to add the caption node to the scene when its anchor is detected and remove it after a set duration.
    *   Fade-in and fade-out animations for the 3D node.
*   **Out-of-Scope Features (Won't Be Included in this Version):**
    *   User interaction with the 3D captions (e.g., tapping to dismiss).
    *   Physics-based animations or interactions.
    *   Occlusion of captions by real-world objects (unless provided for free by the AR framework).

---

## 5. Design & User Experience (UX)

*   **Visual Design:**
    *   The 3D text will be clean and legible.
    *   The background "bubble" will be a semi-transparent, dark, rounded 3D plane to provide contrast and a sense of depth.
    *   The overall aesthetic will be futuristic but functional.
*   **Interaction:**
    *   The user can switch to the 3D AR mode from the main UI.
    *   The captions will appear and disappear automatically as people speak.

---

## 6. Technical Requirements & Constraints

*   **Platform(s):** iOS 14.0+ (with an ARKit-compatible device).
*   **Technology Stack:** Swift, ARKit, SceneKit (or RealityKit).
*   **Performance Requirements:**
    *   The AR scene must maintain a minimum of 30 FPS, even with multiple caption nodes visible.
    *   The memory usage of the 3D assets must be kept low.
*   **Dependencies:**
    *   This feature is entirely dependent on the `ARAnchor` objects created by the anchor placement module (Task 7).

---

## 7. Analytics & Success Metrics

*   **How will we measure success?**
    *   Success will be measured by the performance and visual quality of the AR experience.
*   **Key Performance Indicators (KPIs):**
    *   **AR Frame Rate (FPS):** Monitored during runtime.
    *   **User Engagement:** Time spent in AR mode vs. 2D mode.
    *   **Qualitative Feedback:** User reviews and feedback on the immersiveness and quality of the 3D captions.

---

## 8. Go-to-Market & Launch Plan

*   The 3D AR mode will be the flagship feature of the app, heavily featured in all marketing materials, app store screenshots, and demo videos.

---

## 9. Open Questions & Assumptions

*   **Open Questions:**
    *   SceneKit or RealityKit? Which framework is better suited for this task in terms of performance, ease of use, and visual quality? A small proof-of-concept may be needed to decide.
*   **Assumptions:**
    *   We assume that rendering a moderate number of simple, billboarded 3D text nodes will not be a performance bottleneck on modern iOS devices.
    *   We assume that a simple billboarding constraint is sufficient to ensure readability in most situations.

---

## 10. Sign-off

| Stakeholder       | Role                | Date Approved |
| :---------------- | :------------------ | :------------ |
| [Name]            | Product Manager     |               |
| [Name]            | Design Lead         |               |
| [Name]            | Engineering Lead    |               |

---

## Repository Updates

- Implemented `CaptionNode.swift` to create a 3D caption node with a text and background geometry.
- Added a billboard constraint to the `CaptionNode` to ensure it always faces the user.
- Integrated the `CaptionNode` with the `ARAnchorManager` to add the caption to the scene when a new anchor is created.
- Updated architecture and technical documentation.
- README now lists 3D Caption Rendering feature.

## Implementation Approach Update (2025)

**We will use a native plugin/FFI approach to interface directly with the Gemma 3n model and its .task file.**
- No third-party Dart/Flutter packages will be used for inference.
- All 3D caption rendering and context analysis will be handled natively (C/C++/Rust or platform-specific code).
- This enables full access to Gemma 3n's multimodal and spatial encoders.
- The Flutter app will communicate with the native layer via FFI or platform channels.

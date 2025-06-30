# Product Requirements Document: IMU-based Device Orientation Integration

**Author:** Gemini
**Date Created:** 2025-06-29
**Last Updated:** 2025-06-29
**Status:** Draft
**Version:** 1.0

---

## 1. Overview & Background

*   **What is this feature?**
    *   This feature involves integrating data from the device's Inertial Measurement Unit (IMU) – specifically the gyroscope and accelerometer – to get a precise, real-time understanding of the device's orientation in 3D space.
*   **Why are we building this?**
    *   Accurate device orientation is critical for correctly interpreting the directional audio data and placing AR anchors. The audio localization tells us the direction of a sound *relative to the device*. To place a caption in the *world*, we need to know how the device itself is oriented. This feature provides that crucial piece of the puzzle, ensuring that a sound detected on the "left" is placed correctly in the world, no matter how the user is holding or turning their phone.
*   **Business Objectives & Key Results (OKRs):**
    *   **Objective:** Ensure stable and accurate placement of AR captions by providing precise device orientation data.
        *   **Key Result 1:** The system provides a continuous stream of device orientation data (e.g., as a quaternion or rotation matrix) with low latency (< 16ms).
        *   **Key Result 2:** The orientation data is accurate to within 1 degree of the true physical orientation.
        *   **Key Result 3:** The integration of IMU data results in a noticeable improvement in the stability of AR captions as the device is rotated.

---

## 2. Target Audience & User Personas

*   **Who is this for?**
    *   This is a foundational technical feature for the developers of the AR module. It is not directly user-facing, but its quality is critical to the stability and accuracy of the entire 3D captioning experience.

---

## 3. User Stories & Requirements

| Priority | User Story                                                                                             | Acceptance Criteria                                                                                                                                                              |
| :------- | :----------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **P0**   | As a developer, I need to know the device's current orientation in 3D space so that I can translate a device-relative sound direction into a world-relative direction. | - An API provides the device's orientation as a `simd_quatf` (quaternion) or `simd_float4x4` (transform matrix). <br> - The orientation data is updated at a high frequency (e.g., 60Hz or higher). <br> - The data is sourced from ARKit's world tracking, which already fuses IMU data. |

---

## 4. Scope & Features

*   **In-Scope Features (Must-Haves):**
    *   Accessing the device's orientation data, which is already processed and provided by ARKit's `ARFrame.camera.transform`.
    *   Applying this transform to the audio-based direction vector to correctly orient it in world space.
*   **Out-of-Scope Features (Won't Be Included in this Version):**
    *   Directly processing raw IMU data from Core Motion. ARKit provides a higher-level, more stable abstraction that is sufficient for our needs.
    *   Implementing custom sensor fusion algorithms (this is already handled by ARKit).

---

## 5. Design & User Experience (UX)

*   **API Design:**
    *   This feature will likely not require a new, separate API. The logic will be integrated directly into the `ARAnchorManager` (from Task 7).
    *   The `createAnchor(at angle: Float, ...)` function will be modified to use the `ARFrame.camera.transform` to correctly calculate the final world position of the anchor.

---

## 6. Technical Requirements & Constraints

*   **Platform(s):** iOS 14.0+
*   **Technology Stack:** Swift, ARKit.
*   **Performance Requirements:**
    *   Accessing the camera transform from an `ARFrame` is a very low-overhead operation and will not impact performance.
*   **Dependencies:**
    *   This feature is tightly coupled with ARKit and the anchor placement module (Task 7).

---

## 7. Analytics & Success Metrics

*   **How will we measure success?**
    *   Success is implicitly measured by the stability and correctness of the final AR caption placement.
*   **Key Performance Indicators (KPIs):**
    *   **Anchor Stability:** As measured in Task 7, the stability of anchors during device rotation will be the primary indicator of this feature's success.
    *   **Directional Correctness:** A test where the device is rotated while a sound is played from a fixed location. The resulting AR anchor should remain at the fixed location in the world.

---

## 8. Go-to-Market & Launch Plan

*   This is a critical internal component, not a user-facing feature.

---

## 9. Open Questions & Assumptions

*   **Open Questions:**
    *   None. The use of `ARFrame.camera.transform` is a standard and well-documented practice in ARKit development.
*   **Assumptions:**
    *   We assume that ARKit's sensor fusion and world-tracking are sufficiently fast, accurate, and stable for our real-time requirements. This is a safe assumption for modern iOS devices.

---

## 10. Sign-off

| Stakeholder       | Role                | Date Approved |
| :---------------- | :------------------ | :------------ |
| [Name]            | Engineering Lead    |               |

---

## Implementation Approach Update (2024)

**We will use a native plugin/FFI approach to interface directly with the Gemma 3n model and its .task file.**
- No third-party Dart/Flutter packages will be used for inference.
- All IMU orientation integration and sensor fusion will be handled natively (C/C++/Rust or platform-specific code).
- This enables full access to Gemma 3n's multimodal and sensor fusion capabilities.
- The Flutter app will communicate with the native layer via FFI or platform channels.

---

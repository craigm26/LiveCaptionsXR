# Product Requirements Document: Hybrid Localization Strategy (Fusion via Kalman Filter)

**Author:** Gemini
**Date Created:** 2025-06-29
**Last Updated:** 2025-06-29
**Status:** Draft
**Version:** 1.0

---

## 1. Overview & Background

*   **What is this feature?**
    *   This feature implements an advanced localization engine that intelligently fuses data from multiple sources – audio direction (TDOA), visual speaker identification (face tracking), and device orientation (IMU) – into a single, highly accurate, and robust estimation of the speaker's position. A Kalman filter will be used to smooth the data and predict the speaker's position, reducing jitter and improving stability.
*   **Why are we building this?**
    *   Each individual localization method has weaknesses. Audio is imprecise and struggles with noise. Vision can be blocked or fail in low light. IMU data can drift. By fusing these inputs, we create a system that is more robust and accurate than the sum of its parts. The Kalman filter will provide smooth, stable anchor positioning, which is critical for a high-quality, professional-feeling AR experience.
*   **Business Objectives & Key Results (OKRs):**
    *   **Objective:** Achieve best-in-class speaker localization accuracy and stability.
        *   **Key Result 1:** The final fused position estimate has at least 25% less jitter (variance) than the raw estimates from any single source.
        *   **Key Result 2:** The system maintains accurate tracking even if one of the data sources (e.g., vision) is temporarily lost.
        *   **Key Result 3:** The localization is perceived as "rock-solid" in user testing, with a satisfaction score > 4.8/5 for caption stability.

---

## 2. Target Audience & User Personas

*   **Who is this for?**
    *   This is a backend technical feature for the developers of the AR module. The end-user will experience the benefits through incredibly stable and accurately placed captions.

---

## 3. User Stories & Requirements

| Priority | User Story                                                                                             | Acceptance Criteria                                                                                                                                                              |
| :------- | :----------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **P0**   | As a user, I want the captions to be perfectly stable and not jump around, even if I move my head quickly or the lighting changes. | - A Kalman filter is implemented to process the stream of localization data. <br> - The filter's state includes the speaker's position and velocity. <br> - The output of the filter is a smoothed, predicted position for the AR anchor. |
| **P0**   | As a developer, I want a single, reliable source for the speaker's position, abstracting away the complexity of fusing multiple sensors. | - A `HybridLocalizationEngine` class is created. <br> - It accepts inputs from the audio, visual, and IMU modules. <br> - It outputs a single, high-quality `simd_float4x4` transform for the speaker's position. |

---

## 4. Scope & Features

*   **In-Scope Features (Must-Haves):**
    *   Implementation of a linear Kalman filter.
    *   A state model that includes position and velocity to allow for prediction.
    *   A measurement model that can incorporate data from audio (angle), vision (3D position), and IMU (device transform).
    *   Logic to adjust the filter's confidence in each measurement based on its reliability (e.g., lower confidence in audio when it's noisy).
*   **Out-of-Scope Features (Won't Be Included in this Version):**
    *   More complex non-linear filters (e.g., Extended Kalman Filter or Particle Filter), unless a linear model proves insufficient.
    *   Tracking multiple speakers simultaneously with a single filter.

---

## 5. Design & User Experience (UX)

*   **API Design:**
    *   A `HybridLocalizationEngine` class will be the central point for all localization data.
    *   It will have methods like `updateWithAudioMeasurement(angle:)`, `updateWithVisualMeasurement(transform:)`.
    *   It will provide a property or publisher, e.g., `fusedTransform: simd_float4x4`, which gives the final, filtered output.

---

## 6. Technical Requirements & Constraints

*   **Platform(s):** iOS 14.0+
*   **Technology Stack:** Swift, Accelerate framework (for matrix math).
*   **Performance Requirements:**
    *   The Kalman filter update step must be extremely fast (<< 5ms) to run in the main AR processing loop.
*   **Dependencies:**
    *   This feature depends on the outputs of the TDOA audio localization (Task 3), visual speaker identification (Task 6), and IMU integration (Task 10).

---

## 7. Analytics & Success Metrics

*   **How will we measure success?**
    *   Success will be measured by the quantifiable improvement in the stability and accuracy of the final caption position.
*   **Key Performance Indicators (KPIs):**
    *   **Position Variance / Jitter:** A statistical measure of how much the final position estimate jumps around. This should be significantly lower than the variance of the raw inputs.
    *   **Prediction Accuracy:** How well the filter predicts the next position of a moving speaker.
    *   **Robustness to Sensor Loss:** The system's ability to maintain a reasonable estimate when one of the input streams is temporarily unavailable.

---

## 8. Go-to-Market & Launch Plan

*   This is a deep-tech internal feature, but the resulting stability will be a key selling point, marketed as "rock-solid AR tracking" or similar.

---

## 9. Open Questions & Assumptions

*   **Open Questions:**
    *   What are the optimal values for the process and measurement noise covariance matrices (Q and R) in the Kalman filter? These will need to be tuned empirically to achieve the best performance.
*   **Assumptions:**
    *   We assume that a linear Kalman filter is sufficient for this problem (i.e., the speaker's motion can be reasonably approximated with a constant velocity model over short time intervals).
    *   We assume that the computational overhead of the Kalman filter is negligible on a modern iOS device.

---

## 10. Sign-off

| Stakeholder       | Role                | Date Approved |
| :---------------- | :------------------ | :------------ |
| [Name]            | Engineering Lead    |               |

---

## Implementation Approach Update (2024)

**We will use a native plugin/FFI approach to interface directly with the Gemma 3n model and its .task file.**
- No third-party Dart/Flutter packages will be used for inference.
- All hybrid localization and inference will be handled natively (C/C++/Rust or platform-specific code).
- This enables full access to Gemma 3n's multimodal and localization capabilities.
- The Flutter app will communicate with the native layer via FFI or platform channels.

---

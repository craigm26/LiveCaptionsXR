
# Product Requirements Document: Advanced Audio Localization using TDOA/GCC-PHAT

**Author:** Gemini
**Date Created:** 2025-06-29
**Last Updated:** 2025-06-29
**Status:** Draft
**Version:** 1.0

---

## 1. Overview & Background

*   **What is this feature?**
    *   This feature implements a high-precision speaker direction estimation algorithm based on Time Difference of Arrival (TDOA). It uses the Generalized Cross-Correlation with Phase Transform (GCC-PHAT) method to accurately calculate the time delay between stereo audio channels, which is then used to determine the speaker's angle with high accuracy.
*   **Why are we building this?**
    *   While basic amplitude analysis (Task 2) provides a rough direction, it is susceptible to noise and reflections. TDOA via GCC-PHAT is a much more robust and precise technique, essential for accurately anchoring AR captions in 3D space. This is a critical step up in localization quality.
*   **Business Objectives & Key Results (OKRs):**
    *   **Objective:** Deliver a high-precision, real-time speaker direction angle for accurate AR caption placement.
        *   **Key Result 1:** Achieve an angular accuracy of ±5 degrees for a stationary sound source in a controlled environment.
        *   **Key Result 2:** The TDOA calculation process adds no more than 25ms of latency to the audio pipeline.
        *   **Key Result 3:** The system successfully rejects ambient noise and reverberation to provide a stable angle estimation.

---

## 2. Target Audience & User Personas

*   **Who is this for?**
    *   This feature is for the developers of the LiveCaptionsXR application, specifically the AR rendering module. It provides the high-fidelity directional data required for believable and stable placement of 3D caption bubbles.

---

## 3. User Stories & Requirements

| Priority | User Story                                                                                             | Acceptance Criteria                                                                                                                                                              |
| :------- | :----------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **P0**   | As a developer, I want to get a precise directional angle from a stereo audio buffer using TDOA so that I can accurately anchor a 3D caption in the AR scene. | - A function exists that takes a stereo `AVAudioPCMBuffer` as input. <br> - The function implements the GCC-PHAT algorithm to find the time delay between channels. <br> - The time delay is converted into a precise horizontal angle in radians. |
| **P1**   | As a developer, I want the advanced localization to be computationally efficient to run on a mobile device in real-time. | - The implementation leverages the Accelerate framework for FFT and other signal processing operations. <br> - The algorithm is optimized to run within the specified latency budget. |

---

## 4. Scope & Features

*   **In-Scope Features (Must-Haves):**
    *   Implementation of the Fast Fourier Transform (FFT) for the left and right audio channels.
    *   Calculation of the cross-correlation of the two signals in the frequency domain.
    *   Application of the Phase Transform (PHAT) to whiten the signal and improve robustness to noise.
    *   Implementation of the Inverse Fast Fourier Transform (IFFT) to get the time-domain correlation.
    *   A function to find the peak of the cross-correlation function, which corresponds to the time delay.
    *   Conversion of the time delay into a directional angle.
*   **Out-of-Scope Features (Won't Be Included in this Version):**
    *   Localization in the vertical plane.
    *   Tracking of multiple simultaneous speakers.
    *   Fusion with visual data (covered in other tasks).

---

## 5. Design & User Experience (UX)

*   **API Design:**
    *   The feature will be implemented as a function within the `SpeechLocalizer` class, e.g., `estimateDirectionAdvanced(from buffer: AVAudioPCMBuffer) -> Float`.
    *   This function will encapsulate the entire GCC-PHAT pipeline.

---

## 6. Technical Requirements & Constraints

*   **Platform(s):** iOS 14.0+
*   **Technology Stack:** Swift, Accelerate framework (for vDSP and vForce).
*   **Performance Requirements:**
    *   The entire GCC-PHAT calculation for a single buffer must complete in under 25ms.
*   **Input/Output:**
    *   **Input:** A stereo `AVAudioPCMBuffer`.
    *   **Output:** A high-precision `Float` representing the horizontal angle in radians.

---

## 7. Analytics & Success Metrics

*   **How will we measure success?**
    *   Success will be measured by the accuracy, latency, and robustness of the angle estimation compared to the basic method.
*   **Key Performance Indicators (KPIs):**
    *   **Angular Accuracy:** Measured in degrees using a goniometer in a controlled test environment.
    *   **Latency:** End-to-end execution time of the `estimateDirectionAdvanced` function.
    *   **Robustness:** Stability of the angle output in the presence of simulated background noise and reverberation.

---

## 8. Go-to-Market & Launch Plan

*   This is an internal component and does not have a separate launch plan.

---

## 9. Open Questions & Assumptions

*   **Open Questions:**
    *   What is the exact physical distance between the microphones on the target iOS devices? This is a critical parameter for converting time delay to an angle and may need to be estimated empirically.
*   **Assumptions:**
    *   We assume that the GCC-PHAT algorithm is suitable for real-time execution on modern iOS devices.
    *   We assume a far-field sound source, which simplifies the angle calculation from the time delay.

---

## 10. Sign-off

| Stakeholder       | Role                | Date Approved |
| :---------------- | :------------------ | :------------ |
| [Name]            | Product Manager     |               |
| [Name]            | Engineering Lead    |               |

---

## Repository Updates

The following commits implement Task 3:

* Added the **scidart** dependency for FFT-based signal processing.
* Implemented `estimateDirectionAdvanced` in `SpeechLocalizer` using the
  GCC-PHAT algorithm for precise TDOA calculation.
* Updated `AudioService` to use the new advanced localization method.
* Revised README and technical docs to reflect the GCC-PHAT pipeline.

---

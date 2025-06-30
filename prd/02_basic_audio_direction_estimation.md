
# Product Requirements Document: Basic Audio Direction Estimation (Left/Right Localization)

**Author:** Gemini
**Date Created:** 2025-06-29
**Last Updated:** 2025-06-30
**Status:** Implemented
**Version:** 1.1

---

## 1. Overview & Background

*   **What is this feature?**
    *   This feature provides a basic, real-time estimation of a sound source's horizontal direction (left, center, or right) by analyzing the amplitude differences between the left and right channels of a stereo audio stream.
*   **Why are we building this?**
    *   This is the first and simplest method for speaker localization. It provides the foundational directional cue that the LiveCaptionsXR app will use to horizontally place captions in the user's view, creating a more intuitive and spatially aware experience.
*   **Business Objectives & Key Results (OKRs):**
    *   **Objective:** Provide a real-time, low-latency estimation of the speaker's horizontal direction.
        *   **Key Result 1:** The system correctly identifies whether a sound originates from the left, right, or center relative to the device with at least 80% accuracy in a controlled environment.
        *   **Key Result 2:** The direction estimation process adds less than 10ms of latency to the audio processing pipeline.
        *   **Key Result 3:** The feature delivers a continuous stream of directional angle estimates for incoming audio buffers.

---

## 2. Target Audience & User Personas

*   **Who is this for?**
    *   This feature is for the developers of the LiveCaptionsXR application, specifically for the module responsible for AR and UI placement. It provides the core data needed to decide where on the screen to place a caption.

---

## 3. User Stories & Requirements

| Priority | User Story                                                                                             | Acceptance Criteria                                                                                                                                                              |
| :------- | :----------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **P0**   | As a developer, I want to receive a directional angle from a stereo audio buffer so that I can determine the horizontal position for a caption. | - A function exists that takes a stereo `AVAudioPCMBuffer` as input. <br> - The function returns a `Float` value representing the horizontal angle (e.g., negative for left, positive for right, zero for center). <br> - The calculation is performed efficiently using the Accelerate framework. |
| **P1**   | As a developer, I want the direction estimation to be robust enough to handle varying audio levels.      | - The estimation logic normalizes the amplitude difference to provide a consistent angular mapping regardless of the overall volume. |

---

## 4. Scope & Features

*   **In-Scope Features (Must-Haves):**
    *   Calculation of Root Mean Square (RMS) amplitude for the left and right audio channels.
    *   A function to convert the normalized amplitude difference into a horizontal angle (e.g., in radians).
    *   Integration with the `StereoAudioCapture` component.
*   **Out-of-Scope Features (Won't Be Included in this Version):**
    *   Advanced localization using Time Difference of Arrival (TDOA) or cross-correlation (this is covered in Task 3).
    *   Estimation of the vertical angle of the sound source.
    *   Filtering of non-speech sounds.

---

## 5. Design & User Experience (UX)

*   **API Design:**
    *   The feature will be implemented as a function within the `SpeechLocalizer` class, e.g., `estimateDirection(from buffer: AVAudioPCMBuffer) -> Float`.
    *   The function will be self-contained and have no external dependencies other than the Accelerate framework.

---

## 6. Technical Requirements & Constraints

*   **Platform(s):** iOS 14.0+
*   **Technology Stack:** Swift, Accelerate framework (for `vDSP`).
*   **Performance Requirements:**
    *   The direction estimation function must execute in under 10ms per buffer.
*   **Input/Output:**
    *   **Input:** A stereo `AVAudioPCMBuffer`.
    *   **Output:** A `Float` representing the horizontal angle in radians.

---

## 7. Analytics & Success Metrics

*   **How will we measure success?**
    *   Success will be measured by the accuracy and performance of the direction estimation.
*   **Key Performance Indicators (KPIs):**
    *   **Directional Accuracy:** Percentage of correct left/center/right classifications in a controlled test with sound sources at known angles.
    *   **Latency:** Execution time of the estimation function, measured using `CFAbsoluteTimeGetCurrent()`.
    *   **Stability:** The consistency of the angle output for a stationary sound source.

---

## 8. Go-to-Market & Launch Plan

*   This is an internal component and does not have a separate launch plan.

---

## 9. Open Questions & Assumptions

*   **Open Questions:**
    *   What is the most effective mathematical formula to map the normalized amplitude difference to a realistic horizontal angle? This will require empirical testing and tuning.
*   **Assumptions:**
    *   We assume that for a nearby sound source, the amplitude difference between the stereo channels is a sufficiently reliable indicator of direction.
    *   We assume the device is held in a standard portrait orientation, where the microphones are aligned horizontally.

---

## 10. Sign-off

| Stakeholder       | Role                | Date Approved |
| :---------------- | :------------------ | :------------ |
| [Name]            | Product Manager     |               |
| [Name]            | Engineering Lead    |               |

---

## Repository Updates

The following commits implement Task 2:

* Added a new Dart service `SpeechLocalizer` that estimates the horizontal angle of incoming stereo audio using RMS amplitude comparison.
* Integrated `SpeechLocalizer` into `AudioService` for real-time direction estimation.
* Updated documentation and README to reflect the new localization pipeline.

---

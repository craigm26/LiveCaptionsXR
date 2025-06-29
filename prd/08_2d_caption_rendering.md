
# Product Requirements Document: 2D Caption Rendering (HUD Overlay Mode)

**Author:** Gemini
**Date Created:** 2025-06-29
**Last Updated:** 2025-06-29
**Status:** Draft
**Version:** 1.0

---

## 1. Overview & Background

*   **What is this feature?**
    *   This feature provides the user interface for displaying transcribed speech as a 2D overlay on the device's screen. The captions will be styled for readability and positioned horizontally to correspond with the detected direction of the speaker. This serves as the primary, non-AR mode for the application.
*   **Why are we building this?**
    *   A 2D HUD mode is essential for accessibility and usability. It provides a familiar, straightforward way to view captions that works on all devices, regardless of their AR capabilities. It's a critical fallback and a valuable feature in its own right for users who prefer a simpler interface.
*   **Business Objectives & Key Results (OKRs):**
    *   **Objective:** Deliver clear, readable, and correctly positioned 2D captions in real-time.
        *   **Key Result 1:** Captions are displayed on screen within 100ms of receiving the final transcribed text.
        *   **Key Result 2:** The caption placement on the screen correctly corresponds to the speaker's detected direction (left/center/right).
        *   **Key Result 3:** User testing shows a high satisfaction rate (e.g., > 4.5/5) with the readability and styling of the 2D captions.

---

## 2. Target Audience & User Personas

*   **Who is this for?**
    *   This feature is for all end-users of the LiveCaptionsXR app, particularly those who may not be in an environment suitable for AR, are using a non-AR-capable device, or simply prefer a traditional captioning view.

---

## 3. User Stories & Requirements

| Priority | User Story                                                                                             | Acceptance Criteria                                                                                                                                                              |
| :------- | :----------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **P0**   | As a user, I want to see captions displayed clearly on my screen, so I can easily read what is being said. | - Text is rendered in a high-contrast, legible font (e.g., white text on a semi-transparent black background). <br> - The caption background provides enough contrast against any camera feed. <br> - Captions automatically wrap to fit the screen width. |
| **P0**   | As a user, I want the captions to appear near the person who is talking on the screen, so I can easily follow the conversation. | - If a speaker is on the left side of the screen, the caption appears on the left. <br> - If a speaker is in the center, the caption appears in the center or at the bottom. <br> - The caption position updates smoothly if the speaker's detected location changes. |
| **P1**   | As a user, I want captions to fade in and out smoothly, so the experience is not jarring.                 | - Captions appear and disappear using a subtle fade animation. <br> - Old captions are removed from the screen after a configurable duration to prevent clutter. |

---

## 4. Scope & Features

*   **In-Scope Features (Must-Haves):**
    *   A UI component (e.g., a custom `UIView` or SwiftUI `View`) for displaying a single caption.
    *   Styling that mimics standard closed-captioning (e.g., white text, semi-transparent black rounded rectangle background).
    *   Logic to position the caption view on the screen based on a horizontal angle or the 2D coordinates of a detected face.
    *   Management of multiple simultaneous captions (if multiple people are speaking in sequence).
    *   Fade-in and fade-out animations for captions.
*   **Out-of-Scope Features (Won't Be Included in this Version):**
    *   User-customizable caption styles (e.g., font size, color).
    *   Displaying captions in a scrolling transcript view.

---

## 5. Design & User Experience (UX)

*   **UI Design:**
    *   Captions will use a clean, sans-serif font.
    *   The background will be a "speech bubble" style rounded rectangle.
    *   The overall look and feel will be modern and unobtrusive, prioritizing readability.
*   **Interaction:**
    *   The 2D mode will be the default view when the app is opened.
    *   The user will be able to switch between 2D and 3D AR modes.

---

## 6. Technical Requirements & Constraints

*   **Platform(s):** iOS 14.0+
*   **Technology Stack:** Swift, UIKit or SwiftUI.
*   **Performance Requirements:**
    *   Rendering and animating captions must not impact the performance of the underlying camera feed or ASR processing.
    *   The UI must remain responsive at all times.
*   **Dependencies:**
    *   This feature depends on the output of the ASR (Task 4) and localization (Task 2/3/6) modules.

---

## 7. Analytics & Success Metrics

*   **How will we measure success?**
    *   Success will be measured through performance monitoring and user feedback.
*   **Key Performance Indicators (KPIs):**
    *   **Rendering Latency:** The time from receiving a transcription result to the caption being visible on screen.
    *   **UI Responsiveness:** The app's main thread should never be blocked by the caption rendering logic.
    *   **User Satisfaction Score:** Gathered from user surveys or app store reviews.

---

## 8. Go-to-Market & Launch Plan

*   This will be presented as the primary, most accessible mode of the application.

---

## 9. Open Questions & Assumptions

*   **Open Questions:**
    *   What is the optimal duration to display a caption before it fades out?
*   **Assumptions:**
    *   We assume that a simple horizontal positioning of captions is sufficient for a good 2D user experience.
    *   We assume that the chosen styling will be legible across a wide variety of background camera scenes.

---

## 10. Sign-off

| Stakeholder       | Role                | Date Approved |
| :---------------- | :------------------ | :------------ |
| [Name]            | Product Manager     |               |
| [Name]            | Design Lead         |               |
| [Name]            | Engineering Lead    |               |

---

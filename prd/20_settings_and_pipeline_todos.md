# Product Requirements Document: Settings & Pipeline TODOs

**Author:** GitHub Copilot
**Date Created:** 2025-07-17
**Status:** Draft
**Version:** 0.1

---

## 1. Overview

This PRD documents the remaining TODOs and enhancements for the LiveCaptionsXR settings and multistage captioning pipeline, based on the current implementation and previous PRD requirements.

---

## 2. Motivation

To ensure the settings UI, user experience, and backend pipeline fully meet user needs and the product vision, the following improvements and integrations are required.

---

## 3. User Stories & Requirements

| Priority | User Story                                                                                 | Acceptance Criteria                                                                                       |
|----------|--------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------|
| P0       | As a user, I want the selected ASR backend and STT mode to immediately affect captioning.  | Changing ASR backend or STT mode in settings updates the active engine in real time.                     |
| P0       | As a user, I want to see a clear indicator when captions are being processed or delayed.   | UI displays a "Processing..." indicator during STT/enhancement delays; indicator disappears when ready.  |
| P1       | As a user, I want analytics to track my use of captioning features and settings.           | Analytics events are logged for caption generation, enhancement, mode switches, and processing delays.   |
| P1       | As a user, I want to understand the privacy and performance tradeoffs of each STT mode.    | UI provides tooltips or dialogs explaining privacy/performance for each mode.                            |
| P2       | As a user, I want to toggle LED alerts and see all available accessibility options.         | LED alerts and all accessibility toggles are exposed in the settings UI.                                 |
| P2       | As a user, I want help or documentation for each setting.                                  | Tooltips or help screens are available for all settings.                                                 |

---

## 4. Scope & Features

**In-Scope:**
- Real-time integration of settings with backend services (audio router, enhanced speech processor with whisper_ggml)
- UI indicator for caption processing state
- Analytics event logging for all key user actions
- Exposing all user preferences in the settings UI (including LED alerts)
- User guidance/help for all settings
- Code cleanup (remove duplicate imports, etc.)

**Out-of-Scope:**
- Major redesign of the settings UI
- Support for additional STT providers beyond current scope

---

## 5. Technical Requirements

- Settings changes must trigger immediate updates in backend services (e.g., engine switching between whisper_ggml and other engines)
- UI must show a processing indicator during caption delays
- Analytics events must be logged for all key actions
- All user preferences must be persisted and loaded on app start
- Codebase must be cleaned of duplicate imports and dead code

---

## 6. Success Metrics

- No user-reported issues with settings not taking effect
- Processing indicator visible during all caption delays
- Analytics events visible in dashboard for all tracked actions
- All settings available and documented in the UI
- Codebase passes lint/format checks

---

## 7. Open Questions

- What is the best UX for explaining privacy/performance tradeoffs?
- Should engine switching be debounced or confirmed by the user?
- Are there additional accessibility options users want?

---

## 8. Next Steps

---

## 9. Implementation Summary (as of July 17, 2025)

- Real-time backend integration for settings changes (ASR backend, STT mode) is complete and live.
- UI processing indicator is present and functional, showing "Processing..." during caption delays.
- Analytics event logging is not yet implemented (skipped for now).
- Settings UI now exposes all user preferences, including enhancement, haptic feedback, and LED alerts.
- Tooltips/help documentation are provided for all settings in the UI.
- Code cleanup performed: duplicate imports removed, settings and audio code reviewed for dead code and structure. No major architectural issues found in core settings/audio blocks.
- Further codebase review is ongoing for deeper architectural and code quality improvements.
- **Legacy cleanup:** Removed unused `gemma_3n_service.dart` (all logic now consolidated in `gemma3n_service.dart`).

1. Implement real-time backend integration for settings changes
2. Add processing indicator to UI
3. Add analytics event logging
4. Expand settings UI for all preferences
5. Add tooltips/help for all settings
6. Clean up codebase (including removal of legacy/unused files)

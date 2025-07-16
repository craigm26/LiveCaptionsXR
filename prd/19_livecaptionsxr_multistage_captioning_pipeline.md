# Product Requirements Document: LiveCaptionsXR Multistage Captioning Pipeline

**Author:** Craig Merry
**Date Created:** [Date]
**Last Updated:** [Date]
**Status:** Draft
**Version:** 1.0

---

## 1. Overview & Background

* **What is this product/feature?**
  * A robust, two-stage pipeline for real-time captioning in LiveCaptionsXR, combining fast speech-to-text (STT) with advanced, on-device contextual enhancement using Gemma 3n. The system supports both online (cloud) and offline (on-device) STT, and fuses text with camera input for spatially-aware, context-rich captions.
* **Why are we building this?**
  * To overcome the limitations of current on-device models for real-time video and STT, and to deliver unique, contextually enhanced captions that leverage the strengths of Gemma 3n. This approach ensures reliability, privacy, and a superior user experience regardless of connectivity.
* **Business Objectives & Key Results (OKRs):**
  * **Objective:** Deliver best-in-class, context-aware live captioning for AR/XR users
    * **Key Result 1:** Achieve 95%+ caption accuracy in both online and offline modes
    * **Key Result 2:** 80% of users utilize enhanced captions within 1 month of launch
    * **Key Result 3:** Reduce user-reported captioning errors by 50% compared to previous versions

---

## 2. Target Audience & User Personas

* **Who is this for?**
  * AR/XR users who require reliable, real-time captions for accessibility, communication, or situational awareness, regardless of network connectivity.
* **User Personas:**
  * **Persona 1: Alex the Power User**
    * **Demographics:** 32, urban, tech-savvy, uses AR glasses for work and social events
    * **Goals:** Needs accurate, always-on captions in noisy or multi-speaker environments
    * **Frustrations:** Hates unreliable or delayed captions, values privacy
  * **Persona 2: Sam the Newcomer**
    * **Demographics:** 24, student, new to AR/XR, uses captions for accessibility
    * **Goals:** Wants easy setup and clear, readable captions
    * **Frustrations:** Confused by technical settings, dislikes slow or missing captions

---

## 3. User Stories & Requirements

| Priority | User Story                                                                                             | Acceptance Criteria                                                                                                                                                              |
| :------- | :----------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **P0**   | As Alex, I want captions to work seamlessly online and offline so that I always have access to live captions. | - Captions are available in both online and offline modes.<br>- The app automatically switches modes based on connectivity.<br>- Users can manually override mode selection. |
| **P0**   | As Sam, I want captions to be contextually enhanced so that I can better understand who is speaking and what is happening. | - Enhanced captions include spatial/contextual info (e.g., "Person to your right said: ...").<br>- Enhancement is performed on-device using Gemma 3n.<br>- Users can toggle enhancement on/off. |
| **P1**   | As Alex, I want to choose between cloud and on-device STT so that I can balance privacy and performance. | - User can select preferred STT mode in settings.<br>- App displays which mode is active.<br>- Privacy and performance tradeoffs are clearly explained. |
| **P2**   | As Sam, I want to see a "Processing..." indicator when captions are delayed so that I know the app is working. | - UI shows a clear indicator during STT or enhancement delays.<br>- Indicator disappears when caption is ready. |

---

## 4. Scope & Features

* **In-Scope Features (Must-Haves):**
  * Audio Router Service to select between cloud and on-device STT
  * Integration with at least one cloud STT API (e.g., Google, Azure)
  * Integration with an on-device STT model (e.g., Whisper)
  * Camera snapshot service for capturing context images
  * Multimodal enhancement using Gemma 3n via flutter_gemma
  * User settings for mode selection and enhancement toggling
  * UI indicators for processing state
* **Out-of-Scope Features (Won't Be Included in this Version):**
  * Real-time video stream analysis by Gemma 3n (pending model support)
  * Support for additional STT providers beyond initial launch (future work)
  * Advanced speaker diarization (future enhancement)

---

## 5. Design & User Experience (UX)

* **Wireframes & Mockups:**
  * [Link to Figma/designs]
* **User Flow Diagram:**
  * ![Pipeline Diagram](../docs/architecture_pipeline.png) <!-- Replace with actual diagram path -->
* **Key UX Principles:**
  * **Simplicity:** Minimal setup, clear feedback, and easy mode switching
  * **Accessibility:** High-contrast captions, AR-friendly overlays, WCAG 2.1 AA compliance
  * **Consistency:** Unified look and feel across modes and platforms

---

## 6. Technical Requirements & Constraints

* **Platform(s):** iOS, Android, (optionally macOS, Windows for dev/testing)
* **Technology Stack:** Flutter, flutter_gemma, cloud STT API, Whisper (or similar), camera plugin
* **Performance Requirements:**
  * Caption latency < 1s (cloud), < 5s (offline)
  * Enhancement latency < 2s
* **Security & Privacy:**
  * All audio/image data processed on-device unless user opts for cloud
  * Cloud STT only used with explicit user consent
  * GDPR/CCPA compliance
* **Dependencies & Integrations:**
  * flutter_gemma, cloud STT API, Whisper, camera plugin

---

## 7. Analytics & Success Metrics

* **How will we measure success?**
  * Caption accuracy, user adoption of enhanced mode, latency metrics, user satisfaction
* **Key Performance Indicators (KPIs):**
  * **Adoption Rate:** % of users using enhanced captions
  * **Latency:** Average time from speech to caption display
  * **User Satisfaction:** In-app survey/NPS
  * **Error Rate:** User-reported captioning issues
* **Analytics Events:**
  * `caption_generated`, `enhancement_used`, `mode_switched`, `processing_delay_shown`

---

## 8. Go-to-Market & Launch Plan

* **Launch Tiers:**
  * **Internal Alpha:** [Date] - Internal team testing
  * **Closed Beta:** [Date] - Early access for select users
  * **General Availability (GA):** [Date] - Public release
* **Marketing & Communication:**
  * Blog post, social media, accessibility community outreach

---

## 9. Open Questions & Assumptions

* **Open Questions:**
  * Which cloud STT API will be used for launch?
  * What is the expected device compatibility for on-device models?
  * How will we handle privacy for camera images?
* **Assumptions:**
  * Users will accept a short delay for offline mode
  * Devices have sufficient resources for Gemma 3n and Whisper

---

## 10. Sign-off

| Stakeholder       | Role                | Date Approved |
| :---------------- | :------------------ | :------------ |
| [Name]            | Product Manager     |               |
| [Name]            | Engineering Lead    |               |
| [Name]            | Design Lead         |               |
| [Name]            | Marketing Manager   |               |

---

## 11. Service Refactor & Consolidation Plan

To support the new multistage captioning pipeline and improve maintainability, the following service refactor and consolidation plan is recommended:

### A. Multimodal AI Services

* **Gemma3nService** will become the single entry point for all Gemma 3n inference (text, audio, image, multimodal).

* **AudioService** and **VisualIdentificationService** will be refactored to be thin wrappers/adapters that use Gemma3nService for all AI logic.
* **GemmaEnhancer** will be merged into Gemma3nService as a "text enhancement" method, or kept as a utility if it adds significant value.

### B. Speech & Audio Processing

* **EnhancedSpeechProcessor** will coordinate all STT, language detection, and enhancement, using Gemma3nService for inference.

* **AudioService** will focus on audio capture and event detection, delegating all AI to Gemma3nService.
* **LanguageDetectionService** will be used as a utility or integrated into EnhancedSpeechProcessor.

### C. Camera & Visual Services

* **VisualService** will use **CameraService** for hardware access and provide a simple snapshot API.

* **VisualIdentificationService** will use VisualService for image capture and Gemma3nService for inference.

### D. Localization

* **LocalizationService** and **HybridLocalizationEngine** will be merged or clarified. If HybridLocalizationEngine is a lower-level wrapper, LocalizationService should use it internally, or they should be merged if their responsibilities are redundant.

### E. Utilities

* **DebugLoggerService** and **HapticService** will remain as utilities, but all services should use the centralized logger and haptic feedback as needed.

#### Summary Table

| Service                     | Keep/Refactor/Merge | Notes                                                      |
|-----------------------------|---------------------|------------------------------------------------------------|
| AIService                   | Refactor/Remove     | Replace with orchestration via specialized services         |
| AudioService                | Refactor            | Focus on audio I/O, delegate AI to Gemma3nService          |
| Gemma3nService              | Keep (centralize)   | Make the single entry for all Gemma 3n inference           |
| VisualIdentificationService | Refactor            | Use VisualService + Gemma3nService                         |
| GemmaEnhancer               | Merge/Utility       | Integrate as method in Gemma3nService or keep as utility   |
| EnhancedSpeechProcessor     | Refactor            | Centralize all STT, language detection, enhancement        |
| LocalizationService         | Merge/Refactor      | Merge with HybridLocalizationEngine if possible             |
| HybridLocalizationEngine    | Merge/Refactor      | See above                                                  |
| CameraService               | Keep                | Used by VisualService                                      |
| VisualService               | Refactor            | Use CameraService, provide snapshot API                    |
| HapticService               | Keep                | Utility                                                    |
| LanguageDetectionService    | Utility/Refactor    | Use as part of speech/audio pipeline                       |
| DebugLoggerService          | Keep                | Utility                                                    |

#### Next Steps

1. Decide on the centralization of Gemma3nService for all AI inference.
2. Refactor AudioService, VisualIdentificationService, and EnhancedSpeechProcessor to use Gemma3nService.
3. Merge or clarify the roles of LocalizationService and HybridLocalizationEngine.
4. Ensure all services use shared utilities (logger, haptics) for consistency.

---

## 12. Model Refactor & Consolidation Plan

To improve maintainability, reusability, and support the multistage captioning pipeline, the following model refactor and consolidation plan is recommended:

### A. Speech & Caption Models

* **SpeechResult** and **TranscriptionResult** are very similar. Merge TranscriptionResult into SpeechResult, keeping only necessary fields.

* **EnhancedCaption** could potentially be merged with SpeechResult for a unified caption model, or kept separate for clarity (one for raw, one for enhanced captions).

### B. Multimodal Event Models

* **SoundEvent** and **VisualObject** both have metadata, description, confidence, and context fields. Consider a shared interface or abstract class for multimodal events, or at least standardize metadata and context handling.

* If more event types are anticipated (e.g., haptic, environmental), a base class will help future-proof the model layer.

### C. Config & Settings

* **SpeechConfig** is well-structured and should be kept as is.

* **UserSettings** is currently a placeholder; expand it to include all user preferences (e.g., STT mode, enhancement toggles, accessibility options).

#### Summary Table

| Model              | Keep/Refactor/Merge | Notes                                                      |
|--------------------|---------------------|------------------------------------------------------------|
| SoundEvent         | Keep/Standardize    | Consider base class for multimodal events                  |
| VisualObject       | Keep/Standardize    | See above                                                  |
| EnhancedCaption    | Keep/Possibly Merge | Could merge with SpeechResult for unified caption model    |
| SpeechResult       | Merge/Refactor      | Merge with TranscriptionResult                             |
| TranscriptionResult| Merge/Delete        | Merge into SpeechResult                                    |
| SpeechConfig       | Keep                | Well-structured                                            |
| UserSettings       | Expand              | Add all user preferences                                   |

#### Next Steps

1. Merge TranscriptionResult into SpeechResult.
2. Consider a base class or interface for SoundEvent and VisualObject for shared context/metadata.
3. Decide if EnhancedCaption and SpeechResult should be unified or kept separate.
4. Expand UserSettings to cover all user preferences.
5. Standardize metadata/context fields across models for easier multimodal fusion.

---

## 13. Feature Refactor & Consolidation Plan

To improve maintainability, reusability, and support the multistage captioning pipeline, the following feature refactor and consolidation plan is recommended:

### A. AR Orchestration

* Centralize orchestration of AR-related services (live captions, sound detection, localization, visual identification) in **ARSessionCubit** (or a new **AROchestratorCubit**), reducing duplication in HomeScreen and feature cubits.

### B. Cubit Simplification

* Many cubits (sound_detection, localization, visual_identification) are thin wrappers with similar start/stop logic. Consider a generic base class or utility mixin for start/stop/isActive logic.

### C. Live Captions

* Both **LiveCaptionsCubit** and **EnhancedLiveCaptionsCubit** exist. Merge if possible, or use a single cubit with a mode flag for enhancement.

### D. Settings & User Preferences

* Expand the **Settings** feature to cover all user preferences, including AR, captions, enhancement toggles, etc.

### E. Utility/Diagnostic Features

* **model_status** and **onboarding** are standalone and can remain as such.

#### Summary Table

| Feature                | Keep/Refactor/Merge | Notes                                                      |
|------------------------|---------------------|------------------------------------------------------------|
| ar_session             | Refactor            | Centralize orchestration of AR-related services            |
| home                   | Refactor            | Delegate service orchestration to ARSessionCubit           |
| live_captions          | Merge/Refactor      | Merge cubits or use mode flag for enhancement              |
| localization           | Merge/Refactor      | Consider merging with sound_detection or AR session        |
| model_status           | Keep                | Utility/diagnostic                                         |
| onboarding             | Keep                | Standalone                                                 |
| settings               | Expand              | Cover all user preferences                                 |
| sound_detection        | Merge/Refactor      | Consider merging with localization or AR session           |
| visual_identification  | Merge/Refactor      | Consider merging with AR session or generic base cubit     |

#### Next Steps

1. Centralize AR service orchestration in ARSessionCubit (or new AROrchestratorCubit).
2. Refactor HomeScreen to delegate all AR/service logic to ARSessionCubit.
3. Merge or unify LiveCaptionsCubit and EnhancedLiveCaptionsCubit.
4. Consider a generic base class or mixin for feature cubits with similar start/stop logic.
5. Expand Settings to cover all user preferences.
6. Keep model_status and onboarding as standalone features.

---

## 14. App Structure & Utility Refactor Plan

To further improve maintainability, reduce duplication, and support cross-platform development, the following app structure and utility refactor plan is recommended:

### A. App Shell & Entry Points

* There is duplication between native and web app entry points and shells (`app.dart`, `app_shell.dart`, `web/app/app_web.dart`, `web/app/app_shell_web.dart`).

* **Recommendation:** Consider a shared base for app shell logic, with platform-specific extensions for navigation and UI. The web shell could be expanded to match the native shell, or a single shell could be used with conditional logic.

### B. Shared Widgets and Theme

* `lib/shared/widgets/` contains reusable widgets; review for unused widgets or those that could be merged (e.g., caption_bubble and caption_overlay).

* `lib/theming/` is empty and can be deleted; keep all theming in `shared/theme/app_theme.dart`.

### C. Core and Web Utilities

* `lib/core/utils/` and `lib/web/utils/` both contain utility files. If any logic in `web/utils` is not web-specific, move it to `core/utils` for reuse. Standardize utility function locations (e.g., all logging in core/utils/logger.dart).

### D. Web Pages and Widgets

* `lib/web/pages/` and `lib/web/widgets/` contain large, separate Dart files for each web page and navigation. If any page logic or widgets are duplicated between web and native, consider moving to shared/widgets or shared/pages. Unify page/widget implementations where possible.

### E. Config

* `lib/web/config/web_performance_config.dart` is web-specific and can remain unless config is duplicated elsewhere.

#### Summary Table

| Area                | Keep/Refactor/Merge | Notes                                                      |
|---------------------|---------------------|------------------------------------------------------------|
| app.dart / app_web.dart | Refactor/Unify        | Share more logic between native and web app setup          |
| app_shell.dart / app_shell_web.dart | Refactor/Unify        | Use a single shell with platform-specific UI if possible   |
| shared/widgets      | Review/Merge        | Merge similar widgets, remove unused                       |
| shared/theme vs theming | Delete/Merge         | Delete empty theming/, keep all theme in shared/theme      |
| core/utils vs web/utils | Merge/Refactor        | Move non-web-specific utils to core/utils                  |
| web/pages & widgets | Merge/Refactor      | Move shared logic/widgets to shared/ if possible           |
| web/config          | Keep                | Web-specific, unless config is duplicated elsewhere        |

#### Next Steps

1. Unify app shell and app setup logic for web and native where possible.
2. Delete the empty `lib/theming/` directory.
3. Move any non-web-specific utilities from `web/utils` to `core/utils`.
4. Review shared/widgets for unused or redundant widgets and merge where possible.
5. If web and native pages/widgets are similar, move shared code to shared/.
6. Standardize all theming in `shared/theme/app_theme.dart`.

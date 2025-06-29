
# live_captions_xr - Project Plan

**This document tracks the development status and milestones for live_captions_xr, guided by the detailed PRDs in the `/prd` directory.**

---

## Development Process

This project follows a **PRD-driven development** methodology. The entire scope of the project has been broken down into 14 distinct, manageable tasks. Each task has a corresponding Product Requirements Document (PRD) in the `/prd` directory.

**All development work must align with the specifications outlined in these PRDs.** They are the single source of truth for features, architecture, and acceptance criteria.

---

## Current Development Status (as of June 2025)

The project is currently in the **initial implementation phase**. The foundational architecture has been defined, and the development tasks have been clearly specified in the PRDs.

### ✅ Completed
-   **Architecture Definition:** The layered, MediaPipe-based architecture is documented in `ARCHITECTURE.md`.
-   **PRD Creation:** All 14 core tasks have a detailed PRD.
-   **Project Scaffolding:** The initial Flutter project is set up.

### 🔄 In Progress
-   Implementation of the tasks as defined in the `/prd` directory, starting with the foundational layers (Audio Capture, Basic Localization, etc.).

---

## Development Milestones

The project will be developed by implementing the features outlined in the PRDs in a logical order.

### Milestone 1: Foundational Services
-   **Goal:** Implement the core data capture and processing services.
-   **Relevant PRDs:**
    -   `01_on_device_audio_capture.md`
    -   `02_basic_audio_direction_estimation.md`
    -   `06_face_detection_speaker_identification.md`
    -   `10_imu_orientation_integration.md`

### Milestone 2: Core AI Integration
-   **Goal:** Integrate the Gemma 3n model for ASR and multimodal fusion using MediaPipe.
-   **Relevant PRDs:**
    -   `04_gemma_3n_streaming_asr.md`
    -   `05_multimodal_fusion.md`

### Milestone 3: AR and UI Implementation
-   **Goal:** Build the 2D and 3D user interfaces for displaying captions.
-   **Relevant PRDs:**
    -   `07_arkit_anchor_creation.md`
    -   `08_2d_caption_rendering.md`
    -   `09_3d_caption_rendering.md`
    -   `12_ux_ui_design.md`

### Milestone 4: Advanced Features & Optimization
-   **Goal:** Implement the advanced localization and performance optimizations.
-   **Relevant PRDs:**
    -   `03_advanced_audio_localization.md`
    -   `11_hybrid_localization_strategy.md`
    -   `13_performance_optimization.md`

### Milestone 5: CI/CD and Release
-   **Goal:** Automate the build and deployment process.
-   **Relevant PRDs:**
    -   `14_ci_cd_pipeline.md`

---

## Risk Assessment & Mitigation

| Risk                               | Impact | Probability | Mitigation Strategy                                                                                             |
| ---------------------------------- | ------ | ----------- | --------------------------------------------------------------------------------------------------------------- |
| MediaPipe API limitations          | High   | Medium      | The architecture is modular, allowing for alternative inference engines if necessary. Stay updated on MediaPipe releases. |
| Performance on lower-end devices   | Medium | High        | Implement adaptive quality settings and prioritize optimizations as per PRD #13.                                |
| Accuracy of localization algorithms | Medium | Medium      | The hybrid fusion strategy (PRD #11) is designed to mitigate the weaknesses of individual algorithms.           |

---

*This document provides a high-level overview. For specific technical requirements and implementation details, please refer to the individual PRDs in the `/prd` directory.*

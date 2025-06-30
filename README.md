# live_captions_xr

**Real-time, spatially-aware closed captioning for Android XR and iOS, powered by on-device multimodal AI.**

---

## 🎯 Purpose

`live_captions_xr` is a real-time closed captioning application that leverages the power of Google's Gemma 3n model to provide an immersive and accessible experience. The project is designed for Android XR headsets and standard iOS/Android devices, providing spatially-aware captions that indicate the direction of sound.

This project is developed by Craig Merry, who, being Deaf, is driven by the personal need for more advanced and context-aware accessibility tools.

## ✨ Core Features

*   **On-Device AI:** All processing is done locally using the Gemma 3n `.task` model, ensuring privacy and low latency.
*   **Multimodal Input:** The system is designed to fuse audio and visual data, providing context-aware transcriptions.
*   **Spatial Audio Localization:** Utilizes stereo audio analysis to determine the direction of sound sources, placing captions spatially in the UI. A new `SpeechLocalizer` service provides real-time left/right angle estimates using RMS amplitude comparison.
*   **Stereo Audio Capture:** New `StereoAudioCapture` service provides low-latency PCM buffers from the device microphones.
*   **Cross-Platform:** Built with Flutter, targeting Android (including XR) and iOS.
*   **High-Performance:** Leverages Google's MediaPipe Tasks for optimized, hardware-accelerated inference.

## 🏛️ Architecture

The application is built on a clean, layered architecture that separates concerns and promotes maintainability.

*   **Presentation Layer:** Flutter UI, responsible for rendering 2D and 3D captions.
*   **Business Logic Layer:** Manages application state and business logic using the Cubit pattern.
*   **Service Layer:** Contains services for audio processing, visual identification, and Gemma 3n inference.
*   **Data/Platform Layer:** Interfaces with hardware (camera, microphone) and the native MediaPipe inference engine.

For a detailed explanation of the architecture, please see the [ARCHITECTURE.md](ARCHITECTURE.md) file.

---

## Development Guidance

This project is structured into a series of well-defined tasks, each with its own Product Requirements Document (PRD) located in the `/prd` directory. All development, by both humans and AI agents, must reference and align with these PRDs.

-   **Always consult the relevant PRD** before starting any new feature, refactor, or review.
-   The PRDs are the single source of truth for feature scope, acceptance criteria, and technical requirements.
-   When using AI-assisted development tools, provide the relevant PRD as context.

---

## 🚀 Getting Started

### Prerequisites

-   Flutter 3.x
-   An IDE such as Android Studio or VS Code with the Flutter plugin.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/craigm26/live_captions_xr.git
    cd live_captions_xr
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    ```bash
    flutter run
    ```

---

## 📚 Project Documentation

For more detailed information, please refer to the following documents:

-   **[ARCHITECTURE.md](ARCHITECTURE.md):** The detailed technical architecture of the system.
-   **[TECHNICAL_WRITEUP.md](TECHNICAL_WRITEUP.md):** A comprehensive technical explanation of the project.
-   **`/prd` directory:** Contains the detailed Product Requirements Documents for each development task.

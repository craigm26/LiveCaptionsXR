# Gemini Project Configuration: Live Captions XR

This document outlines the core architectural and technical decisions for the Live Captions XR project, enabling Gemini to provide informed and context-aware assistance.

## 1. Core Technologies & Architecture

- **Cross-Platform Framework:** The application is built with **Flutter**, enabling a shared codebase for the UI and business logic across iOS and Android.
- **Native Integration for AR:** Augmented Reality features are implemented natively to leverage platform-specific capabilities:
    - **iOS:** **ARKit** is used for world tracking, scene understanding, and rendering.
    - **Android:** **ARCore** is used for the same purposes.
- **Communication Bridge:** A robust system of **Flutter Plugins** using **MethodChannels** and **EventChannels** connects the Dart frontend with the native Swift/Kotlin/Java backend. This is the primary mechanism for invoking native AR functionality and passing data.

## 2. Speaker Localization Strategy

The core challenge is to accurately place captions in 3D space corresponding to the speaker's location. This is achieved through a **Hybrid Localization Engine**.

- **Multimodal Data Fusion:** The engine fuses data from multiple on-device sensors:
    - **Audio:** Direction is estimated from the stereo microphone array using techniques like RMS and GCC-PHAT.
    - **Vision:** The camera is used for visual detection of potential speakers.
    - **Inertial:** The **IMU** provides device orientation data.
- **Kalman Filter:** A Kalman filter is employed to merge these data streams, providing a robust and real-time estimation of the speaker's 3D position.

## 3. On-Device AI & Speech Recognition

- **Speech-to-Text:** The app uses a **Gemma 3n `.task` model** for streaming, on-device Automatic Speech Recognition (ASR).
- **Inference Engine:** The **MediaPipe LLM Inference API** is used to run the Gemma model efficiently on-device.
- **Multimodal Context:** The system is designed for multimodal fusion, using both audio and vision to provide context for the ASR engine.
- **Privacy:** A key design principle is **privacy**. All sensor data (camera, microphone) is processed locally on the device and is not sent to the cloud.

## 4. Key MethodChannels

The following MethodChannels are critical for the app's functionality. Gemini should be aware of their purpose when analyzing code or implementing new features.

- `live_captions_xr/ar_navigation`: Used to initiate and manage the transition from the Flutter UI to the native AR view.
- `live_captions_xr/caption_methods`: The primary channel for sending finalized text and the corresponding 3D transform to the native layer for rendering AR captions.
- `live_captions_xr/hybrid_localization_methods`: Facilitates communication between the Dart layer and the native Hybrid Localization Engine.
- `live_captions_xr/visual_object_methods`: Sends information about visually detected objects (e.g., faces) from the native AR view back to the Dart application logic.

## 5. Project Structure & Conventions

- **Documentation:** Architectural deep-dives and research are located in the `docs/` directory. Product Requirement Documents (PRDs) are in the `prd/` directory. The main project `README.md` serves as the entry point to the documentation.
- **Native Code:** iOS-specific Swift code is located in `ios/Runner/`. Android-specific code is in `android/app/src/`.
- **Flutter Code:** The main Dart application logic is within the `lib/` directory.
- **Plugins:** Custom-built plugins are located in the `plugins/` directory.

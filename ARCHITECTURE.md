# LiveCaptionsXR System Architecture

**A layered, service-oriented architecture for real-time, on-device multimodal AI.**

---

## 1. High-Level Architecture

The system is designed with a clear separation of concerns, organized into four primary layers. This layered approach ensures that the application is scalable, maintainable, and testable.

```
┌─────────────────────────────────────────────────────────────────┐
│                    Presentation Layer (Flutter UI)              │
│     (Renders 2D/3D Captions, Manages User Interaction)          │
└─────────────────────────────────────────────────────────────────┘
                                ▲
                                │ (State Updates)
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                 Business Logic Layer (Cubit/BLoC)               │
│      (Manages State, Handles User Input, Orchestrates Services) │
└─────────────────────────────────────────────────────────────────┘
                                ▲
                                │ (Service Calls)
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                       Service Layer                             │
│ (Audio Processing, Visual Identification, Gemma 3n Inference)   │
└─────────────────────────────────────────────────────────────────┘
                                ▲
                                │ (Platform Channels / FFI)
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Data / Platform Layer (Native)                 │
│   (MediaPipe, Camera/Audio APIs, Hardware Abstraction)          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Detailed Layer Breakdown

### 2.1. Presentation Layer

*   **Framework:** Flutter
*   **Responsibilities:**
    *   Rendering the user interface, including both the 2D HUD and the 3D AR caption modes.
    *   Handling user input and gestures.
    *   Displaying the final, processed captions to the user.
    *   Subscribing to state updates from the Business Logic Layer and rebuilding the UI accordingly.

### 2.2. Business Logic Layer

*   **Framework:** `flutter_bloc` (primarily using the Cubit pattern).
*   **Responsibilities:**
    *   Managing the application's state (e.g., recording status, caption history, UI mode).
    *   Responding to UI events and orchestrating the necessary calls to the Service Layer.
    *   Providing streams of state that the Presentation Layer can listen to.
    *   This layer acts as the "brain" of the application, connecting the UI to the underlying services.

### 2.3. Service Layer

*   **Framework:** Pure Dart classes, managed with `get_it` for dependency injection.
*   **Responsibilities:**
    *   Encapsulating specific business functionalities into distinct services.
    *   **`GemmaASR`:** Provides streaming on-device ASR using the Gemma 3n model. It now accepts an optional visual context (camera frame) to perform multimodal fusion, improving transcription accuracy by allowing the model to "see" what it's hearing.
    *   **`AudioService`:** Handles the capture of stereo audio, performs TDOA analysis for direction estimation, and provides audio buffers for transcription.
    *   **`VisualService`:** Manages the camera feed and uses the Vision framework for face detection and speaker identification. It also provides the visual context frames to the `GemmaASR` service.
    *   **`LocalizationService`:** Fuses data from audio, visual, and IMU sources to provide a single, robust estimate of the speaker's position.

### 2.4. Data / Platform Layer

*   **Framework:** Native code (Kotlin for Android, Swift for iOS).
*   **Responsibilities:**
    *   **MediaPipe Integration:** This is the core of the platform layer. It involves loading the Gemma 3n `.task` model and running inference using the MediaPipe Tasks library. This provides hardware-accelerated, optimized performance.
    *   **Hardware Abstraction:** Direct interaction with the device's hardware, including the microphone array (via `AVAudioEngine` or `AudioRecord`) and the camera (`CameraX` or `AVCaptureSession`).
    *   **Platform Channels/FFI:** Exposes the native functionalities (like MediaPipe inference) to the Dart Service Layer.

---

## 3. Core Data Flow: From Sound and Sight to Caption

1.  **Audio & Video Capture (Platform Layer):** The `AudioService` and `VisualService` initiate audio and video capture on the native side.
2.  **Direction Estimation (Service Layer):** The `AudioService` receives stereo buffers and uses TDOA (Task 3) to calculate a rough directional angle of the sound source.
3.  **Visual Context (Service Layer):** The `VisualService` provides the current camera frame to the `GemmaASR` service to act as visual context.
4.  **Multimodal ASR (Service/Platform Layer):** The mono audio stream and the visual context frame are passed to the `GemmaASR` service. It sends both over a platform channel to the native MediaPipe backend, which performs a fused multimodal inference for streaming transcription (Task 4 & 5).
5.  **Visual Identification (Service/Platform Layer):** Simultaneously, the `VisualService` analyzes the camera feed to identify the active speaker's face (Task 6).
6.  **Localization Fusion (Service Layer):** The `LocalizationService` takes the audio angle, the visual position of the speaker's face, and the device's IMU data, and uses a Kalman filter to produce a stable 3D position for the speaker (Task 11).
7.  **State Update (Business Logic Layer):** The services report the transcription and the speaker's 3D position to the relevant Cubits.
8.  **AR Anchor Creation (Service/Platform Layer):** The `ARAnchorManager` creates an `ARAnchor` at the fused 3D position (Task 7).
9.  **UI Rendering (Presentation Layer):** The UI listens to the state changes and renders a 2D or 3D caption at the appropriate location, attached to the newly created anchor (Tasks 8 & 9).

---

## 4. Key Design Decisions

*   **Native Inference with MediaPipe:** Instead of using a pure Dart TFLite interpreter, we are using the official Google MediaPipe Tasks library on the native side.
    *   **Rationale:** MediaPipe is highly optimized for running Google's models (like Gemma) on mobile devices. It provides access to hardware acceleration (GPU, NNAPI, CoreML) that is difficult to achieve with a generic Dart library, resulting in significantly better performance and lower battery consumption.
*   **Cubit for State Management:** We favor the simpler Cubit pattern over the more verbose BLoC pattern for most state management.
    *   **Rationale:** Cubit provides a straightforward way to manage state with less boilerplate, which is sufficient for most of our UI needs. BLoC is reserved for more complex scenarios with intricate event-to-state logic.
*   **Modular PRD-Driven Development:** The project is broken down into 14 distinct, manageable tasks, each with its own detailed PRD.
    *   **Rationale:** This approach provides extreme clarity for both human and AI developers, ensuring that every component is built to a clear specification. It also allows for parallel development and easier testing.

---

## 5. Conclusion

This architecture is designed to be robust, performant, and scalable. By leveraging the power of native MediaPipe for inference and maintaining a clean separation of concerns through a layered approach, we can deliver a high-quality, real-time AR captioning experience. The PRD-driven workflow ensures that development is focused and aligned with the project's core goals.

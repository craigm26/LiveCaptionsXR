# LiveCaptionsXR Architecture

## Overview
LiveCaptionsXR is a cross-platform AR captioning system that fuses audio, vision, and IMU data for robust, real-time, privacy-preserving speech transcription and AR caption placement. The architecture is modular, extensible, and production-ready for both iOS (ARKit) and Android (ARCore).

## Key Components

### Dart (Flutter) Layer
- **Services:** A collection of Dart services that encapsulate the business logic and communication with the native layer.
  - `ARAnchorManager`: Manages the lifecycle of AR anchors.
  - `HybridLocalizationEngine`: Manages the fusion of sensor data to determine speaker location.
  - `SpeechProcessor`: Processes the audio stream and sends it to the ASR engine.
  - `StereoAudioCapture`: Captures stereo audio from the device's microphones.
  - `WhisperService`: On-device speech-to-text processing using Whisper GGML with real-time event emission.
  - `Gemma3nService`: Contextual enhancement and multimodal inference using Gemma 3n with real-time event emission.
  - `ModelDownloadManager`: Unified model management for both Whisper and Gemma models.
  
- **UI:** The user interface of the application, built with Flutter.
- **State Management:** Cubit is used for state management with event-driven AR session states.

### AR Session State Machine
The AR session follows a sophisticated state machine that provides real-time feedback for the two-stage processing pipeline:

#### AR Session States
- `ARSessionInitial`: Default state when no AR session is active
- `ARSessionInitializing`: AR session is being initialized
- `ARSessionConfiguring`: AR session configuration and calibration
- `ARSessionStartingServices`: Starting all AR-related services with progress tracking
- `ARSessionSTTProcessing`: **Stage 1** - Speech-to-Text processing with real backend progress
- `ARSessionContextualEnhancement`: **Stage 2** - Gemma 3n contextual enhancement with real backend progress
- `ARSessionReady`: AR session is ready for full operation
- `ARSessionError`: Error state with detailed error information
- `ARSessionStopping`: AR session is being stopped
- `ARSessionPaused`: AR session is paused (e.g., app backgrounded)
- `ARSessionResuming`: AR session is resuming from paused state
- `ARSessionTrackingLost`: AR tracking has been lost
- `ARSessionReconnecting`: Attempting to reconnect AR session

#### Two-Stage Processing Pipeline
1. **Stage 1: Speech-to-Text (STT)**
   - **Backend**: Whisper GGML (on-device)
   - **Progress Events**: Initialization, model download, transcription progress
   - **State**: `ARSessionSTTProcessing` with real-time progress updates

2. **Stage 2: Contextual Enhancement**
   - **Backend**: Gemma 3n multimodal model
   - **Progress Events**: Model loading, enhancement processing, multimodal inference
   - **State**: `ARSessionContextualEnhancement` with real-time progress updates

### Event-Driven Integration
The system uses event streams to provide real-time feedback:

#### Whisper STT Events (`WhisperSTTEvent`)
- Service initialization progress
- Model download and availability checking
- Audio processing and transcription progress
- Error handling and recovery

#### Gemma 3n Enhancement Events (`Gemma3nEnhancementEvent`)
- Service initialization and model loading
- Text enhancement processing
- Multimodal inference with image context
- Caching and performance optimization

#### AR Session Event Wiring
- `ARSessionCubit` listens to both Whisper and Gemma 3n event streams
- Real-time state emission based on service progress
- Proper cleanup and resource management
- Error handling with detailed error codes

### Native Layer (iOS/Android)
- **HybridLocalizationEngine:** Fuses audio direction, visual detection, and IMU orientation using a Kalman filter. Exposed to Dart via MethodChannel for prediction, update, and fused transform retrieval.
- **ARKit/ARCore Plugins:** Native plugins for AR anchor management, visual object detection, and caption placement.
- **Streaming ASR:** On-device, low-latency speech recognition using the `whisper_ggml` package with the base model for fast, private processing.

## End-to-End Pipeline
1. **AR Session Initialization:** User enters AR mode, triggering session initialization with real-time progress feedback.
2. **Service Startup:** All AR services are started sequentially with progress tracking via `ARSessionStartingServices`.
3. **Stage 1 - STT Processing:** Whisper service initializes, downloads models if needed, and begins real-time transcription with `ARSessionSTTProcessing` states.
4. **Stage 2 - Contextual Enhancement:** Gemma 3n service enhances transcriptions with contextual information using `ARSessionContextualEnhancement` states.
5. **Audio & Vision Capture:** Stereo audio is captured in real-time. When needed, a visual snapshot is captured from the camera.
6. **Direction Estimation:** Audio direction is estimated using RMS and GCC-PHAT; visual speaker identification is optionally used.
7. **Hybrid Localization Fusion:** The HybridLocalizationEngine fuses all modalities to estimate the 3D world position of the speaker.
8. **AR Caption Placement:** When a final enhanced transcript is available, the fused transform and caption are sent to the native AR view, which anchors the caption in 3D space at the speaker's location.

## Model Management
The system includes a unified model management system:

### ModelDownloadManager
- **Supported Models**: Whisper (various sizes) and Gemma 3n models
- **Download Progress**: Real-time progress tracking for each model
- **Status Management**: Download, error, and completion states
- **UI Integration**: Model status page for user management

### Model Types
- **Whisper Models**: `whisper-base`, `whisper-small`, `whisper-medium`, `whisper-large`
- **Gemma Models**: `gemma-3n-E4B-it-int4` (multimodal enhancement)

## Dart-Native Communication
Communication between the Dart and native layers is handled via MethodChannels.

- `live_captions_xr/ar_navigation`: Used to initiate and manage the transition from the Flutter UI to the native AR view.
- `live_captions_xr/ar_anchor_methods`: Manages the lifecycle of AR anchors.
- `live_captions_xr/caption_methods`: The primary channel for sending finalized text and the corresponding 3D transform to the native layer for rendering AR captions.
- `live_captions_xr/hybrid_localization_methods`: Facilitates communication between the Dart layer and the native Hybrid Localization Engine.
- `live_captions_xr/visual_object_methods`: Sends information about visually detected objects (e.g., faces) from the native AR view back to the Dart application logic.
- `live_captions_xr/audio_capture_methods`: Manages the capture of stereo audio.
- `live_captions_xr/audio_capture_events`: An event channel that streams audio data from the native layer to the Dart layer.

## State Management Architecture
The application uses a layered state management approach:

### Cubit Pattern
- **ARSessionCubit**: Manages the complete AR session lifecycle and state machine
- **LiveCaptionsCubit**: Manages live caption display and history
- **SettingsCubit**: Manages user preferences and configuration
- **Service Cubits**: Individual service state management (SoundDetection, Localization, etc.)

### Event Streams
- **Service Events**: Whisper and Gemma 3n services emit progress events
- **State Synchronization**: ARSessionCubit listens to service events and emits corresponding states
- **UI Updates**: ARSessionStatusWidget displays real-time progress and status

## Extensibility
- Modular plugin architecture for adding new sensors, models, or AR features.
- Event-driven architecture for real-time progress feedback.
- Unified model management system for easy model additions.
- Testable, production-grade code with clear separation of concerns.
- Two-stage pipeline design allows for easy addition of new processing stages.

## Performance Considerations
- **On-Device Processing**: All AI processing happens on-device for privacy and low latency
- **Model Optimization**: Quantized models (int4) for efficient inference
- **Caching**: Gemma 3n service includes enhancement caching for repeated phrases
- **Background Processing**: Non-blocking event streams for smooth UI updates
- **Resource Management**: Proper cleanup of event subscriptions and model resources

---
See [README.md](README.md), [docs/](docs/), and [prd/](prd/) for more details.

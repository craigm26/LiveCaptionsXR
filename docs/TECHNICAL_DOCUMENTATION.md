# LiveCaptionsXR Technical Documentation

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [AR Session State Machine](#ar-session-state-machine)
3. [Speech Processing Pipeline](#speech-processing-pipeline)
4. [Model Management](#model-management)
5. [Audio Processing](#audio-processing)
6. [AR Integration](#ar-integration)
7. [Logging System](#logging-system)
8. [Performance Optimization](#performance-optimization)
9. [Testing & Debugging](#testing--debugging)
10. [Build & Deployment](#build--deployment)

---

## Architecture Overview

LiveCaptionsXR is a cross-platform AR captioning system that fuses audio, vision, and IMU data for robust, real-time, privacy-preserving speech transcription and AR caption placement. The architecture is modular, extensible, and production-ready for both iOS (ARKit) and Android (ARCore).

### Key Components

#### Dart (Flutter) Layer
- **Services:** A collection of Dart services that encapsulate the business logic and communication with the native layer.
  - `ARAnchorManager`: Manages the lifecycle of AR anchors.
  - `HybridLocalizationEngine`: Manages the fusion of sensor data to determine speaker location.
  - `SpeechProcessor`: Processes the audio stream and sends it to the ASR engine.
  - `StereoAudioCapture`: Captures stereo audio from the device's microphones.
  - `WhisperService`: On-device speech-to-text processing using Whisper GGML with real-time event emission.
  - `AppleSpeechService`: iOS-native speech-to-text using Apple's Speech Recognition framework with offline support.
  - `Gemma3nService`: Contextual enhancement and multimodal inference using Gemma 3n with real-time event emission.
  - `ModelDownloadManager`: Unified model management for both Whisper and Gemma models.
  - `ARFrameService`: iOS-specific service for capturing visual frames from ARKit sessions for multimodal context.
  
- **UI:** The user interface of the application, built with Flutter.
- **State Management:** Cubit is used for state management with event-driven AR session states.

#### Native Layer (iOS/Android)
- **HybridLocalizationEngine:** Fuses audio direction, visual detection, and IMU orientation using a Kalman filter. Exposed to Dart via MethodChannel for prediction, update, and fused transform retrieval.
- **ARKit/ARCore Plugins:** Native plugins for AR anchor management, visual object detection, and caption placement.
- **Streaming ASR:** On-device, low-latency speech recognition using the `whisper_ggml` package with the base model for fast, private processing.

### Dart-Native Communication
Communication between the Dart and native layers is handled via MethodChannels.

- `live_captions_xr/ar_navigation`: Used to initiate and manage the transition from the Flutter UI to the native AR view.
- `live_captions_xr/ar_anchor_methods`: Manages the lifecycle of AR anchors.
- `live_captions_xr/caption_methods`: The primary channel for sending finalized text and the corresponding 3D transform to the native layer for rendering AR captions.
- `live_captions_xr/hybrid_localization_methods`: Facilitates communication between the Dart layer and the native Hybrid Localization Engine.
- `live_captions_xr/visual_object_methods`: Sends information about visually detected objects (e.g., faces) from the native AR view back to the Dart application logic.
- `live_captions_xr/audio_capture_methods`: Manages the capture of stereo audio.
- `live_captions_xr/audio_capture_events`: An event channel that streams audio data from the native layer to the Dart layer.
- `live_captions_xr/ar_frames`: iOS-specific channel for capturing ARKit frame data for visual context enhancement.

---

## AR Session State Machine

The AR session follows a sophisticated state machine that provides real-time feedback for the two-stage processing pipeline:

### AR Session States
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

### Two-Stage Processing Pipeline
1. **Stage 1: Speech-to-Text (STT)**
   - **Backend**: Whisper GGML (on-device)
   - **Progress Events**: Initialization, model download, transcription progress
   - **State**: `ARSessionSTTProcessing` with real-time progress updates

2. **Stage 2: Contextual Enhancement**
   - **Backend**: Gemma 3n multimodal model
   - **Progress Events**: Model loading, enhancement processing, multimodal inference
   - **State**: `ARSessionContextualEnhancement` with real-time progress updates

### Platform-Specific STT Engines
- **iOS**: Uses `AppleSpeechService` (Apple Speech Recognition framework) for native integration
- **Android**: Uses `WhisperService` (Whisper GGML) for on-device processing
- **Web**: Falls back to `flutter_sound` for compatibility

### Event-Driven Integration
The system uses event streams to provide real-time feedback:

#### STT Service Events
**Whisper STT Events (`WhisperSTTEvent`)**
- Service initialization progress
- Model download and availability checking
- Audio processing and transcription progress
- Error handling and recovery

**Apple Speech Events (`AppleSpeechEvent`)**
- iOS Speech Recognition initialization
- Real-time transcription with partial and final results
- Offline mode support and configuration
- Permission and availability checking

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

### State Management Architecture
The application uses a layered state management approach:

#### Cubit Pattern
- **ARSessionCubit**: Manages the complete AR session lifecycle and state machine
- **LiveCaptionsCubit**: Manages live caption display and history
- **SettingsCubit**: Manages user preferences and configuration
- **Service Cubits**: Individual service state management (SoundDetection, Localization, etc.)

#### Event Streams
- **Service Events**: Whisper and Gemma 3n services emit progress events
- **State Synchronization**: ARSessionCubit listens to service events and emits corresponding states
- **UI Updates**: ARSessionStatusWidget displays real-time progress and status

---

## Speech Processing Pipeline

### End-to-End Pipeline
1. **AR Session Initialization:** User enters AR mode, triggering session initialization with real-time progress feedback.
2. **Service Startup:** All AR services are started sequentially with progress tracking via `ARSessionStartingServices`.
3. **Stage 1 - STT Processing:** Whisper service initializes, downloads models if needed, and begins real-time transcription with `ARSessionSTTProcessing` states.
4. **Stage 2 - Contextual Enhancement:** Gemma 3n service enhances transcriptions with contextual information using `ARSessionContextualEnhancement` states.
5. **Audio & Vision Capture:** Stereo audio is captured in real-time. When needed, a visual snapshot is captured from the camera.
6. **Direction Estimation:** Audio direction is estimated using RMS and GCC-PHAT; visual speaker identification is optionally used.
7. **Hybrid Localization Fusion:** The HybridLocalizationEngine fuses all modalities to estimate the 3D world position of the speaker.
8. **AR Caption Placement:** When a final enhanced transcript is available, the fused transform and caption are sent to the native AR view, which anchors the caption in 3D space at the speaker's location.

### Speech Processing Flow

#### Audio Capture
- **Stereo Audio**: Captured using device microphones for directional analysis
- **Real-time Processing**: Audio streams are processed in real-time for low latency
- **Format Conversion**: Audio is converted to WAV format for Whisper processing

#### STT Engine Integration

**Whisper GGML Integration (Android)**
- **Model**: Uses `whisper-base.bin` (147.95 MB) for optimal speed/accuracy balance
- **Processing**: Real-time transcription with 4 threads
- **Language**: English (configurable)
- **Timestamps**: Disabled for real-time processing
- **Audio Format**: WAV (auto-converted)

**Apple Speech Integration (iOS)**
- **Framework**: Native iOS Speech Recognition framework
- **Processing**: Real-time transcription with partial and final results
- **Language**: Configurable locale support (English default)
- **Offline Mode**: Supports offline transcription with `onDevice: true`
- **Permissions**: Requires microphone and speech recognition permissions
- **Features**: Auto-punctuation, haptic feedback, confidence scoring

**ARKit Frame Capture (iOS)**
- **Service**: `ARFrameService` - Captures visual frames from ARKit sessions
- **Method Channel**: `live_captions_xr/ar_frames` for frame capture communication
- **Processing**: Real-time CVPixelBuffer to JPEG conversion for Gemma 3n
- **Integration**: Seamlessly integrates with `EnhancedSpeechProcessor` on iOS
- **Format**: Returns JPEG image data as Uint8List for multimodal processing
- **Native Implementation**: Uses `ARViewController.captureCurrentARFrame()` method
- **Error Handling**: Graceful fallback to text-only enhancement if capture fails

#### Gemma 3n Enhancement
- **Model**: `gemma-3n-E4B-it-int4` for multimodal enhancement
- **Function**: Enhances raw transcriptions with punctuation, corrections, and context
- **Caching**: Implements enhancement caching for repeated phrases
- **Multimodal**: Supports image context for enhanced understanding

### Visual Context System

#### Platform-Specific Implementation
- **iOS**: Uses `ARFrameService` to capture frames from active ARKit sessions
- **Android**: Uses `CameraService` for periodic frame capture from device camera
- **Integration**: Both services provide visual context to `EnhancedSpeechProcessor`

#### ARFrameService (iOS)
```dart
// Service for capturing ARKit frames
class ARFrameService {
  Future<Uint8List?> captureFrame() async {
    // Captures current ARKit frame via method channel
    // Returns JPEG data for Gemma 3n processing
  }
}
```

#### CameraService (Android)
```dart
// Service for camera frame capture
class CameraService {
  Stream<List<int>> get frameStream => _frameStreamController.stream;
  Future<List<int>?> captureFrame() async {
    // Captures frame from device camera
    // Returns image data for processing
  }
}
```

#### Visual Processing Pipeline
1. **Frame Capture**: Platform-specific frame acquisition
2. **Format Conversion**: Convert to Gemma 3n compatible format (JPEG/PNG)
3. **Context Integration**: Combine visual data with speech transcription
4. **Enhancement**: Use multimodal Gemma 3n for contextual speech enhancement

### Speech Debug Guide

#### Common Issues
1. **Stream Type Errors**: Ensure proper stream controller usage
2. **Model Download Failures**: Check network connectivity and storage space
3. **Audio Processing Errors**: Verify microphone permissions
4. **AR Session Crashes**: Check device compatibility and AR framework support

#### Debug Logging
- Enable debug logging overlay in settings
- Monitor AR session state transitions
- Check service initialization logs
- Verify event stream connections

---

## Model Management

The system includes a unified model management system:

### ModelDownloadManager
- **Supported Models**: Whisper (various sizes) and Gemma 3n models
- **Download Progress**: Real-time progress tracking for each model
- **Status Management**: Download, error, and completion states
- **UI Integration**: Model status page for user management

### Model Types
- **Whisper Models**: `whisper-base` (speech recognition - Android)
- **Apple Speech**: Native iOS Speech Recognition (no model download required)
- **Gemma Models**: `gemma-3n-E4B-it-int4` (multimodal enhancement)

### Model Setup

#### Whisper Setup
- **Model File**: `whisper_base.bin` (147.95 MB)
- **Status**: ✅ Ready for use
- **Location**: `assets/models/whisper_base.bin`
- **Configuration**: Optimized for real-time processing

#### Apple Speech Setup (iOS)
- **Service**: `AppleSpeechService` - iOS native Speech Recognition framework
- **Status**: ✅ Ready for use
- **Location**: `lib/core/services/apple_speech_service.dart`
- **Configuration**: Offline support, real-time partial/final results, auto-punctuation
- **Permissions**: Configured in `ios/Runner/Info.plist` (Speech Recognition + Microphone)
- **Dependencies**: `speech_to_text: ^6.6.0`

#### Gemma 3n Setup
- **Model File**: `gemma-3n-E4B-it-int4.task` (4.1 GB)
- **Status**: ✅ Ready for use
- **Configuration**: Quantized for efficient inference

---

## Audio Processing

### On-Device Audio Capture
- **Stereo Recording**: Captures audio from multiple microphones
- **Real-time Processing**: Processes audio streams without buffering
- **Direction Estimation**: Uses RMS and GCC-PHAT algorithms
- **Noise Reduction**: Implements basic noise filtering

### Audio Direction Estimation

#### Basic Audio Direction Estimation
- **RMS Analysis**: Root Mean Square analysis for audio level detection
- **GCC-PHAT**: Generalized Cross Correlation with Phase Transform
- **Confidence Scoring**: Provides confidence levels for direction estimates
- **Real-time Updates**: Updates direction estimates continuously

#### Advanced Audio Localization
- **Multi-microphone Array**: Utilizes device microphone array
- **Frequency Analysis**: Analyzes different frequency bands
- **Environmental Adaptation**: Adapts to different acoustic environments
- **Fusion with Visual Data**: Combines audio and visual localization

### Hybrid Localization Strategy
- **Sensor Fusion**: Combines audio, visual, and IMU data
- **Kalman Filter**: Uses Kalman filtering for smooth position estimates
- **Confidence Weighting**: Weights different sensor inputs by confidence
- **Real-time Updates**: Provides continuous position updates

---

## AR Integration

### ARKit/ARCore Integration
- **Cross-platform Support**: Works on both iOS (ARKit) and Android (ARCore)
- **Anchor Management**: Creates and manages AR anchors for caption placement
- **Tracking**: Maintains spatial tracking for stable caption positioning
- **Session Management**: Handles AR session lifecycle

### Anchor Creation
- **Automatic Placement**: Automatically places anchors at speaker locations
- **Manual Override**: Allows manual anchor placement if needed
- **Persistence**: Anchors persist across AR session restarts
- **Validation**: Validates anchor placement and tracking

### Caption Rendering

#### 2D Caption Rendering
- **Text Rendering**: Renders captions as 2D text overlays
- **Positioning**: Positions captions based on speaker location
- **Styling**: Applies consistent styling and formatting
- **Accessibility**: Includes accessibility features for screen readers

#### 3D Caption Rendering
- **3D Text**: Renders captions as 3D text in AR space
- **Spatial Anchoring**: Anchors captions to 3D world coordinates
- **Occlusion**: Handles occlusion with real-world objects
- **Animation**: Smooth animations for caption appearance/disappearance

### IMU Orientation Integration
- **Device Orientation**: Tracks device orientation changes
- **Spatial Alignment**: Aligns captions with device orientation
- **Stability**: Maintains caption stability during device movement
- **Calibration**: Calibrates orientation sensors for accuracy

---

## Logging System

LiveCaptionsXR implements a comprehensive, configurable logging system designed to provide detailed debugging information while maintaining performance in production.

### Architecture

#### Core Components
- **AppLogger**: Central logging service with category-based filtering
- **LogConfigManager**: Persistent configuration management
- **LogCategory**: Categorized logging for different system components
- **LogLevel**: Hierarchical log levels (debug, info, warning, error)

#### Log Categories
```dart
enum LogCategory {
  audio('🎵 AUDIO'),      // Audio capture and processing
  gemma('🤖 GEMMA'),      // Gemma 3n AI service 
  ar('📱 AR'),            // AR/ARKit functionality
  captions('📋 CAPTIONS'), // Caption display and management
  camera('📷 CAMERA'),     // Camera and frame capture
  speech('🎤 SPEECH'),     // Speech recognition engines
  ui('🖥️ UI'),            // User interface events
  system('⚙️ SYSTEM');     // System-level operations
}
```

### Configuration

#### Development Mode
```dart
AppLogger.instance.configure(const LogConfig(
  globalLevel: LogLevel.debug,
  enableConsoleOutput: true,
));
```

#### Production Mode
```dart
AppLogger.instance.configure(LogConfigManager.minimalConfig);
// Reduces noise from AI and audio processing
```

#### Custom Configuration
```dart
AppLogger.instance.configure(const LogConfig(
  globalLevel: LogLevel.info,
  categoryLevels: {
    LogCategory.gemma: LogLevel.warning,    // Reduce AI logs
    LogCategory.audio: LogLevel.warning,    // Reduce audio logs
    LogCategory.ar: LogLevel.debug,         // Detailed AR logs
    LogCategory.captions: LogLevel.info,    // Caption events
  },
  enableConsoleOutput: true,
));
```

### Usage

#### In Services
```dart
class ExampleService {
  final AppLogger _logger = AppLogger.instance;
  
  void processData() {
    _logger.i('Processing started', category: LogCategory.system);
    _logger.d('Debug details', category: LogCategory.system);
    _logger.w('Warning message', category: LogCategory.system);
    _logger.e('Error occurred', category: LogCategory.system, error: e);
  }
}
```

#### Quick Configuration Changes
```dart
// Enable detailed Gemma and AR logging for debugging
AppLogger.instance.setCategoryLevel(LogCategory.gemma, LogLevel.debug);
AppLogger.instance.setCategoryLevel(LogCategory.ar, LogLevel.debug);
```

### Benefits
- **Performance**: Category-based filtering prevents expensive log operations
- **Debugging**: Granular control over what gets logged
- **Production Ready**: Automatic log reduction in release builds
- **Persistent**: Configuration survives app restarts
- **Maintainable**: Centralized logging configuration

---

## Performance Optimization

### On-Device Processing
- **Privacy**: All processing happens on-device
- **Latency**: Minimizes latency for real-time experience
- **Battery**: Optimized for battery efficiency
- **Storage**: Efficient model storage and management

### Model Optimization
- **Quantization**: Uses quantized models (int4) for efficiency
- **Caching**: Implements enhancement caching for repeated phrases
- **Background Processing**: Non-blocking event streams for smooth UI
- **Resource Management**: Proper cleanup of subscriptions and resources

### Performance Considerations
- **Model Size**: Balances model size with accuracy
- **Processing Speed**: Optimizes for real-time processing
- **Memory Usage**: Efficient memory management
- **Battery Life**: Minimizes battery consumption

### ARKit Optimization
LiveCaptionsXR disables certain ARKit features to maximize performance for AI processing:

```swift
// Lighting features disabled for optimal performance with AI processing
// sceneView.automaticallyUpdatesLighting = true
// sceneView.autoenablesDefaultLighting = true
```

**Rationale:**
- **GPU Resources**: Frees GPU resources for Gemma 3n multimodal inference
- **CPU Resources**: Reduces CPU overhead from lighting calculations
- **Battery Life**: Improves battery efficiency during extended use
- **Trade-off**: Slightly less realistic lighting in favor of AI performance

---

## Testing & Debugging

### Testing AR Mode and Audio
- **Emulator Testing**: Test AR functionality in Android emulator
- **Real Device Testing**: Test on physical devices for full functionality
- **Audio Testing**: Verify audio capture and processing
- **AR Testing**: Test AR session lifecycle and anchor placement

### Accessibility Testing
- **Screen Reader Support**: Test with screen readers
- **Voice Control**: Test voice control functionality
- **High Contrast**: Test high contrast mode
- **Font Scaling**: Test font scaling accessibility

### Debug Logging
- **Debug Overlay**: Enable debug logging overlay in settings
- **Log Levels**: Configure log levels for different components
- **Error Tracking**: Track and log errors for debugging
- **Performance Monitoring**: Monitor performance metrics

---

## Build & Deployment

### iOS Build Fixes
- **ARKit Integration**: Fixed ARKit integration issues
- **Build Configuration**: Updated build configurations
- **Dependency Management**: Resolved dependency conflicts
- **Feature Restoration**: Restored missing features

### CI/CD Pipeline
- **Automated Testing**: Automated test suite
- **Build Automation**: Automated build process
- **Deployment**: Automated deployment pipeline
- **Quality Assurance**: Quality checks and validation

### Performance Optimization
- **Build Optimization**: Optimized build process
- **Asset Management**: Efficient asset management
- **Code Splitting**: Implemented code splitting
- **Caching**: Build and runtime caching

---

## Extensibility
- Modular plugin architecture for adding new sensors, models, or AR features.
- Event-driven architecture for real-time progress feedback.
- Unified model management system for easy model additions.
- Testable, production-grade code with clear separation of concerns.
- Two-stage pipeline design allows for easy addition of new processing stages.

---

*This documentation consolidates all technical details from the original scattered documentation files into a single, comprehensive reference.* 
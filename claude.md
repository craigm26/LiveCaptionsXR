# LiveCaptionsXR - Claude Code Context

## Project Overview

LiveCaptionsXR is an accessibility application providing real-time, spatially-aware closed captioning for people with hearing loss. Captions are anchored in 3D space at the speaker's location using AR technology.

**Core Value Proposition:** Privacy-first, 100% on-device AI processing with spatial awareness.

## Current Development Focus (Q1-Q2 2026)

### Priority 1: Nexa SDK Integration for Android
- **Goal:** NPU-accelerated on-device AI using Qualcomm Hexagon NPU
- **Services:** `NexaAsrService` (ASR) and `NexaLlmService` (LLM/VLM)
- **Key files:**
  - [nexa_asr_service.dart](lib/core/services/nexa_asr_service.dart) - Speech-to-text
  - [nexa_llm_service.dart](lib/core/services/nexa_llm_service.dart) - Text enhancement
  - [NexaAsrPlugin.kt](android/app/src/main/kotlin/com/livecaptionsxr/app/NexaAsrPlugin.kt) - Native NPU detection

### Priority 2: Android XR Platform
- **Target devices:** Samsung Galaxy XR headset, upcoming Samsung glasses
- **Key considerations:**
  - Optimize caption placement for head-mounted displays
  - Stereo audio spatial awareness in 3D environment
  - Battery efficiency for wearable form factor
  - ARCore integration for world-locked captions

### Priority 3: User Experience Excellence
- Seamless onboarding flow
- Real-time performance optimization
- Accessibility testing and refinement

## Architecture Overview

```
Audio Capture (16kHz stereo)
       ↓
Nexa ASR (NPU) / Whisper (fallback) → Speech-to-Text
       ↓
Nexa LLM / Gemma 3n → Text Enhancement
       ↓
Hybrid Localization (Kalman filter: audio + visual + IMU)
       ↓
ARCore → 3D Caption Placement
```

### Key Architectural Patterns

1. **Event-Driven Architecture** - Streams for real-time STT/LLM progress
2. **Platform-Specific Abstraction** - Abstract interfaces with platform implementations
3. **Graceful Fallback** - Nexa (NPU) → Whisper → Apple Speech
4. **Lazy Singleton DI** - `get_it` for service lifecycle
5. **State Machine Pattern** - AR session with multiple states
6. **Hybrid Sensor Fusion** - Kalman filter combining audio, visual, IMU

## Key Directories

```
lib/
├── core/
│   ├── services/          # All AI, audio, AR services
│   ├── models/            # Data models (SpeechResult, etc.)
│   ├── di/                # Dependency injection (service_locator.dart)
│   └── cubit/             # State management
├── features/
│   ├── ar_session/        # AR session management
│   ├── live_captions/     # Caption display
│   ├── settings/          # App settings
│   └── onboarding/        # User onboarding
└── shared/
    ├── widgets/           # Reusable UI components
    └── theme/             # App theming

android/app/src/main/kotlin/com/livecaptionsxr/app/
├── NexaAsrPlugin.kt       # Nexa NPU detection
├── HybridLocalizationEngine.kt
├── StereoAudioCapturePlugin.kt
└── VisualCaptureController.kt

docs/                      # Technical documentation
prd/                       # Product requirement documents
```

## Critical Services

| Service | Purpose | Platform |
|---------|---------|----------|
| `EnhancedSpeechProcessor` | Orchestrates STT pipeline | All |
| `NexaAsrService` | NPU-accelerated speech recognition | Android |
| `NexaLlmService` | NPU-accelerated text enhancement | Android |
| `WhisperService` | Fallback STT (Whisper GGML) | Android |
| `AppleSpeechService` | Native iOS speech recognition | iOS |
| `Gemma3nService` | Multimodal text enhancement | All |
| `HybridLocalizationEngine` | Kalman filter sensor fusion | All |
| `SpatialCaptionIntegrationService` | Caption-to-AR integration | All |

## Method Channels (Dart ↔ Native)

- `live_captions_xr/ar_navigation` - Launch native AR view
- `live_captions_xr/caption_methods` - Place captions in AR
- `live_captions_xr/hybrid_localization_methods` - Localization engine API
- `live_captions_xr/audio_capture_methods` - Stereo audio capture
- `live_captions_xr/audio_capture_events` - Audio data stream
- `live_captions_xr/nexa_asr` - Nexa ASR method channel

## Coding Conventions

### Dart/Flutter
- Use `flutter_bloc` with Cubit pattern for state management
- Register services in `service_locator.dart` using `get_it`
- Use streams (`StreamController`) for real-time data
- Follow platform-specific patterns: abstract interface → platform implementation
- Error handling: emit error states, use `AppLogger` for logging

### Kotlin (Android Native)
- Method channels for Dart ↔ Kotlin communication
- Use coroutines for async operations
- JNI for native library access (Nexa SDK, audio processing)

### Event Patterns
```dart
// STT events follow this pattern:
sealed class WhisperSTTEvent {}
class WhisperSTTProgress extends WhisperSTTEvent { ... }
class WhisperSTTComplete extends WhisperSTTEvent { ... }
class WhisperSTTError extends WhisperSTTEvent { ... }
```

## Testing Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/path/to/test.dart

# Build Android APK
flutter build apk --release

# Build for Android XR (same as standard Android)
flutter build apk --release --target-platform android-arm64
```

## Common Development Tasks

### Adding a New Service
1. Create interface in `lib/core/services/`
2. Implement platform-specific versions
3. Register in `service_locator.dart`
4. Inject via constructor or `GetIt.instance<T>()`

### Modifying Speech Processing Pipeline
1. Check `enhanced_speech_processor.dart` for orchestration
2. Update relevant service (Nexa/Whisper/Apple)
3. Ensure event streams maintain compatibility
4. Test fallback behavior

### Working with AR Captions
1. `ar_session_cubit.dart` manages session state
2. `spatial_caption_integration_service.dart` handles placement
3. Use method channels for native AR view communication

## Dependencies to Know

| Package | Version | Purpose |
|---------|---------|---------|
| `nexa_ai_flutter` | ^0.0.2 | Nexa SDK Flutter binding |
| `flutter_bloc` | ^9.1.1 | State management |
| `whisper_ggml` | 1.3.0 | On-device Whisper |
| `flutter_gemma` | ^0.10.0 | Gemma 3n integration |
| `get_it` | ^8.0.3 | Dependency injection |
| `camera` | ^0.10.5+9 | Camera access |
| `flutter_sound` | ^9.2.13 | Audio processing |
| `permission_handler` | ^11.3.1 | Device permissions |

## Android XR Considerations

When developing for Samsung Galaxy XR and glasses:

1. **Display Optimization**
   - Larger, more readable caption text for HMD viewing
   - Consider field of view constraints
   - World-locked vs head-locked caption modes

2. **Spatial Audio**
   - Leverage headset's spatial microphones
   - Enhanced 3D localization for immersive environment
   - Consider pass-through audio integration

3. **Performance**
   - Target 60+ FPS for comfortable XR experience
   - Optimize battery usage (NPU over GPU/CPU)
   - Minimize thermal throttling

4. **Interaction**
   - Voice commands for hands-free control
   - Gaze-based caption selection (future)
   - Controller/gesture support if available

## Documentation References

- [Architecture](docs/ARCHITECTURE.md) - System architecture
- [Nexa SDK Integration](docs/NEXA_SDK_INTEGRATION_ANALYSIS.md) - Nexa integration strategy
- [Samsung Galaxy XR Guide](docs/SAMSUNG_GALAXY_XR_CONSUMER_GUIDE.md) - XR user guide
- [Development Guide](DEVELOPMENT_GUIDE.md) - Setup and contribution
- [PRDs](prd/) - Product requirement documents

## Environment

- **Flutter:** 3.16.0+
- **Dart:** 3.2.0+
- **Android Min SDK:** 24 (Android 7.0)
- **iOS Deployment Target:** 11.0
- **Nexa SDK:** ai.nexa:core:0.0.19

## Quick Reference: File Locations

| What | Where |
|------|-------|
| App entry point | `lib/main.dart` |
| Service registration | `lib/core/di/service_locator.dart` |
| Speech processing | `lib/core/services/enhanced_speech_processor.dart` |
| Nexa ASR | `lib/core/services/nexa_asr_service.dart` |
| Nexa LLM | `lib/core/services/nexa_llm_service.dart` |
| AR session state | `lib/features/ar_session/cubit/ar_session_cubit.dart` |
| Android native plugins | `android/app/src/main/kotlin/com/livecaptionsxr/app/` |
| Build config | `android/app/build.gradle.kts` |
| Dependencies | `pubspec.yaml` |

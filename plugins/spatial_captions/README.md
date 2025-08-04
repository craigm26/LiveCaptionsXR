# Spatial Captions Plugin

A Flutter plugin for managing spatial captions in AR environments with advanced lifecycle management and positioning capabilities.

## Features

- **Caption Lifecycle Management**: Handles partial → final → enhanced caption transitions
- **Spatial Positioning**: Places captions in 3D space based on audio direction and visual cues
- **Speaker Tracking**: Manages captions by speaker ID for multi-speaker scenarios
- **AR Integration**: Seamless integration with ARKit for iOS
- **Landscape Orientation Lock**: Prevents UI issues in portrait mode
- **Automatic Cleanup**: Removes captions after configurable duration

## Usage

### Basic Setup

```dart
import 'package:spatial_captions/spatial_captions.dart';

// Initialize the plugin
final spatialCaptionsCubit = SpatialCaptionsCubit();

// Set landscape orientation lock
await spatialCaptionsCubit.setOrientationLock(true);

// Set caption duration
spatialCaptionsCubit.setCaptionDuration(Duration(seconds: 6));
```

### Adding Captions

```dart
// Add a partial caption
await spatialCaptionsCubit.addPartialCaption(
  text: "Hello, this is a",
  position: Vector3(0, 0, -2),
  speakerId: "speaker1",
  confidence: 0.8,
);

// Finalize the caption
await spatialCaptionsCubit.finalizeCaption(
  text: "Hello, this is a test caption",
  position: Vector3(0, 0, -2),
  speakerId: "speaker1",
  confidence: 0.95,
);

// Enhance with AI
await spatialCaptionsCubit.enhanceCaption(
  captionId: "caption_id",
  enhancedText: "Hello, this is an enhanced test caption",
);
```

### Integration with Speech Processing

```dart
// Process speech results
final integrationService = SpatialCaptionIntegrationService(
  spatialCaptionsCubit: spatialCaptionsCubit,
  speechLocalizer: speechLocalizer,
  gemmaService: gemmaService,
);

// Handle partial results
await integrationService.processPartialResult(speechResult);

// Handle final results
await integrationService.processFinalResult(speechResult);
```

## Architecture

### Components

1. **SpatialCaptions**: Main plugin API for native communication
2. **SpatialCaptionsCubit**: State management for caption lifecycle
3. **CaptionModel**: Data model for caption information
4. **SpatialCaptionIntegrationService**: Integration with existing speech processing

### Caption Types

- **Partial**: Real-time transcription results (orange styling)
- **Final**: Complete transcription results (blue styling)
- **Enhanced**: AI-enhanced versions (green styling)

### Positioning

Captions are positioned using:
- Audio direction from stereo microphones
- Speaker direction metadata
- Visual localization (when available)
- Default center placement as fallback

## iOS Implementation

The iOS implementation includes:
- ARKit integration for 3D caption placement
- Billboard constraints for readable text
- Smooth animations for caption transitions
- Automatic cleanup and memory management

## Demo

Use the Spatial Captions Demo page to test:
- Caption placement and positioning
- Lifecycle transitions
- Multi-speaker scenarios
- AR integration features

Access via navigation drawer or floating action button on the home screen. 
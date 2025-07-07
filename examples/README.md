# Enhanced Speech Processing Examples

This directory contains examples demonstrating the new enhanced speech processing capabilities in LiveCaptionsXR.

## Overview

The examples showcase the following improvements:
- **Configurable Voice Activity Detection Thresholds**
- **Multi-language Support with Language Detection** 
- **Real-time Text Enhancement using Gemma 3**
- **Dynamic Configuration Updates**

## Files

### enhanced_speech_processing_example.dart

A comprehensive Flutter widget that demonstrates:

1. **Interactive UI Controls**:
   - Voice activity threshold slider (0.005 - 0.05 range)
   - Start/Stop processing buttons
   - Real-time text enhancement
   - Configuration preset buttons

2. **Real-time Speech Results Display**:
   - Current transcribed text
   - Language detection notifications
   - Confidence scores and timestamps
   - Visual indicators for interim vs final results

3. **Configuration Examples**:
   - Conference transcription (high accuracy)
   - Gaming commands (low latency)
   - Customer support (multilingual)

## Usage

To integrate the enhanced speech processing into your app:

```dart
import 'examples/enhanced_speech_processing_example.dart';

// Use the complete widget
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: EnhancedSpeechExample(),
    );
  }
}
```

Or use the individual example patterns:

```dart
// High-accuracy scenario
await SpeechProcessingExamples.conferenceTranscription();

// Low-latency scenario
await SpeechProcessingExamples.gamingCommands();

// Multilingual scenario
await SpeechProcessingExamples.customerSupport();
```

## Key Features Demonstrated

### 1. Configurable Thresholds

```dart
// Adjust voice activity detection sensitivity
final config = SpeechConfig(
  voiceActivityThreshold: 0.02, // Higher = less sensitive
  finalResultThreshold: 0.01,   // Threshold for final results
);
```

### 2. Language Detection

```dart
// Enable automatic language detection
const config = SpeechConfig(
  enableLanguageDetection: true,
  supportedLanguages: ['en', 'es', 'fr', 'de', 'zh'],
);

// Listen for language changes
processor.speechResults.listen((result) {
  if (result.isLanguageDetection) {
    print('Language detected: ${result.detectedLanguage}');
  }
});
```

### 3. Real-time Enhancement

```dart
// Enhance transcribed text with context
final enhanced = await processor.enhanceText(
  'raw transcription text',
  context: 'meeting discussion',
  speakerDirection: 'front-left',
);
```

### 4. Dynamic Configuration

```dart
// Update configuration at runtime
await processor.updateConfig(
  processor.config.copyWith(
    voiceActivityThreshold: 0.015,
    language: 'fr',
  ),
);
```

## Configuration Presets

Three optimized presets are available:

### Low Latency
- **Use case**: Gaming, VR commands, real-time interaction
- **Characteristics**: Fast response, minimal processing delay
- **Trade-offs**: Potentially lower accuracy

```dart
await processor.initialize(config: SpeechConfig.lowLatency);
```

### High Accuracy
- **Use case**: Conference transcription, documentation, subtitles
- **Characteristics**: Maximum transcription quality
- **Trade-offs**: Higher latency, more processing

```dart
await processor.initialize(config: SpeechConfig.highAccuracy);
```

### Multilingual
- **Use case**: International meetings, customer support, travel
- **Characteristics**: Language detection, multi-language support
- **Trade-offs**: Additional processing for language detection

```dart
await processor.initialize(config: SpeechConfig.multilingual);
```

## Testing the Examples

The examples include comprehensive error handling and fallbacks:

1. **Model Loading**: Graceful handling of model loading failures
2. **Audio Permissions**: Proper handling of microphone permissions
3. **Network Issues**: Fallback behavior for connectivity problems
4. **Invalid Configurations**: Validation and default value handling

## Integration Notes

- All examples maintain backward compatibility with existing code
- The examples can be copied and modified for specific use cases
- Configuration objects are immutable and use the builder pattern
- All async operations include proper error handling

## Performance Considerations

The examples demonstrate performance best practices:

- **Memory Management**: Proper buffer cleanup and size limits
- **Threading**: UI updates on main thread, processing on background
- **Battery Optimization**: Configurable processing intervals
- **Resource Cleanup**: Proper disposal of resources

## Next Steps

These examples provide a foundation for:
1. Integration with actual Gemma 3 ASR when available
2. Custom configuration profiles for specific applications
3. Advanced language detection and switching scenarios
4. Performance optimization for specific hardware targets
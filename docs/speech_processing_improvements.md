# Speech Processing Improvements

This document outlines the enhanced speech processing capabilities implemented in LiveCaptionsXR.

## Overview

The speech processing system has been significantly enhanced with the following improvements:

1. **Configurable Voice Activity Detection Thresholds**
2. **Multi-language Support with Language Detection**
3. **Real-time Text Enhancement using Gemma 3**
4. **Preparatory Framework for Gemma 3 ASR Integration**

## Key Components

### SpeechConfig

A comprehensive configuration system for speech processing parameters:

```dart
const config = SpeechConfig(
  voiceActivityThreshold: 0.01,      // Configurable VAD threshold
  finalResultThreshold: 0.005,       // Threshold for final results
  language: 'en',                    // Primary language
  enableLanguageDetection: true,     // Auto-detect language
  enableRealTimeEnhancement: true,   // Use Gemma 3 for text enhancement
  supportedLanguages: ['en', 'es', 'fr', 'de', 'it', 'pt', 'zh'],
);
```

### Preset Configurations

Three optimized presets are available:

- **`SpeechConfig.lowLatency`**: Optimized for minimal delay
- **`SpeechConfig.highAccuracy`**: Optimized for transcription quality
- **`SpeechConfig.multilingual`**: Optimized for multi-language scenarios

### Language Detection Service

Automated language detection from both audio and text:

```dart
// Detect language from audio buffer
final audioDetection = await LanguageDetectionService.detectLanguage(
  audioBuffer, 
  config
);

// Detect language from transcribed text
final textDetection = await LanguageDetectionService.detectLanguageFromText(
  "Hello world", 
  config
);
```

### Enhanced Speech Processor

The `SpeechProcessor` now supports:

- **Dynamic Configuration Updates**: Change thresholds and settings at runtime
- **Language-Aware Text Enhancement**: Context-aware improvements using Gemma 3
- **Real-time Language Detection**: Automatic language switching
- **Enhanced Metadata**: Rich speech result information

## Usage Examples

### Basic Setup with Custom Configuration

```dart
final processor = SpeechProcessor();

// Initialize with custom config
await processor.initialize(
  config: const SpeechConfig(
    voiceActivityThreshold: 0.02,
    language: 'es',
    enableLanguageDetection: true,
  ),
);

// Start processing
await processor.startProcessing();
```

### Dynamic Configuration Updates

```dart
// Update configuration during runtime
await processor.updateConfig(
  processor.config.copyWith(
    voiceActivityThreshold: 0.015,
    language: 'fr',
  ),
);
```

### Enhanced Text Processing

```dart
// Enhance transcribed text with context
final enhanced = await processor.enhanceText(
  'raw transcription text',
  context: 'meeting discussion',
  speakerDirection: 'front-left',
);
```

### Language Detection Results

```dart
processor.speechResults.listen((result) {
  if (result.isLanguageDetection) {
    print('Language detected: ${result.detectedLanguage}');
    print('Confidence: ${result.languageConfidence}');
  } else if (result.hasActualSpeech) {
    print('Speech: ${result.text}');
  }
});
```

## Implementation Details

### Swift Plugin Enhancements

The iOS plugin (`Gemma3nMultimodalPlugin.swift`) now supports:

- **Configurable Thresholds**: Voice activity and final result thresholds
- **Dynamic Language Support**: Language-specific simulated results
- **Enhanced Metadata**: Rich speech result information
- **Configuration Updates**: Runtime parameter updates

Key methods added:
- `updateSpeechConfig()`: Update processing parameters
- `getASRCapabilities()`: Query plugin capabilities
- `generateSimulatedSpeechText()`: Language-aware simulation

### Dart Service Improvements

The Dart services provide:

- **Comprehensive Configuration Management**: Type-safe configuration system
- **Language Detection**: Multi-modal language identification
- **Text Enhancement**: Context-aware improvements
- **Statistics and Monitoring**: Runtime performance metrics

## Future Integration Points

### Gemma 3 ASR Integration

The framework is prepared for actual Gemma 3 ASR integration:

1. **Replace Simulation**: Current simulated results can be replaced with actual ASR
2. **Maintain Interface**: All existing APIs will continue to work
3. **Enhanced Capabilities**: Real ASR will provide better accuracy and features

### Planned Enhancements

1. **Real-time Streaming ASR**: Direct Gemma 3 audio processing
2. **Advanced Language Models**: Specialized models for different languages
3. **Speaker Identification**: Multi-speaker scenarios
4. **Contextual Understanding**: Scene and conversation context

## Testing

Comprehensive tests cover:

- **Configuration Management**: All SpeechConfig functionality
- **Language Detection**: Audio and text-based detection
- **Speech Processing**: Enhanced processor capabilities
- **Edge Cases**: Error handling and fallback scenarios

Run tests with:
```bash
dart test test/core/models/speech_config_test.dart
dart test test/core/services/language_detection_service_test.dart
dart test test/core/services/enhanced_speech_processor_test.dart
```

## Performance Considerations

- **Adaptive Buffering**: Dynamic buffer sizing based on configuration
- **Efficient Language Detection**: Optimized pattern matching and AI-based detection
- **Memory Management**: Controlled buffer sizes and cleanup
- **Threading**: Proper main thread dispatch for UI updates

## Backward Compatibility

All changes maintain backward compatibility:
- Existing APIs continue to work with default configurations
- Optional parameters preserve existing behavior
- Legacy code requires no modifications
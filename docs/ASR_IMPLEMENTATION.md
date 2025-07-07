# ASR Implementation Guide

## Overview

This document describes the hybrid ASR (Automatic Speech Recognition) implementation for the LiveCaptionsXR project. The implementation addresses the issue where MediaPipe iOS doesn't fully support direct audio input API yet, by providing a fallback to native platform speech recognition.

## Architecture

### Hybrid Approach

The implementation uses a hybrid approach:

1. **Primary**: Native platform speech recognition (iOS Speech framework, Android SpeechRecognizer)
2. **Secondary**: Gemma 3n enhancement for improved accuracy and context
3. **Fallback**: Text prompt bridge when native ASR is unavailable

### iOS Implementation

#### Key Components

- **SFSpeechRecognizer**: Apple's speech recognition framework
- **AVAudioEngine**: Audio processing and buffer management
- **Gemma 3n Enhancement**: Post-processing for improved accuracy

#### Implementation Details

```swift
// Initialize Speech Recognition
private func initializeSpeechRecognition() {
    speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: currentLanguage))
    speechRecognizer?.delegate = self
    
    SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
        switch authStatus {
        case .authorized:
            self?.isSpeechRecognitionAvailable = true
        case .denied, .restricted, .notDetermined:
            self?.isSpeechRecognitionAvailable = false
        @unknown default:
            self?.isSpeechRecognitionAvailable = false
        }
    }
}
```

#### Speech Recognition Flow

1. Audio buffer is converted to PCM format
2. SFSpeechAudioBufferRecognitionRequest is created
3. Recognition task processes the audio
4. Results are enhanced using Gemma 3n if available
5. Final transcription is returned

### Android Implementation

#### Key Components

- **SpeechRecognizer**: Android's speech recognition API
- **RecognitionListener**: Handles speech recognition events
- **Gemma 3n Enhancement**: Post-processing for improved accuracy

#### Implementation Details

```kotlin
private fun initializeSpeechRecognition() {
    applicationContext?.let { context ->
        if (SpeechRecognizer.isRecognitionAvailable(context)) {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
            isSpeechRecognitionAvailable = true
        }
        
        // Check permissions
        val hasPermission = ContextCompat.checkSelfPermission(
            context, 
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
        
        if (!hasPermission) {
            isSpeechRecognitionAvailable = false
        }
    }
}
```

## Configuration Options

### Speech Recognition Settings

- `useNativeSpeechRecognition`: Enable/disable native platform ASR
- `enableRealTimeEnhancement`: Enable Gemma 3n enhancement
- `currentLanguage`: Target language for recognition
- `voiceActivityThreshold`: Threshold for voice activity detection
- `finalResultThreshold`: Threshold for final result confidence

### Language Support

Supported languages include:
- English (`en`)
- Spanish (`es`)
- French (`fr`)
- German (`de`)
- Italian (`it`)
- Portuguese (`pt`)
- Chinese (`zh`)
- Japanese (`ja`)
- Korean (`ko`)
- Arabic (`ar`)

## Permissions Required

### iOS (Info.plist)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for audio capture and speech processing.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Speech recognition is used to convert speech to text for live captions.</string>
```

### Android (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

## API Usage

### Dart/Flutter Side

```dart
// Initialize speech processor
await speechProcessor.initialize(
  config: SpeechConfig(
    language: 'en',
    enableRealTimeEnhancement: true,
    useNativeSpeechRecognition: true,
  ),
);

// Start listening for speech
speechProcessor.speechResults.listen((result) {
  if (result.isFinal && result.text.trim().isNotEmpty) {
    // Process final transcription
    handleFinalTranscription(result.text);
  } else {
    // Handle interim results
    handleInterimTranscription(result.text);
  }
});
```

### Native Method Calls

```dart
// Transcribe audio directly
final result = await methodChannel.invokeMethod('transcribeAudio', {
  'audio': audioBytes,
  'isFinal': true,
});
```

## Error Handling

### Common Error Scenarios

1. **Speech Recognition Not Available**
   - Fallback to bridge implementation
   - Log warning and continue with reduced functionality

2. **Permissions Denied**
   - Graceful degradation to text-only mode
   - User notification about missing permissions

3. **Audio Processing Errors**
   - Retry with different audio format
   - Fallback to previous transcription method

### Error Recovery

```swift
// iOS Error Recovery
private func performGemma3nASR(audioBuffer: [Float], isFinal: Bool) throws -> String {
    if useNativeSpeechRecognition && isSpeechRecognitionAvailable {
        do {
            return try performNativeSpeechRecognition(audioBuffer: audioBuffer, isFinal: isFinal)
        } catch {
            print("Native ASR failed, falling back to bridge: \(error)")
            return try performBridgeASR(audioBuffer: audioBuffer, isFinal: isFinal)
        }
    } else {
        return try performBridgeASR(audioBuffer: audioBuffer, isFinal: isFinal)
    }
}
```

## Performance Considerations

### Optimization Strategies

1. **Audio Buffer Management**
   - Limit buffer size to prevent memory issues
   - Efficient audio format conversion

2. **Recognition Timeout**
   - Set reasonable timeouts for speech recognition
   - Implement cancellation for long-running tasks

3. **Gemma 3n Enhancement**
   - Optional enhancement to balance accuracy vs. performance
   - Configurable temperature and token limits

### Memory Management

- Audio buffers are automatically trimmed when exceeding limits
- Recognition tasks are properly cancelled and cleaned up
- Session management prevents memory leaks

## Testing

### Unit Tests

The implementation includes comprehensive unit tests covering:

- Audio transcription with valid input
- Final vs. interim transcription modes
- Silent audio detection
- Error handling for missing arguments
- Configuration validation
- Multi-language support

### Integration Tests

- End-to-end speech recognition pipeline
- Platform-specific behavior validation
- Permission handling
- Error recovery scenarios

## Migration from Bridge Implementation

### Before (Bridge Implementation)

```swift
// Old bridge approach
let transcriptionPrompt = buildTranscriptionPrompt(isFinal: isFinal)
try session.addQueryChunk(inputText: transcriptionPrompt)
let response = try session.generateResponse()
return cleanTranscriptionResponse(response)
```

### After (Hybrid Implementation)

```swift
// New hybrid approach
if useNativeSpeechRecognition && isSpeechRecognitionAvailable {
    return try performNativeSpeechRecognition(audioBuffer: audioBuffer, isFinal: isFinal)
} else {
    return try performBridgeASR(audioBuffer: audioBuffer, isFinal: isFinal)
}
```

## Future Improvements

### When MediaPipe Audio API becomes available

1. Replace bridge implementation with direct audio input:
   ```swift
   // Future MediaPipe implementation
   try session.addQueryChunk(audioData: processedAudio)
   ```

2. Maintain hybrid approach for compatibility
3. Add configuration option to choose ASR backend

### Planned Enhancements

- Real-time streaming ASR with partial results
- Voice activity detection improvements
- Multi-speaker recognition
- Custom acoustic models
- Noise reduction preprocessing

## Troubleshooting

### Common Issues

1. **"Speech recognition not available"**
   - Check device language settings
   - Verify internet connection (some platforms require it)
   - Ensure proper permissions

2. **"Model not loaded" errors**
   - Verify Gemma 3n model is properly bundled
   - Check model file path and accessibility
   - Validate model format compatibility

3. **Audio format issues**
   - Ensure 16kHz mono PCM format
   - Check audio buffer size and timing
   - Validate audio data integrity

### Debug Logging

Enable comprehensive logging to track ASR pipeline:

```swift
print("✅ iOS Speech Recognition initialized for language: \(currentLanguage)")
print("🎤 Processing audio buffer: \(audioBuffer.count) samples")
print("📝 Transcription result: \(result)")
```

This implementation provides a robust, production-ready ASR solution that bridges the gap until MediaPipe's direct audio input API becomes available on iOS.
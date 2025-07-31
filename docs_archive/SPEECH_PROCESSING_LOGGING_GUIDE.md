# Speech Processing Logging Guide - LiveCaptionsXR

## Overview

This document describes the comprehensive logging system that has been added to the speech processing pipeline in LiveCaptionsXR. The logging provides detailed visibility into every step of the speech detection, transcription, and caption generation process.

## Logging Architecture

### Emoji-Based Log Categories

The logging system uses emojis to categorize different types of events:

- 🎤 **Audio Capture & Processing**: Microphone input, audio chunks, processing
- 🎵 **Audio Data**: Raw audio chunks, byte conversion, data flow
- 📊 **Audio Metrics**: RMS levels, audio quality, performance metrics
- 🗣️ **Speech Detection**: Voice activity detection, speech triggers
- 🔄 **Processing & Conversion**: Data transformation, format conversion
- 📝 **Transcription Results**: Whisper output, text generation
- 📋 **Caption Processing**: Caption creation, enhancement, management
- 📚 **Caption History**: Caption storage, history management
- 🎯 **AR Placement**: 3D positioning, anchor creation
- 📤 **Stream Emission**: Data flow between components
- ✅ **Success Operations**: Successful completions
- ❌ **Error Conditions**: Failures, exceptions, issues
- ⚠️ **Warnings**: Non-critical issues, fallbacks
- 👂 **Event Listeners**: Stream subscriptions, event handling
- 🤖 **AI Services**: Gemma 3n, Whisper service interactions
- 🚀 **Service Startup**: Initialization, service launches

## Complete Speech Processing Log Flow

### 1. Audio Capture Phase

```
🎤 Starting audio capture...
📊 Configuring audio streamer with 16kHz sample rate
🎵 Audio chunk #1 received (1024 samples)
📊 Audio levels - RMS: 0.0123
🗣️ Potential speech detected (RMS: 0.0123)
📤 Sent audio chunk to stream (1024 samples)
```

### 2. Speech Processing Phase

```
🎤 Starting Whisper GGML processing...
🎵 Received audio chunk (1024 samples)
🔄 Converting audio to bytes (4096 bytes)
🎤 Sending audio to Whisper for transcription...
📝 Whisper transcription result: "Hello world" (confidence: 0.8)
```

### 3. Whisper Service Processing

```
🎵 Processing audio buffer (4096 bytes)
💾 Saved audio to temp file: /tmp/whisper_audio_1234567890.wav
🎤 Sending transcription request to Whisper GGML...
📝 Whisper GGML response received: "Hello world"
🗑️ Cleaned up temp audio file
📝 Whisper result: "Hello world" (confidence: 0.8)
📤 Emitted speech result to stream
```

### 4. Caption Processing Phase

```
🔄 Processing speech result: "Hello world" (final: true)
📤 Emitted raw speech result to stream
📝 Using raw speech result (enhancement disabled or unavailable)
📋 Created basic caption: "Hello world"
```

### 5. Live Captions Management

```
📋 Received enhanced caption: "Hello world" (final: true, enhanced: false)
📚 Added final caption to history (1 total)
🎯 Placing caption in AR space: "Hello world"
📤 Emitted updated state with 1 captions
```

### 6. AR Placement Phase

```
🎯 Placing real-time caption in AR: "Hello world"
🔄 Requesting fused transform from hybrid localization...
✅ Fused transform retrieved successfully - length: 16
✅ Real-time caption placed successfully.
```

## Service-Specific Logging

### AudioCaptureService

**Key Log Events:**
- `🎤 Starting audio capture...` - Service initialization
- `🎵 Audio chunk #N received (X samples)` - Audio data reception
- `📊 Audio levels - RMS: X.XXXX` - Audio level monitoring
- `🗣️ Potential speech detected (RMS: X.XXXX)` - Speech activity detection
- `📤 Sent audio chunk to stream (X samples)` - Data forwarding

**Error Conditions:**
- `❌ Failed to start audio capture` - Initialization failures
- `❌ Error in audio stream` - Stream processing errors

### WhisperService

**Key Log Events:**
- `🎵 Processing audio buffer (X bytes)` - Audio processing start
- `💾 Saved audio to temp file: /path/to/file.wav` - File operations
- `🎤 Sending transcription request to Whisper GGML...` - API calls
- `📝 Whisper GGML response received: "text"` - Transcription results
- `🗑️ Cleaned up temp audio file` - Resource cleanup
- `📝 Whisper result: "text" (confidence: X.X)` - Final results
- `📤 Emitted speech result to stream` - Data emission

**Error Conditions:**
- `❌ Error processing audio with Whisper` - Processing failures
- `⚠️ Whisper not initialized, returning fallback result` - Service not ready

### EnhancedSpeechProcessor

**Key Log Events:**
- `🎤 Starting Whisper GGML processing...` - Processing initialization
- `🎵 Received audio chunk (X samples)` - Audio reception
- `🔄 Converting audio to bytes (X bytes)` - Data conversion
- `🎤 Sending audio to Whisper for transcription...` - Service calls
- `📝 Whisper transcription result: "text" (confidence: X.X)` - Results
- `🔄 Processing speech result: "text" (final: X)` - Result processing
- `📤 Emitted raw speech result to stream` - Data flow

**Error Conditions:**
- `❌ Error processing audio chunk` - Processing failures
- `❌ Error in audio stream` - Stream errors

### LiveCaptionsCubit

**Key Log Events:**
- `📋 Received enhanced caption: "text" (final: X, enhanced: X)` - Caption reception
- `📚 Added final caption to history (X total)` - History management
- `🎯 Placing caption in AR space: "text"` - AR placement
- `📤 Emitted updated state with X captions` - State updates
- `⏳ Processing partial caption: "text"` - Partial results

### HybridLocalizationEngine

**Key Log Events:**
- `🎯 Placing real-time caption in AR: "text"` - Placement initiation
- `🔄 Requesting fused transform from hybrid localization...` - Transform requests
- `✅ Fused transform retrieved successfully - length: 16` - Transform success
- `✅ Real-time caption placed successfully.` - Placement completion

**Error Conditions:**
- `❌ Platform error placing real-time caption: message` - Placement failures

## AR Session Integration Logging

### Service Setup

```
🎤 Retrieved Whisper service from service locator
🤖 Retrieved Gemma 3n service from service locator
👂 Setting up Whisper STT event listener...
✅ Whisper STT event listener configured
👂 Setting up Gemma 3n enhancement event listener...
✅ Gemma 3n enhancement event listener configured
🚀 Starting all AR services through ARSessionCubit...
✅ All AR services started successfully
```

### Service Lifecycle

```
🎤 Starting live captions for AR mode...
✅ Live captions started for AR mode
🔊 Starting sound detection for AR mode...
✅ Sound detection started for AR mode
🧭 Starting localization for AR mode...
✅ Localization started for AR mode
👁️ Starting visual identification for AR mode...
✅ Visual identification started for AR mode
```

## Debugging Common Issues

### No Speech Detection

**Look for these logs:**
1. `🎤 Starting audio capture...` - Audio service started
2. `🎵 Audio chunk #1 received (X samples)` - Audio data flowing
3. `📊 Audio levels - RMS: X.XXXX` - Audio levels (should be > 0.01 for speech)
4. `🗣️ Potential speech detected` - Speech activity detected

**If missing:**
- Check microphone permissions
- Verify audio capture service is running
- Check device audio input settings

### No Transcription Results

**Look for these logs:**
1. `🎤 Sending audio to Whisper for transcription...` - Audio sent to Whisper
2. `📝 Whisper transcription result: "text"` - Transcription completed
3. `📝 Whisper result: "text" (confidence: X.X)` - Result processed

**If missing:**
- Check Whisper service initialization
- Verify model files are available
- Check audio format compatibility

### No Captions Displayed

**Look for these logs:**
1. `📋 Received enhanced caption: "text"` - Caption received
2. `📚 Added final caption to history` - Caption stored
3. `🎯 Placing caption in AR space: "text"` - AR placement initiated
4. `✅ Real-time caption placed successfully.` - Placement completed

**If missing:**
- Check LiveCaptionsCubit state
- Verify AR session is active
- Check HybridLocalizationEngine status

### Model Download Issues

**Look for these logs:**
1. `📥 Model not found or incomplete, downloading: whisper-base` - Download started
2. `📁 Created Whisper model file: ggml-base.bin` - File created
3. `✅ Model download completed successfully` - Download success

**If missing:**
- Check network connectivity
- Verify storage space
- Check model file permissions

## Performance Monitoring

### Audio Processing Metrics

- **Audio Chunk Frequency**: Look for `🎵 Audio chunk #N` logs
- **Processing Latency**: Time between audio reception and transcription
- **Audio Quality**: Monitor RMS levels in `📊 Audio levels - RMS: X.XXXX`

### Speech Recognition Metrics

- **Transcription Accuracy**: Monitor confidence levels in `📝 Whisper result: "text" (confidence: X.X)`
- **Processing Speed**: Time between `🎤 Sending audio to Whisper` and `📝 Whisper result`
- **Error Rates**: Count of `❌ Error processing audio with Whisper` logs

### Caption Generation Metrics

- **Caption Frequency**: Count of `📋 Received enhanced caption` logs
- **AR Placement Success**: Ratio of `✅ Real-time caption placed successfully` to placement attempts
- **State Updates**: Frequency of `📤 Emitted updated state with X captions` logs

## Testing the Logging System

Run the comprehensive logging test to verify all logging patterns:

```bash
flutter test test/speech_processing_logging_test.dart
```

This test verifies:
- All expected log patterns are defined
- Emoji categorization is consistent
- Log flow structure is complete
- Error conditions are properly logged

## Best Practices

1. **Monitor Log Flow**: Follow the complete log flow from audio capture to AR placement
2. **Check Error Patterns**: Look for repeated error patterns that indicate systemic issues
3. **Performance Monitoring**: Use RMS levels and processing times to identify bottlenecks
4. **State Verification**: Ensure all services are in the expected states before troubleshooting
5. **Model Validation**: Verify model files are properly downloaded and accessible

## Conclusion

This comprehensive logging system provides complete visibility into the speech processing pipeline, making it easy to debug issues with speech detection, transcription, and caption generation. The emoji-based categorization makes it simple to filter and understand different types of events, while the detailed flow tracking helps identify exactly where issues occur in the processing chain. 
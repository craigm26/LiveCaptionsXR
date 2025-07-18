# Speech Processing Flow - LiveCaptionsXR

## Overview
This document explains how speech is captured and processed in the LiveCaptionsXR application.

## Architecture Overview

### Key Components
1. **StereoAudioCapturePlugin** (iOS Native) - Captures stereo audio from microphones
2. **StereoAudioCapture** (Dart) - Dart wrapper for native audio capture
3. **LiveCaptionsCubit** - Manages the connection between audio capture and speech processing
4. **EnhancedSpeechProcessor** - Processes audio for speech recognition using the `whisper_ggml` package with the base model for fast, private processing.

## Complete Audio Flow

### 1. Audio Capture Initialization
```
User starts AR mode → LiveCaptionsCubit.startCaptions() → StereoAudioCapture.startRecording()
```

**Native iOS (StereoAudioCapturePlugin.swift):**
- Configures AVAudioSession with `.playAndRecord` category
- Sets up AVAudioEngine with input node
- Installs audio tap with 16kHz sample rate, 2 channels, Float32 format
- Buffers audio in 1024 frame chunks

**Dart (StereoAudioCapture.dart):**
- Receives interleaved Float32 audio data via EventChannel
- Separates left and right channels
- Calculates RMS levels for monitoring
- Emits `StereoAudioFrame` objects

### 2. Audio Processing Pipeline
```
StereoAudioFrame → LiveCaptionsCubit → processAudioChunk() → SpeechProcessor
```

**LiveCaptionsCubit:**
- Subscribes to audio frames from `StereoAudioCapture`
- Sends audio chunks to `SpeechProcessor.startProcessing()`

**EnhancedSpeechProcessor:**
- Initializes the `whisper_ggml` plugin with the base model.
- Starts listening for speech with real-time processing.
- Receives speech results from the `whisper_ggml` plugin.

### 3. Speech Recognition
```
Audio stream → whisper_ggml plugin → Whisper Base Model → Speech results
```

**`whisper_ggml` Plugin:**
- Handles on-device speech recognition using the Whisper base model.
- Provides fast, private, offline speech recognition with ~3-5 second processing delay.
- Processes audio in real-time with configurable parameters.

### 4. Caption Placement
```
Final speech result → LiveCaptionsCubit → HybridLocalizationEngine → AR space
```

**Caption Flow:**
- Final speech results trigger AR caption placement
- Uses `HybridLocalizationEngine` to determine 3D position
- Places caption in AR space at estimated speaker location

## Logging and Debugging

### What You Should See in Logs

#### Audio Capture Phase:
```
[INFO] 🎧 Starting stereo audio capture
[DEBUG] Target format: 16kHz, 2 channels, Float32, interleaved
[INFO] ✅ Stereo audio capture started successfully
```

#### Speech Processing Phase:
```
[INFO] 🎤 Starting speech processing...
```

#### Speech Recognition Results:
```
[INFO] 🎤 Speech result received: "Hello world"
```

#### AR Caption Placement:
```
[INFO] 🎯 Attempting to place caption in AR space...
[DEBUG] Caption text: "Hello world" (11 characters)
[DEBUG] 🔄 Requesting fused transform from hybrid localization...
[INFO] ✅ Caption placed successfully in AR space at estimated speaker location
```

## Troubleshooting

### No Audio Capture
If you see this log pattern:
```
[INFO] 🎧 Starting stereo audio capture
[ERROR] ❌ Failed to start stereo audio capture
```
**Cause:** Microphone permissions not granted or audio session configuration failed
**Solution:** Check iOS permissions and audio session setup

### Audio Capture Working But No Speech Results
If you see:
```
[INFO] 🎤 Starting speech processing...
```
but no "🎤 Speech result received" logs, the cause is likely with the `whisper_ggml` plugin.
**Solution:** Check the Whisper model initialization and audio format compatibility.

### No AR Caption Placement
If you see:
```
[INFO] ✅ Final speech result: "Hello world"
[ERROR] ❌ Failed to place caption in AR
```
**Cause:** This indicates a failure in the final stage of the pipeline. The issue could be:
*   **AR Session Inactive:** The ARKit/ARCore session is not running or has been interrupted.
*   **Hybrid Localization Failure:** The `HybridLocalizationEngine` is not providing a valid 3D position for the speaker, possibly due to a lack of sensor data.
*   **AR Anchor Creation Failed:** The `ARAnchorManager` could be failing to create an anchor at the position provided by the localization engine.

**Solution:**
1.  Verify the AR session is active and world-tracking is stable.
2.  Check logs from the `HybridLocalizationEngine` to ensure it's receiving sensor data and outputting a fused transform.
3.  Inspect the `ARAnchorManager` logs to see if it's receiving the transform and attempting to place an anchor.

## Testing

Use the provided `test/features/live_captions/speech_processor_test.dart` script to verify the speech processing pipeline:

```bash
flutter test test/features/live_captions/speech_processor_test.dart
```

This will test each component in isolation and verify the complete flow from audio capture to speech recognition.

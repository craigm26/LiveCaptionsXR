# Speech Processing Flow - LiveCaptionsXR

## Overview
This document explains how speech is captured and processed in the LiveCaptionsXR application, addressing the issue where the user couldn't understand what was being captured for speech recognition.

## Architecture Overview

### Key Components
1. **StereoAudioCapturePlugin** (iOS Native) - Captures stereo audio from microphones
2. **StereoAudioCapture** (Dart) - Dart wrapper for native audio capture
3. **LiveCaptionsCubit** - Manages the connection between audio capture and speech processing
4. **SpeechProcessor** - Processes audio for speech recognition using Gemma 3n
5. **Gemma3nMultimodalPlugin** (iOS Native) - Native implementation of Gemma 3n ASR

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
- Converts stereo to mono using `toMono()` method
- Calculates RMS levels for voice activity detection
- Sends mono audio chunks to `SpeechProcessor.processAudioChunk()`

**SpeechProcessor:**
- Receives Float32List audio chunks
- Calculates voice activity using RMS threshold
- Sends audio to native plugin via MethodChannel
- Receives speech results via EventChannel

### 3. Speech Recognition
```
Audio chunk → Gemma3nMultimodalPlugin → iOS Speech Recognition / Gemma 3n ASR → Speech results
```

**Gemma3nMultimodalPlugin (iOS):**
- Accumulates audio chunks in internal buffer
- Performs voice activity detection
- Uses iOS Speech Recognition for transcription
- Enhances results with Gemma 3n if available
- Sends both interim and final results back to Dart

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
[DEBUG] 📊 Audio frame #50: 1024 samples (512 per channel)
[DEBUG] 🎧 Audio levels - Left: 0.0124, Right: 0.0098
```

#### Speech Processing Phase:
```
[INFO] 🎤 Starting speech processing...
[DEBUG] 🔧 Audio capture config: sampleRate=16000, channels=1, format=pcm16
[DEBUG] 🌍 Language: en
[DEBUG] 🎯 Voice activity threshold: 0.01
[DEBUG] 📊 Processing audio chunk: 512 samples
[DEBUG] 🔊 Audio RMS level: 0.0156 (threshold: 0.01)
[DEBUG] 🎯 Voice activity detected, sending to ASR...
```

#### Speech Recognition Results:
```
[INFO] 📥 Received stream data: speechResult
[INFO] 🎤 Speech result received: "Hello world"
[DEBUG] 📊 Confidence: 0.87, Final: false
[DEBUG] 🔄 Interim speech result: "Hello world"
[INFO] ✅ Final speech result: "Hello world"
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
[DEBUG] 📊 Audio frame #50: 1024 samples, RMS: 0.0156
[DEBUG] 🔇 Below voice activity threshold, skipping ASR
```
**Cause:** Audio levels too low or voice activity threshold too high
**Solution:** Adjust `voiceActivityThreshold` in speech configuration

### Speech Recognition Not Working
If you see:
```
[DEBUG] 🎯 Voice activity detected, sending to ASR...
[ERROR] ❌ Error processing audio chunk
```
**Cause:** Gemma 3n model not loaded or native plugin issues
**Solution:** Check model loading and native plugin initialization

### No AR Caption Placement
If you see:
```
[INFO] ✅ Final speech result: "Hello world"
[ERROR] ❌ Failed to place caption in AR
```
**Cause:** AR session not active or hybrid localization engine not initialized
**Solution:** Ensure AR mode is properly initialized before starting captions

## Configuration Options

### Audio Configuration
- **Sample Rate:** 16kHz (optimal for speech recognition)
- **Channels:** 2 (stereo) → 1 (mono for speech processing)
- **Format:** Float32 (±1.0 range)
- **Buffer Size:** 1024 frames (~64ms at 16kHz)

### Speech Recognition Configuration
- **Voice Activity Threshold:** 0.01 (adjustable)
- **Language:** "en" (configurable)
- **Real-time Enhancement:** true (uses Gemma 3n)
- **Native Speech Recognition:** true (uses iOS Speech Recognition)

### Performance Monitoring
- **Audio Frame Rate:** ~15.6 fps (1024 samples / 16kHz)
- **Speech Result Latency:** <100ms for interim results
- **Caption Placement Latency:** <50ms after final result

## Testing

Use the provided `test_speech_flow.dart` script to verify the complete pipeline:

```bash
dart test_speech_flow.dart
```

This will test each component in isolation and verify the complete flow from audio capture to speech recognition.
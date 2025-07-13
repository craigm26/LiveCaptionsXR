# Speech Processing Debug Guide

## Quick Debugging Steps

### 1. Check Audio Capture
Look for these logs after entering AR mode:
```
[INFO] 🎧 Starting stereo audio capture
[INFO] ✅ Stereo audio capture started successfully
```

**If missing:** Audio permissions or hardware issue

### 2. Check Speech Processor Connection
Look for these logs:
```
[INFO] 🎤 Starting speech processing...
```

**If missing:** Audio not reaching speech processor

### 3. Check Speech Recognition Results
Look for:
```
[INFO] 🎤 Speech result received: "Hello world"
```

**If missing:** `speech_to_text` plugin or engine issue

### 4. Check AR Caption Placement
Look for:
```
[INFO] 🎯 Attempting to place caption in AR space...
[INFO] ✅ Caption placed successfully in AR space
```

**If missing:** AR session or localization issue

## Log Level Configuration

Enable debug logging in your app settings:
1. Go to Settings → Developer & Testing
2. Enable "Debug Logging Overlay"
3. Set log level to "Debug" or "Verbose"

## Common Issues and Solutions

### Issue: No audio frames captured
**Symptoms:** No "🎧 Starting stereo audio capture" logs
**Solution:** Check microphone permissions

### Issue: Audio captured but no speech processing
**Symptoms:** "🎧 Starting stereo audio capture" logs but no "🎤 Starting speech processing..."
**Solution:** Check if LiveCaptionsCubit properly connects audio to speech processor

### Issue: Speech processing but no recognition results
**Symptoms:** "🎤 Starting speech processing..." but no "🎤 Speech result received"
**Solution:** Check the `speech_to_text` plugin initialization and device's speech recognition service.

### Issue: Recognition results but no AR captions
**Symptoms:** "🎤 Speech result received" but no "🎯 Attempting to place caption"
**Solution:** Check AR session state and hybrid localization engine

## Testing Commands

Run the speech flow test:
```bash
flutter test test/features/live_captions/speech_processor_test.dart
```

Check debug logs in real-time:
```bash
# If using iOS Simulator
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.example.livecaptions"'
```

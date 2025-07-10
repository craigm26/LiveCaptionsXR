# Speech Processing Debug Guide

## Quick Debugging Steps

### 1. Check Audio Capture
Look for these logs after entering AR mode:
```
[INFO] 🎧 Starting stereo audio capture
[INFO] ✅ Stereo audio capture started successfully
[DEBUG] 📊 Audio frame #50: 1024 samples, RMS: 0.0156
```

**If missing:** Audio permissions or hardware issue

### 2. Check Speech Processor Connection
Look for these logs:
```
[INFO] 🎤 Starting speech processing...
[DEBUG] 📊 Processing audio chunk: 512 samples
[DEBUG] 🔊 Audio RMS level: 0.0156 (threshold: 0.01)
```

**If missing:** Audio not reaching speech processor

### 3. Check Voice Activity Detection
Look for:
```
[DEBUG] 🎯 Voice activity detected, sending to ASR...
```

**If seeing:** `🔇 Below voice activity threshold, skipping ASR`
**Solution:** Speak louder or adjust threshold

### 4. Check Speech Recognition Results
Look for:
```
[INFO] 📥 Received stream data: speechResult
[INFO] 🎤 Speech result received: "Hello world"
```

**If missing:** Native plugin or model issue

### 5. Check AR Caption Placement
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
**Symptoms:** No "📊 Audio frame" logs
**Solution:** Check microphone permissions

### Issue: Audio captured but no speech processing
**Symptoms:** "📊 Audio frame" logs but no "🎤 Processing audio chunk"
**Solution:** Check if LiveCaptionsCubit properly connects audio to speech processor

### Issue: Speech processing but no recognition results
**Symptoms:** "🎤 Processing audio chunk" but no "📥 Received stream data"
**Solution:** Check Gemma 3n model loading and native plugin

### Issue: Recognition results but no AR captions
**Symptoms:** "🎤 Speech result received" but no "🎯 Attempting to place caption"
**Solution:** Check AR session state and hybrid localization engine

## Testing Commands

Run the speech flow test:
```bash
dart test_speech_flow.dart
```

Check debug logs in real-time:
```bash
# If using iOS Simulator
xcrun simctl spawn booted log stream --predicate 'subsystem == "com.example.livecaptions"'
```
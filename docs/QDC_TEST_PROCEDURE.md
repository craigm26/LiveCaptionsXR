# QDC/Qualcomm Device Test Procedure

## Prerequisites

1. QDC device with Snapdragon chipset (8 Gen 2 or newer recommended)
2. Debug APK built with Nexa SDK integration
3. USB debugging enabled on device
4. ADB connected and verified

## Setup

### 1. Install Debug APK

```bash
# Build debug APK
flutter build apk --debug

# Install on device
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### 2. Verify NPU Availability

```bash
# Check for Hexagon DSP
adb shell cat /sys/class/kgsl/kgsl-3d0/gpu_model
adb shell getprop ro.hardware.chipname
```

### 3. Enable Logging

```bash
# Start logcat filtering for app
adb logcat -s LiveCaptionsXR:* NexaSDK:*
```

## Test Execution

### Test 1: Basic ASR (5 min)

1. Launch app
2. Grant microphone permission
3. Speak test sentences clearly:
   - "Hello, this is a test of the live caption system."
   - "The quick brown fox jumps over the lazy dog."
   - "Testing one two three four five."
4. Verify captions appear within 500ms
5. Note accuracy of transcription

**Pass criteria:** >90% accuracy, <500ms latency

### Test 2: NPU vs CPU Comparison (10 min)

1. In settings, force CPU mode (if available)
2. Run Test 1, note latency and battery
3. Switch to NPU mode
4. Run Test 1 again, note latency and battery
5. Compare results

**Pass criteria:** NPU shows measurable improvement

### Test 3: Extended Use (30 min)

1. Note battery percentage
2. Run continuous transcription for 30 minutes
3. Monitor for crashes, memory leaks, thermal throttling
4. Note ending battery percentage

**Pass criteria:** <5% battery drain, no crashes, stable memory

### Test 4: AR Mode (if applicable)

1. Connect XR glasses
2. Enable AR caption mode
3. Verify captions appear in AR view
4. Test head tracking / caption positioning
5. Walk around, verify stability

**Pass criteria:** Captions visible and stable in AR

## Recording Results

1. Fill out `QDC_DEVICE_TESTING.md` with measurements
2. Save logcat output: `adb logcat -d > test-results/YYYY-MM-DD-device.log`
3. Screenshot any errors or notable behavior
4. Commit results to repo

## Troubleshooting

### NPU not detected
- Verify device has compatible Snapdragon chipset
- Check Nexa SDK is properly integrated
- Review logcat for initialization errors

### High latency
- Check if thermal throttling is occurring
- Verify model is running on NPU not CPU
- Try smaller model variant

### Crashes
- Capture full stack trace from logcat
- Note exact steps to reproduce
- File issue with details

# Installing LiveCaptionsXR on Android XR Devices

LiveCaptionsXR runs on Android XR headsets (Samsung Galaxy XR, Qualcomm reference devices, etc.) with **two installation paths** and **multiple AI configurations** depending on your hardware. This guide covers every scenario.

---

## Quick Decision Guide

| **How you install** | **AI Engine** | **Best for** | **Privacy** |
|---|---|---|---|
| Google Play Store | Whisper + Gemma (on-device) | Most users, consumer headsets | ✅ Fully on-device |
| Sideloaded APK (GitHub Release) | Nexa NPU + Parakeet ASR | Qualcomm Snapdragon devices with NPU | ✅ Fully on-device, hardware-accelerated |

Both versions are **fully on-device** — no audio leaves your headset. The difference is *which* AI models run and *how fast* they run.

---

## Option 1: Google Play Store (Recommended for Most Users)

### What you get
- **Speech-to-text:** Whisper GGML (optimized for CPU/GPU)
- **Text enhancement:** Gemma 3n (punctuation, grammar, context)
- **Works on:** Any Android XR device with ARCore support

### Install steps
1. Open the **Google Play Store** on your Android XR headset
2. Search for **"LiveCaptionsXR"**
3. Tap **Install**
4. Grant permissions when prompted:
   - **Microphone** — required for speech capture
   - **Camera** — optional, enables speaker localization and visual context
5. Launch and start captioning

### AI behavior (Store version)
The Store version auto-detects your device and selects the best AI configuration:

| Device tier | ASR model | LLM model | Performance |
|---|---|---|---|
| **Flagship** (Snapdragon 8 Elite, 8 Gen 3) | Whisper base | Gemma 3n 2B | Real-time, <500ms latency |
| **High-end** (Snapdragon 8 Gen 2, 8 Gen 1) | Whisper base | Gemma 3n 2B | Real-time, <800ms latency |
| **Mid-range** (Snapdragon 7-series) | Whisper tiny | Gemma 3n 2B (quantized) | Near real-time |
| **iOS** (iPhone/iPad) | Apple Speech | — | System-level ASR |

---

## Option 2: Sideloaded APK with Nexa AI (Best Performance)

### What you get
- **Speech-to-text:** Parakeet ASR via Nexa SDK (NPU-accelerated)
- **Text enhancement:** OmniNeural / Granite LLM (NPU-accelerated)
- **Works on:** Qualcomm Snapdragon devices with NPU (8 Elite, 8 Gen 3, 8 Gen 2, 8 Gen 1)
- **Why sideload:** The Nexa NPU runtime leverages Qualcomm's dedicated neural processor for ~2-3x faster inference than CPU-only Whisper

### Supported NPU devices
- Samsung Galaxy XR (Snapdragon 8 Elite)
- Qualcomm QRD8750 / QRD8650 reference boards
- Any device with Qualcomm Hexagon NPU (Snapdragon 8-series, 2022+)

### Download the APK
1. Go to [**GitHub Releases**](https://github.com/craigm26/LiveCaptionsXR/releases)
2. Download the latest `app-release.apk` (look for the most recent `v1.x.x` tag)

### Sideload via ADB (developer method)
If you have ADB set up:

```bash
# Connect your headset via USB or wireless ADB
adb devices

# Install the APK
adb install app-release.apk

# If upgrading from a previous version:
adb install -r app-release.apk
```

### Sideload without a computer
1. On your Android XR headset, go to **Settings → Security → Install unknown apps**
2. Enable installation from your browser (Chrome, etc.)
3. Open the GitHub Releases page in the headset's browser
4. Download and tap the APK to install
5. Grant permissions when prompted

### Sideload via Qualcomm Device Cloud (QDC)
For developers testing on QDC reference boards:

```bash
# Upload APK to your QDC session
adb -s <device-serial> install app-release.apk

# Verify installation
adb shell pm list packages | grep livecaptionsxr

# Launch
adb shell am start -n com.livecaptionsxr.app/.MainActivity
```

### AI behavior (Sideloaded version)
When the app detects an NPU-capable Qualcomm chipset, it automatically selects the Nexa AI pipeline:

| Detection | ASR model | LLM model | Acceleration |
|---|---|---|---|
| **NPU detected** (Snapdragon 8-series) | Parakeet ASR (Nexa) | Granite / OmniNeural (Nexa) | Qualcomm Hexagon NPU |
| **NPU not detected** (fallback) | Whisper GGML (CPU) | Gemma 3n (CPU/GPU) | Standard CPU/GPU |

The app logs its detection at startup. To verify NPU is active:
```bash
adb logcat -s NexaAsrPlugin | grep "NPU"
# Expected: "NPU availability check: chipset=qcom, hardware=qcom, supported=true"
```

---

## Understanding the AI Options

### Whisper + Gemma (Default / Store)
- **Whisper** is OpenAI's speech recognition model, running locally via GGML (C++ inference)
- **Gemma 3n** is Google's on-device language model that cleans up transcriptions — fixing punctuation, grammar, and adding context
- Runs on CPU/GPU on any modern Android device
- No internet connection needed after initial model download

### Nexa NPU + Parakeet (Sideload)
- **Parakeet** is NVIDIA's ASR model optimized for the Nexa SDK's NPU runtime
- **Granite / OmniNeural** are compact LLMs optimized for Qualcomm's Hexagon NPU
- Runs on the dedicated Neural Processing Unit — dramatically lower latency and power consumption
- No internet connection needed after initial model download

### Apple Speech (iOS)
- Uses Apple's built-in Speech framework
- Zero model downloads — works immediately
- Privacy handled at the OS level

---

## First Launch — What to Expect

1. **Permission prompts:** Allow microphone (required) and camera (recommended)
2. **Model download:** First launch downloads AI models (~200-500MB depending on configuration). This is a one-time download over WiFi.
3. **Device detection:** The app auto-detects your hardware and selects the optimal AI pipeline. You'll see a brief loading indicator.
4. **Ready to caption:** Point your headset toward a speaker and captions appear in your field of view, spatially anchored near the speaker's position.

---

## Troubleshooting

### App crashes on launch (sideloaded version)
- Ensure your device has a Qualcomm Snapdragon 8-series chipset
- Check logcat for errors: `adb logcat *:E | grep livecaptionsxr`
- Try clearing app data: **Settings → Apps → LiveCaptionsXR → Clear Data**

### NPU not detected on a supported device
- Some reference boards report non-standard chipset names. We support QRD board IDs and Qualcomm codenames (pineapple, kalama, waipio, taro)
- File an issue on [GitHub](https://github.com/craigm26/LiveCaptionsXR/issues) with your `adb shell getprop ro.board.platform` output

### Models won't download
- Ensure WiFi is connected (models are 200-500MB)
- Check available storage: models need ~1GB free space
- On QDC sessions: WiFi may need to be enabled manually via `adb shell svc wifi enable`

### Captions are delayed
- Close other resource-heavy apps
- The Nexa NPU version has significantly lower latency than Whisper CPU — consider sideloading if on a supported device
- Ensure the headset isn't in power-saving mode

---

## Version History

| Version | Changes |
|---|---|
| v1.0.22 | Fixed Nexa SDK 0.0.19 compatibility (init callback API change) |
| v1.0.20 | Improved NPU detection for QDC reference boards (QRD codenames) |
| v1.0.19 | NPU/Nexa improvements, Snapdragon 8 Elite detection |

---

## Questions?

- **GitHub Issues:** [github.com/craigm26/LiveCaptionsXR/issues](https://github.com/craigm26/LiveCaptionsXR/issues)
- **Architecture docs:** See [HYBRID_AI_ARCHITECTURE.md](HYBRID_AI_ARCHITECTURE.md) for deep technical details
- **Samsung Galaxy XR guide:** See [SAMSUNG_GALAXY_XR_CONSUMER_GUIDE.md](SAMSUNG_GALAXY_XR_CONSUMER_GUIDE.md)

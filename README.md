[![Release APK](https://github.com/craigm26/LiveCaptionsXR/actions/workflows/release-apk.yml/badge.svg)](https://github.com/craigm26/LiveCaptionsXR/actions/workflows/release-apk.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B?logo=flutter)](https://flutter.dev)
[![Nexa SDK](https://img.shields.io/badge/Nexa_SDK-NPU_Accelerated-FF6B00)](https://github.com/NexaAI)

# LiveCaptionsXR

**LiveCaptionsXR is an advanced accessibility application that provides real-time, spatially-aware closed captioning for the 466 million people worldwide with hearing loss. Powered by on-device AI with Nexa SDK NPU acceleration, we deliver privacy-first processing that transforms traditional flat captions into rich, contextual experiences with full spatial awareness.**

> **[Download Latest APK](https://github.com/craigm26/LiveCaptionsXR/releases/latest)** | **[Live Website](https://livecaptionsxr.com)**

---

## Nexa SDK & NPU Acceleration

LiveCaptionsXR uses the **Nexa SDK** to run AI models directly on the **Qualcomm Hexagon NPU**, achieving 2x faster inference and 9x better energy efficiency compared to CPU-only processing.

### Models Used

| Model | Type | Size | NPU | Purpose |
|-------|------|------|-----|---------|
| **Parakeet TDT 0.6B** | ASR | 0.6 GB | Yes | Real-time speech-to-text |
| **LFM2-1.2B** | LLM | 0.75 GB | Yes | Caption enhancement & punctuation |
| **OmniNeural-4B** | VLM | 4 GB | Yes | Visual context awareness |
| **Whisper GGML** | ASR | 141 MB | No | Fallback speech recognition |

### NPU Benefits

- **Real-time ASR**: Parakeet model on NPU delivers low-latency transcription suitable for live captions
- **Energy efficient**: NPU processing draws significantly less power than CPU/GPU, critical for XR headsets
- **Privacy-first**: All processing stays on-device — no audio data ever leaves the device
- **Concurrent AI**: NPU handles ASR while CPU/GPU remain free for AR rendering

### QDC Test Results (v1.0.34+)

Successfully tested on **Snapdragon 8 Elite** (QRD8750) via Qualcomm Developer Cloud:
- Nexa ASR initialized in NPU mode
- Audio capture pipeline operational at 16kHz
- Real-time transcription pipeline end-to-end functional
- LLM text enhancement working via LFM2-1.2B on NPU

---

## Architecture

```text
Audio Capture (16kHz stereo)
        |
Nexa ASR (Hexagon NPU) --> Speech-to-Text
        |
Nexa LLM (LFM2-1.2B) --> Punctuation & Enhancement
        |
Speaker Diarization --> Voice Embedding --> Speaker ID
        |
Hybrid Localization (Kalman filter: audio + visual + IMU)
        |
ARCore --> 3D Caption Placement at Speaker Location
```

---

## Key Features

- **NPU-Accelerated ASR** — Nexa SDK Parakeet model on Qualcomm Hexagon NPU for real-time speech recognition
- **On-Device LLM Enhancement** — LFM2-1.2B adds punctuation, grammar, and context to raw transcriptions
- **Spatial AR Captions** — Captions anchored in 3D space at the speaker's location via ARCore
- **Speaker Diarization** — Voice embedding analysis identifies and tracks unique speakers with color-coded captions
- **Real-Time Translation** — On-device translation to 15+ languages, 100% private
- **Hybrid Localization** — Kalman filter fusing stereo audio, visual face detection, and IMU data
- **Privacy-First** — 100% on-device processing, no data ever leaves the device
- **Cross-Platform** — Single Flutter codebase for Android, Android XR, iOS, and Web

---

## Quick Start

### Option 1: Download APK

```bash
# Download latest release APK
gh release download --repo craigm26/LiveCaptionsXR -p "app-release.apk" -D /tmp/

# Install on device
adb install /tmp/app-release.apk
```

Or download directly from [GitHub Releases](https://github.com/craigm26/LiveCaptionsXR/releases/latest).

### Option 2: Build from Source

**Prerequisites:** Flutter 3.38+, Android SDK API 24+

```bash
git clone https://github.com/craigm26/LiveCaptionsXR.git
cd LiveCaptionsXR
flutter pub get
flutter build apk --release --target-platform android-arm64
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Technical Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Framework** | Flutter 3.38+ / Dart 3.9+ | Cross-platform development |
| **On-Device ASR** | Nexa SDK (Parakeet TDT 0.6B) | NPU-accelerated speech recognition |
| **On-Device LLM** | Nexa SDK (LFM2-1.2B) | NPU-accelerated text enhancement |
| **On-Device VLM** | Nexa SDK (OmniNeural-4B) | NPU-accelerated visual understanding |
| **Fallback ASR** | Whisper GGML | CPU-based speech recognition |
| **AR Engine** | ARCore (Android) | Spatial caption placement |
| **State Management** | flutter_bloc (Cubit) | Predictable state handling |
| **DI** | get_it | Service architecture |

---

## Model Downloads

Models are downloaded automatically on first launch. The app includes a download manager with progress tracking.

| Model | ID | Size | Files | Type |
|-------|-----|------|-------|------|
| Parakeet TDT 0.6B | `parakeet-tdt-0.6b-v3-npu` | 0.6 GB | 7 | ASR (NPU) |
| LFM2-1.2B | `LFM2-1.2B-npu` | 0.75 GB | 4 | Chat/LLM (NPU) |
| OmniNeural-4B | `OmniNeural-4B` | 4 GB | 12 | VLM (NPU) |
| SmolVLM-256M | `SmolVLM-256M-Instruct-f16` | 0.48 GB | 2 | VLM (GGUF) |
| LFM2-1.2B GGUF | `LFM2-1.2B-GGUF-GGUF` | 0.75 GB | 1 | Chat (GGUF) |

---

## Platform Support

| Platform | Status | AI Backend |
|----------|--------|------------|
| **Android (Snapdragon)** | Primary | Nexa SDK on Hexagon NPU |
| **Android XR (Samsung Galaxy XR)** | Primary | Nexa SDK on Hexagon NPU |
| **Android (Other)** | Supported | Whisper GGML (CPU fallback) |
| **iOS** | Supported | Apple Speech + Gemma 3n |
| **Web** | Demo | Limited functionality |

---

## Project Structure

```text
LiveCaptionsXR/
├── lib/
│   ├── core/
│   │   ├── services/          # AI, audio, AR services
│   │   ├── models/            # Data models
│   │   └── di/                # Dependency injection
│   ├── features/              # Feature modules (UI)
│   └── shared/                # Shared widgets
├── android/app/src/main/kotlin/
│   ├── NexaAsrPlugin.kt       # Nexa ASR platform channel
│   └── HybridLocalizationEngine.kt
├── nexa_ai_flutter_patched/    # Patched Nexa SDK plugin
│   ├── android/src/main/kotlin/
│   │   └── ModelDownloadManager.kt
│   └── assets/model_list.json
├── plugins/
│   ├── spatial_captions/       # Spatial caption rendering
│   └── whisper_ggml_patched/   # Patched Whisper plugin
├── web/                        # PWA website
├── docs/                       # Documentation
└── .github/workflows/          # CI/CD pipelines
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [Development Guide](DEVELOPMENT_GUIDE.md) | Setup, testing, contribution guidelines |
| [Architecture](docs/ARCHITECTURE.md) | System design and patterns |
| [Nexa SDK Integration](docs/NEXA_SDK_INTEGRATION_ANALYSIS.md) | NPU integration analysis |
| [Speaker Diarization](docs/SPEAKER_DIARIZATION.md) | Voice embedding & spatial tracking |

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

**LiveCaptionsXR** — Empowering the deaf and hard of hearing community through AI-powered spatial accessibility technology.

*Built with [Nexa SDK](https://github.com/NexaAI) for Qualcomm Hexagon NPU acceleration.*

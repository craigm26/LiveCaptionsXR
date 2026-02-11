# LiveCaptionsXR

**LiveCaptionsXR is an advanced accessibility application that provides real-time, spatially-aware closed captioning for the 466 million people worldwide with hearing loss. Powered by on-device AI with Nexa SDK NPU acceleration, we deliver privacy-first processing that transforms traditional flat captions into rich, contextual experiences with full spatial awareness.**

---

## Current Focus: Android XR & Nexa SDK

We are actively developing LiveCaptionsXR for the **Android XR platform**, with primary support for:

- **Samsung Galaxy XR Headset** - Immersive spatial captions in mixed reality
- **Upcoming Samsung XR Glasses** - Lightweight, everyday accessibility
- **Android Phones & Tablets** - Full-featured mobile experience

### Nexa SDK Integration

LiveCaptionsXR leverages the **Nexa SDK** for Qualcomm Hexagon NPU-accelerated AI inference:

| Component | Technology | Benefit |
|-----------|-----------|---------|
| **Speech Recognition** | Nexa ASR on NPU | 2x faster, 9x more energy efficient |
| **Text Enhancement** | Granite-4.0-h-350M | Real-time caption refinement |
| **Multimodal AI** | OmniNeural-4B VLM | Visual context awareness |
| **Fallback** | Whisper GGML / Apple Speech | Non-NPU device support |

> **Note:** Nexa SDK requires Flutter 3.38.7+ (Dart 3.9.2+). See [Development Guide](DEVELOPMENT_GUIDE.md) for setup.

---

## Key Features

- **Spatial AR Captions:** Captions anchored in 3D space at the speaker's location using ARCore
- **🆕 Speaker Diarization + 3D/4D Spatial Mapping:** 
  - Voice embedding analysis to identify and track unique speakers
  - Real-time 3D position tracking with temporal smoothing (4D = 3D + time)
  - Translations mapped to the exact spatial location of each speaker
  - Persistent speaker profiles with color-coded captions
  - Kalman-filtered position prediction for smooth caption placement
- **Real-Time Translation:** On-device translation to 15+ languages including Spanish, French, German, Chinese, Japanese, Korean, Arabic, and more — 100% private
- **On-Device Hybrid Localization:** Kalman filter fusing stereo audio, visual face detection, and IMU data for real-time speaker tracking
- **Privacy-First by Design:** 100% on-device processing - no data ever leaves the device
- **NPU-Accelerated AI:** Qualcomm Hexagon NPU optimization via Nexa SDK
- **Cross-Platform Ready:** Single Flutter codebase for Android, iOS, and Web

---

## Technical Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Framework** | Flutter 3.x + Dart 3 | Cross-platform development |
| **On-Device AI** | Nexa SDK (NPU) | NPU-accelerated inference |
| **Speech Recognition** | Nexa ASR / Whisper GGML | Real-time transcription |
| **Text Enhancement** | Nexa LLM / Gemma 3n | Caption refinement |
| **AR Engine** | ARCore (Android) | Spatial caption placement |
| **State Management** | flutter_bloc (Cubit) | Predictable state handling |
| **DI** | get_it | Service architecture |

---

## How It Works

```text
Audio Capture (16kHz stereo)
        ↓
Nexa ASR (Hexagon NPU) → Speech-to-Text
        ↓
Nexa LLM → Text Enhancement & Punctuation
        ↓
Speaker Diarization → Voice Embedding → Speaker ID + Profile
        ↓
Hybrid Localization (Kalman filter: audio + visual + IMU)
        ↓
4D Spatial Tracking (3D position + temporal history)
        ↓
ARCore → 3D Caption Placement at Speaker Location
```

1. **Audio & Vision Capture:** Real-time stereo audio and camera frames captured
2. **NPU-Accelerated ASR:** Speech transcribed using Nexa SDK on Qualcomm Hexagon NPU
3. **Intelligent Enhancement:** Nexa LLM adds punctuation and context
4. **Speaker Diarization:** Voice embeddings (MFCC + spectral features) identify unique speakers
5. **4D Spatial Tracking:** 3D positions tracked over time with Kalman-filtered smoothing
6. **Speaker Localization:** Hybrid engine fuses audio direction, face detection, and IMU
7. **Spatial Placement:** Translations appear at the exact 3D location of each identified speaker

---

## Quick Start

### Prerequisites

- **Flutter SDK**: 3.38.7+ (for Nexa SDK support)
- **Dart SDK**: 3.9.2+
- **Android Studio** with Flutter extensions
- **Android SDK**: API 24+ (Android 7.0)

### Setup

```bash
# Clone the repository
git clone https://github.com/craigm26/LiveCaptionsXR.git
cd LiveCaptionsXR

# Install dependencies
flutter pub get

# Run on Android device
flutter run
```

### Android XR Development

```bash
# Build for Android XR devices (ARM64)
flutter build apk --release --target-platform android-arm64

# Install on Samsung Galaxy XR
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Platform Support

### Android (Primary Focus)

- **Samsung Galaxy XR Headset** - Full AR caption support with spatial audio
- **Samsung XR Glasses** - Lightweight caption overlay (coming soon)
- **Snapdragon Devices** - NPU acceleration via Nexa SDK
- **Other Android** - CPU/GPU fallback with Whisper GGML

### iOS

- Apple Speech Recognition (native)
- ARKit for spatial captions
- Gemma 3n for text enhancement

### Web

- Demo mode with limited functionality
- Full caption display without AR

---

## Project Structure

```text
LiveCaptionsXR/
├── lib/
│   ├── core/
│   │   ├── services/      # AI, audio, AR services
│   │   ├── models/        # Data models
│   │   └── di/            # Dependency injection
│   ├── features/          # Feature modules
│   └── shared/            # Shared widgets
├── android/               # Android native code
│   └── app/src/main/kotlin/
│       ├── NexaAsrPlugin.kt
│       └── HybridLocalizationEngine.kt
├── ios/                   # iOS native code
├── docs/                  # Documentation
└── prd/                   # Product requirements
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [Development Guide](DEVELOPMENT_GUIDE.md) | Setup, testing, contribution |
| [Architecture](docs/ARCHITECTURE.md) | System design and patterns |
| [Nexa SDK Integration](docs/NEXA_SDK_INTEGRATION_ANALYSIS.md) | NPU integration strategy |
| [Samsung Galaxy XR Guide](docs/SAMSUNG_GALAXY_XR_CONSUMER_GUIDE.md) | XR user experience |
| [Contributing](CONTRIBUTING.md) | Contribution guidelines |

---

## Model Downloads

LiveCaptionsXR downloads AI models automatically on first launch:

| Model | Size | Purpose |
|-------|------|---------|
| Nexa ASR | ~150 MB | NPU speech recognition |
| Granite-4.0-h-350M | ~350 MB | NPU text enhancement |
| Whisper Base | 141 MB | Fallback speech recognition |
| Gemma 3N E4B | 4.11 GB | Advanced enhancement (optional) |

---

## Development

```bash
# Run tests
flutter test

# Build release APK
flutter build apk --release

# Analyze code
flutter analyze
```

See [Development Guide](DEVELOPMENT_GUIDE.md) for detailed instructions.

---

## Speaker Diarization & 3D/4D Spatial Intelligence

LiveCaptionsXR implements advanced speaker diarization that maps translations to speakers in 3D/4D space:

### Voice Embedding Features
- **MFCC Coefficients:** Mel-Frequency Cepstral Coefficients for voice characterization
- **Delta MFCCs:** First-order derivatives capturing speech dynamics
- **Spectral Features:** Centroid, bandwidth, rolloff, and flatness
- **Pitch Estimation:** Autocorrelation-based fundamental frequency detection
- **Energy Statistics:** RMS energy for voice activity detection

### Spatial Tracking (4D)
- **3D Position:** GCC-PHAT time-delay-of-arrival + hybrid localization
- **Temporal History:** Exponential decay weighted position averaging
- **Velocity Estimation:** Position prediction for smooth caption animation
- **Confidence Weighting:** High-confidence observations weighted more heavily

### Speaker Profile Management
- **Similarity Threshold:** Cosine similarity matching (default: 0.75)
- **Spatial Coherence:** Position-based matching boost for nearby speakers
- **Profile Persistence:** Export/import for cross-session recognition
- **Max Speakers:** Configurable limit with LRU pruning

### UI Components
- **SpeakerIndicator:** Individual speaker badge with color and position
- **SpeakerTracker:** Horizontal list of all tracked speakers
- **SpeakerRadar:** Radar-style 2D visualization of 3D speaker positions

---

## Roadmap

### Q1 2026

- [x] Nexa SDK ASR integration
- [x] Nexa SDK LLM integration
- [ ] Samsung Galaxy XR optimization
- [ ] Performance profiling on NPU

### Q2 2026

- [ ] Samsung XR Glasses support
- [ ] Multi-speaker tracking improvements
- [ ] Voice command control
- [ ] Accessibility testing with D/HH community

---

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

This project is developed for accessibility and social impact.

---

**LiveCaptionsXR - Empowering the deaf and hard of hearing community through AI-powered spatial accessibility technology.**

*Optimized for Samsung Galaxy XR and Android XR devices with Qualcomm Hexagon NPU acceleration.*

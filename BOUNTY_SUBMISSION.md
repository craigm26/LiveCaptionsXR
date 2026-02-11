# LiveCaptionsXR — Nexa Bounty Submission

## Project Overview

**LiveCaptionsXR** is an advanced accessibility app that provides real-time, spatially-aware closed captioning for the 466 million people worldwide with hearing loss. Powered entirely by on-device AI with Nexa SDK NPU acceleration, it delivers privacy-first processing that transforms traditional flat captions into rich, contextual experiences with full spatial awareness via ARCore.

## Nexa SDK Integration

### Models & NPU Features Used

| Component | Nexa SDK Feature | Details |
|-----------|-----------------|---------|
| **Speech Recognition** | Nexa ASR on Hexagon NPU | Real-time speech-to-text, 2x faster and 9x more energy efficient than CPU |
| **Text Enhancement** | Granite-4.0-h-350M via Nexa LLM | On-device punctuation, capitalization, and context refinement |
| **Real-Time Translation** | Nexa LLM on Hexagon NPU | On-device translation to 15+ languages, 100% private |
| **Multimodal Vision** | OmniNeural-4B VLM | Visual context awareness for speaker identification |
| **Fallback** | Whisper GGML | Non-NPU device support via Nexa's GGML runtime |

### How Nexa SDK is Used

1. **NPU-Accelerated ASR**: Audio captured at 16kHz stereo is processed through Nexa's ASR pipeline running on the Qualcomm Hexagon NPU, achieving real-time transcription with minimal battery impact.
2. **On-Device LLM Enhancement**: Raw transcriptions are refined by Nexa's LLM inference (Granite-4.0-h-350M) for proper punctuation and formatting — all on-device.
3. **Real-Time Translation**: Transcribed text is optionally translated to 15+ languages using Nexa LLM on the Hexagon NPU. Supported languages include Spanish, French, German, Chinese, Japanese, Korean, Arabic, Hindi, Russian, and more. Translation runs entirely on-device with no cloud dependency.
4. **Vision Pipeline**: Camera frames are processed through Nexa's multimodal VLM for speaker identification and visual context.
5. **Zero Cloud Dependency**: All AI inference runs locally via Nexa SDK. No data ever leaves the device.

### NPU Acceleration Benefits
- **2x faster** inference compared to CPU-only
- **9x more energy efficient** — critical for always-on accessibility
- **Privacy by architecture** — no network calls for AI processing

## Demo Instructions

1. Download the APK: [LiveCaptionsXR.apk](https://github.com/craigm26/LiveCaptionsXR/releases/latest/download/LiveCaptionsXR.apk)
2. Install on an Android device (enable "Install from unknown sources")
3. Grant microphone and camera permissions
4. Point the device at a speaker — captions appear in AR space at the speaker's location
5. The app works fully offline with no cloud dependency

## APK Download

📥 [Download LiveCaptionsXR APK](https://github.com/craigm26/LiveCaptionsXR/releases/latest/download/LiveCaptionsXR.apk)

## Screenshots / Video

<!-- TODO: Add screenshots and demo video -->
- [ ] Hero screenshot showing spatial captions in AR
- [ ] Demo video of real-time captioning
- [ ] NPU performance metrics screenshot
- [ ] Battery usage comparison (NPU vs CPU)

🎥 [Demo Video](https://youtu.be/Oz8nzt2cc3Q)

## How It Meets Bounty Criteria

- **On-Device AI**: 100% local inference via Nexa SDK — zero cloud dependency
- **NPU Utilization**: Leverages Qualcomm Hexagon NPU through Nexa SDK for ASR and LLM
- **Real-World Impact**: Accessibility tool serving 466M+ people with hearing loss
- **Production Quality**: Full Flutter app with ARCore spatial placement, background processing, and optimized battery usage
- **Open Source**: Fully open-source codebase

## Technical Stack

- **Framework**: Flutter 3.38.7+ / Dart 3.9.2+
- **AI Runtime**: Nexa SDK (NPU/GPU/CPU)
- **AR Engine**: ARCore for spatial caption placement
- **Architecture**: flutter_bloc (Cubit) + get_it DI
- **Platform**: Android XR, Android mobile, iOS (fallback), Web (marketing site)

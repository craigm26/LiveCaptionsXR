# LiveCaptionsXR

**LiveCaptionsXR is an advanced accessibility application that provides real-time, spatially-aware closed captioning for the 466 million people worldwide with hearing loss. Leveraging Google's **Gemma 3n** multimodal AI and platform-specific speech recognition, we deliver on-device processing that transforms traditional flat captions into rich, contextual experiences that preserve spatial awareness and environmental context.**

---

## ✨ Key Features

- **Spatial AR Captions:** Captions are anchored in 3D space at the speaker's location using ARKit and ARCore
- **On-Device Hybrid Localization:** A sophisticated Kalman filter fuses stereo audio, visual face detection, and IMU data for rock-solid, real-time speaker tracking
- **Privacy-First by Design:** All processing, from sensor data to AI inference, happens 100% on the user's device. No data ever leaves the phone
- **Powered by **Gemma 3n**:** Leveraging Google's state-of-the-art model for intelligent, context-aware, on-device transcription
- **Cross-Platform & Production-Ready:** A single, polished Flutter codebase for iOS, Android, and Web

## 🛠️ Technical Stack

| **Component** | **Technology Choice** | **Rationale** |
| --- | --- | --- |
| **Frontend Framework** | Flutter 3.x with Dart 3 | Single codebase for iOS/Android/Web, native performance, excellent accessibility support |
| **AI Model** | Google Gemma 3n | State-of-the-art on-device multimodal model |
| **Speech Recognition**| **Platform-specific** | **Android**: whisper_ggml (on-device Whisper), **iOS**: Apple Speech Recognition (native) |
| **State Management** | flutter_bloc (Cubit pattern) | Predictable state management for complex AI workflows |
| **Service Architecture** | Dependency Injection (get_it) | Clean separation of concerns and a testable service layer |
| **AR** | ARKit (iOS), ARCore (Android) | Native AR frameworks for the best performance and features |
| **Permissions** | `permission_handler` | A reliable way to request and manage device permissions |
| **Camera** | `camera` | The official Flutter camera plugin |

## ⚙️ How It Works

1. **Audio & Vision Capture:** Real-time stereo audio and camera frames are captured
2. **Direction Estimation:** Audio direction is estimated (using RMS and GCC-PHAT) and optionally fused with visual speaker identification
3. **Hybrid Localization Fusion:** A Kalman filter in the **HybridLocalizationEngine** fuses all modalities to estimate the 3D world position of the speaker
4. **Streaming ASR:** Speech is transcribed in real time using platform-specific engines: **Android** uses `whisper_ggml` (on-device Whisper), **iOS** uses Apple Speech Recognition (native)
5. **AR Caption Placement:** When a final transcript is available, the fused 3D transform and caption are sent to the native AR view (ARKit/ARCore), which anchors the caption in space at the speaker's location

## 🚀 Quick Start

### Prerequisites
- **Flutter SDK**: 3.16.0 or higher
- **Dart SDK**: 3.2.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Xcode** (for iOS development)
- **Android SDK** (for Android development)

### Basic Setup
1. **Clone the repository:**
   ```bash
   git clone https://github.com/craigm26/LiveCaptionsXR.git
   cd LiveCaptionsXR
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## 📱 Platform-Specific Setup

### iOS Development
- **Xcode**: Latest version with iOS 11.0+ deployment target
- **ARKit**: Automatically configured in the project
- **Permissions**: Camera, microphone, speech recognition, and location permissions are configured
- **Signing**: Configure your Apple Developer account in Xcode
- **Device**: iPhone 6s or newer with iOS 11.0+

### Android Development
- **Android Studio**: Latest version
- **SDK**: API Level 24+ (Android 7.0) for ARCore support
- **ARCore**: Automatically included in the project
- **Permissions**: Camera, microphone, and location permissions are configured
- **Device**: ARCore-supported device with Android 7.0+

### Web Development
- **Flutter Web**: Enabled by default
- **Performance**: Optimized for modern browsers
- **Features**: Limited AR functionality (web AR not supported)
- **Deployment**: Ready for web hosting platforms

## 🔌 Method Channels

- `live_captions_xr/ar_navigation`: Launch the native AR view from Flutter
- `live_captions_xr/caption_methods`: Place captions in the AR view
- `live_captions_xr/hybrid_localization_methods`: API for the hybrid localization engine
- `live_captions_xr/visual_object_methods`: Send visual object detection data from the native layer to Dart
- `live_captions_xr/audio_capture_methods`: Manages the capture of stereo audio
- `live_captions_xr/audio_capture_events`: An event channel that streams audio data from the native layer to the Dart layer
- `live_captions_xr/speech_localizer`: Handles the communication with the speech localization plugin

## 📁 Project Structure

```
LiveCaptionsXR/
├── lib/
│   ├── core/           # Core services and utilities
│   ├── features/       # Feature-specific modules
│   ├── shared/         # Shared widgets and utilities
│   ├── web/           # Web-specific code
│   └── main.dart      # App entry point
├── android/           # Android-specific code
├── ios/              # iOS-specific code
├── web/              # Web-specific assets
├── test/             # Test files
├── docs/             # Documentation
└── prd/              # Product requirements
```

## 🧪 Development

For detailed development information, testing, debugging, and contribution guidelines, please refer to our comprehensive documentation:

- [**Development Guide**](DEVELOPMENT_GUIDE.md) - Complete setup, testing, debugging, and contribution guidelines
- [**Technical Documentation**](docs/ARCHITECTURE.md) - Technical architecture and implementation details
- [**Contributing Guidelines**](CONTRIBUTING.md) - How to contribute to the project

### Running Tests
```bash
# Run all tests
flutter test

# Run tests in a specific file
flutter test test/path/to/your_test.dart

# Generate mocks
flutter pub run build_runner build
```

## 📦 Model Downloads

LiveCaptionsXR requires AI models for speech recognition and enhancement. These models are downloaded automatically by the app, but you can also download them manually:

### Available Models
- **Whisper Base** (141 MB) - Speech recognition
- **Gemma 3N E2B** (2.92 GB) - Text enhancement
- **Gemma 3N E4B** (4.11 GB) - Advanced text enhancement

### Model Distribution System
We maintain a separate model distribution system for reliable, fast downloads:

- **🌐 Web Interface**: [Model Downloads](livecaptionsxrbucket/index.html) - Professional web interface for manual downloads
- **📱 Flutter Integration**: [Flutter Implementation](livecaptionsxrbucket/flutter/) - Complete Flutter integration for app developers
- **⚙️ System Management**: [System Documentation](livecaptionsxrbucket/README.md) - PowerShell scripts and setup guides

> **Note**: The model distribution system operates independently from the main LiveCaptionsXR application and uses Cloudflare R2 for hosting.

## 🤝 Contributing

We welcome contributions from the community! Please see our [Contributing Guidelines](CONTRIBUTING.md) for more information on how to get started.

## 📚 Additional Resources

- [**Hackathon Submission**](docs/HACKATHON_SUBMISSION.md) - Original hackathon submission details
- [**Accessibility Testing**](docs/ACCESSIBILITY_TESTING.md) - Accessibility testing guidelines
- [**Architecture Documentation**](docs/ARCHITECTURE.md) - Detailed technical architecture

---

**LiveCaptionsXR - Empowering the deaf and hard of hearing community through AI-powered spatial accessibility technology.**

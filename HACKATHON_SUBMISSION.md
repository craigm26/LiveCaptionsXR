# Google Gemma 3n Hackathon Submission: live_captions_xr

**Comprehensive Project Overview for Judges**

---

## 🏆 Project Summary

**live_captions_xr** is an innovative accessibility application that demonstrates the transformative potential of Google's Gemma 3n multimodal AI model for real-world closed captioning. Our solution addresses critical accessibility challenges for the 466 million people worldwide with hearing loss by creating a spatially-aware captioning system for both standard mobile devices (iOS/Android) and XR environments.

**Core Innovation**: Rather than processing speech as isolated audio streams, live_captions_xr leverages Gemma 3n's unified multimodal architecture to understand conversational context holistically, providing spatial captions like "Person at your left said: 'The meeting starts in 5 minutes'" instead of simply displaying flat text transcriptions. This is all achieved on-device for maximum privacy and performance.

## What's New
- **Hybrid Localization Engine:** Fuses audio, vision, and IMU for robust, real-time speaker localization using a Kalman filter.
- **ARKit/ARCore Plugin Integration:** Native plugins for AR anchor management, visual object detection, and caption placement, with Dart wrappers and MethodChannel communication.
- **Real-time AR Caption Placement:** Captions are anchored in AR at the fused speaker position as soon as speech is recognized.
- **Streaming ASR & Multimodal Fusion:** On-device Gemma 3n model for low-latency, privacy-preserving speech recognition and multimodal context.
- **Dart-Native Communication:** New MethodChannels for AR navigation, caption placement, hybrid localization, and visual object detection.

## End-to-End Pipeline
1. **Audio & Vision Capture:** Real-time stereo audio and camera frames.
2. **Direction Estimation:** Audio direction (RMS, GCC-PHAT) and visual speaker identification.
3. **Hybrid Localization Fusion:** Kalman filter fuses all modalities for 3D world position.
4. **Streaming ASR:** Real-time speech transcription.
5. **AR Caption Placement:** Fused transform and caption sent to native AR view for 3D anchoring.

## Modular Plugin Architecture
- Easily extensible for new sensors, models, or AR features.
- Testable, production-grade code with clear separation of concerns.

## MethodChannels
- `live_captions_xr/ar_navigation`: Launch native AR view.
- `live_captions_xr/caption_methods`: Place captions in AR.
- `live_captions_xr/hybrid_localization_methods`: Hybrid localization engine API.
- `live_captions_xr/visual_object_methods`: Visual object detection from native.

---

## 📋 Hackathon Submission Checklist

### ✅ Technical Writeup (Proof of Work)
- **📄 [TECHNICAL_WRITEUP.md](TECHNICAL_WRITEUP.md)** - Primary submission document.
- Comprehensive architecture explanation and Gemma 3n integration details using **MediaPipe**.
- Technical challenges overcome and solution strategies.

### ✅ Public Code Repository (Source of Truth)
- **🌐 Public Repository**: [https://github.com/craigm26/live_captions_xr](https://github.com/craigm26/live_captions_xr)
- Well-documented Flutter codebase with a clear, service-oriented architecture.
- Detailed PRDs in the `/prd` directory that outline the implementation of each feature.

### ✅ Additional Documentation
- **🏗️ [ARCHITECTURE.md](ARCHITECTURE.md)** - Detailed system design based on a layered, service-oriented architecture.
- **🎬 [Interactive Demo](web/README.md)** - Live web demonstration for judges.
- **♿ [Accessibility Testing](docs/ACCESSIBILITY_TESTING.md)** - Comprehensive testing plan for the D/HH community.

---

## 🧠 Why This Matters for Gemma 3n

### Revolutionary Multimodal Application
- **Real-world Impact**: Addresses genuine user needs for 466 million people with hearing loss.
- **Mobile Deployment**: Proves feasibility of sophisticated multimodal AI on mobile devices using MediaPipe.
- **Privacy-First**: Complete on-device processing shows Gemma 3n's mobile capabilities.

### Technical Innovation Highlights
- **Unified Multimodal Processing**: Audio + Visual + Context processed simultaneously through Gemma 3n and MediaPipe.
- **Spatial Understanding**: Sound localization combined with visual scene understanding.
- **Real-time Performance**: Optimized for mobile deployment with sub-second response times.

---

## 🎯 Technical Achievements

### 1. Complete Multimodal Architecture
```
[Microphone Array] ──┐
                    ├──► [MediaPipe Inference Engine] ──► [Gemma 3n Core] ──► [Natural Language Response]
[Camera Feed] ───────┤
                    │
[User Context] ─────┘
```

### 2. Production-Ready Implementation
- **Flutter Application**: Complete mobile app with a clean, layered architecture.
- **Service Layer**: Comprehensive AI services with dependency injection and state management.
- **PRD-Driven Development**: A full suite of detailed PRDs in the `/prd` directory guides all development.

### 3. Accessibility-First Design
- **WCAG 2.2 AA Compliance**: Full accessibility standard adherence.
- **Multiple Feedback Channels**: Visual, haptic, and LED feedback systems.
- **Real User Testing**: Partnership with D/HH community for validation.

---

## 🚀 Live Demonstration

### Interactive Web Demo
- **🌐 Access**: Open `/web/index.html` in any browser.
- **🎮 Features**: Interactive use case scenarios and technical visualizations.
- **♿ Accessibility**: Full screen reader support and responsive design.

---

## 🔧 Technical Implementation Deep Dive

### Gemma 3n Integration Strategy

Our integration strategy is centered on using the official **Google MediaPipe Tasks** library on the native side (Kotlin/Swift) to run the Gemma 3n `.task` model. This approach ensures optimal performance, access to hardware acceleration, and a stable, supported path for on-device inference.

#### Core Service Architecture
```dart
// Dart service layer that communicates with native MediaPipe
class Gemma3nService {
  Future<String> runMultimodalInference({
    required Float32List audioInput,
    required Uint8List imageInput,
    required String textContext,
  }) async {
    // This method will invoke the native MediaPipe implementation
    // via a platform channel, passing the input data.
    final result = await _platformChannel.invokeMethod('runInference', {
      'audio': audioInput,
      'image': imageInput,
      'text': textContext,
    });
    return result;
  }
}
```

---

## 🔗 Judge Navigation Guide

### Primary Documents (Start Here)
1.  **📄 [TECHNICAL_WRITEUP.md](TECHNICAL_WRITEUP.md)** - Main hackathon submission.
2.  **🎬 [Flutter Web Demo](web/README.md)** - Live interactive demonstration.
3.  **🏗️ [ARCHITECTURE.md](ARCHITECTURE.md)** - Technical deep dive and system design.

### Supporting Documentation
4.  **📱 [README.md](README.md)** - Project overview and getting started guide.
5.  **♿ [Accessibility Testing](docs/ACCESSIBILITY_TESTING.md)** - User testing and compliance.
6.  **`/prd` directory** - Detailed requirements for each feature.

---

## 🏅 Conclusion

live_captions_xr represents the future of accessibility technology, demonstrating how Gemma 3n's revolutionary multimodal capabilities can transform real-world challenges into elegant, inclusive solutions. Our comprehensive implementation proves not just technical competence, but deep understanding of both AI capabilities and human needs.

# Google Gemma 3n Hackathon Submission: Live Captions XR

**Comprehensive Project Overview for Judges**

---

## 🏆 Project Overview & Impact

**Live Captions XR** is an innovative accessibility application that demonstrates the transformative potential of Google's Gemma 3n multimodal AI model for real-world closed captioning. Our solution addresses critical accessibility challenges for the 466 million people worldwide with hearing loss by creating a spatially-aware captioning system for both standard mobile devices (iOS/Android) and XR environments.

**Core Innovation**: Rather than processing speech as isolated audio streams, Live Captions XR leverages Gemma 3n's unified multimodal architecture to understand conversational context holistically, providing spatial captions like "Person at your left said: 'The meeting starts in 5 minutes'" instead of simply displaying flat text transcriptions. This is all achieved on-device for maximum privacy and performance.

Our system features a **Hybrid Localization Engine** that fuses audio, vision, and IMU data using a Kalman filter for robust, real-time speaker localization. This enables **Real-time AR Caption Placement**, anchoring captions in 3D space at the speaker's location. The **Streaming ASR & Multimodal Fusion** is powered by an on-device Gemma 3n model, ensuring low-latency, privacy-preserving speech recognition. Communication between the Dart frontend and native Swift/Kotlin/Java backend is facilitated by **Flutter Plugins** using **MethodChannels** and **EventChannels**, including `live_captions_xr/ar_navigation`, `live_captions_xr/caption_methods`, `live_captions_xr/hybrid_localization_methods`, and `live_captions_xr/visual_object_methods`.



---

## 🧠 Impact & Vision (40 points)

### Revolutionary Multimodal Application
- **Real-world Impact**: Addresses genuine user needs for 466 million people with hearing loss, transforming communication accessibility.
- **Mobile Deployment**: Proves the feasibility of sophisticated multimodal AI on mobile devices using MediaPipe, pushing the boundaries of on-device ML.
- **Privacy-First**: Complete on-device processing ensures user privacy, demonstrating Gemma 3n's capabilities without compromising sensitive data.

### Technical Innovation Highlights
- **Unified Multimodal Processing**: Audio + Visual + Context processed simultaneously through Gemma 3n and MediaPipe, enabling a deeper understanding of conversational dynamics.
- **Spatial Understanding**: Sound localization combined with visual scene understanding allows for precise placement of captions in 3D space.
- **Real-time Performance**: Optimized for mobile deployment with sub-second response times, crucial for natural and fluid conversations.

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

## 🚀 Video Pitch & Storytelling (30 points)

Our video demonstration is the primary artifact for evaluating the project's impact and functionality. It showcases the real-time, spatially-aware captioning in action, highlighting the user experience and the seamless integration of Gemma 3n.

- **Video Link**: [Insert Video Link Here] (Will be added upon video completion)
- **Key Highlights**:
    - Real-time captioning in various environments.
    - Spatial accuracy of captions relative to the speaker.
    - User interaction and accessibility features.
    - Demonstration of multimodal fusion (audio, visual, IMU).

---

## 🎯 Technical Depth & Execution (30 points)

### 1. Robust Multimodal Architecture
```
[Microphone Array] ──┐
                    ├──► [MediaPipe Inference Engine] ──► [Gemma 3n Core] ──► [Spatial Caption]
[Camera Feed] ───────┤
                    │
[User Context] ─────┘
```
Our architecture is designed for high-performance, on-device multimodal AI. It integrates audio, visual, and inertial data streams, processed efficiently through the MediaPipe Inference Engine and Gemma 3n Core to generate spatially accurate captions.

### 2. Production-Ready Implementation
- **Flutter Application**: Complete mobile app with a clean, layered architecture, ensuring cross-platform compatibility (iOS/Android).
- **Service Layer**: Comprehensive AI services with dependency injection and state management, promoting modularity and testability.
- **PRD-Driven Development**: A full suite of detailed PRDs in the `/prd` directory guides all development, ensuring a structured and goal-oriented approach.

### 3. Accessibility-First Design
- **WCAG 2.2 AA Compliance**: Full adherence to Web Content Accessibility Guidelines, ensuring inclusivity for all users.
- **Multiple Feedback Channels**: Visual, haptic, and LED feedback systems provide diverse ways for users to receive information.
- **Real User Testing**: Partnership with the D/HH community for continuous feedback and validation, ensuring the solution meets real-world needs.

---

## 🔗 Judge Navigation Guide

### Primary Documents (Start Here)
1.  **🎬 Video Pitch & Storytelling**: Our primary submission artifact, showcasing the project in action.
2.  **📄 [TECHNICAL_WRITEUP.md](TECHNICAL_WRITEUP.md)** - Main hackathon submission, detailing technical architecture and Gemma 3n integration.
3.  **🏗️ [ARCHITECTURE.md](ARCHITECTURE.md)** - Detailed system design and architectural patterns.

### Supporting Documentation
4.  **🌐 Public Repository**: [https://github.com/craigm26/live_captions_xr](https://github.com/craigm26/live_captions_xr) - Source code and development history.
5.  **📱 [README.md](README.md)** - Project overview and getting started guide.
6.  **♿ [Accessibility Testing](docs/ACCESSIBILITY_TESTING.md)** - User testing methodologies and compliance.
7.  **`/prd` directory** - Detailed requirements for each feature, providing insight into the development process.

---

## 🏅 Conclusion

Live Captions XR represents the future of accessibility technology, demonstrating how Gemma 3n's revolutionary multimodal capabilities can transform real-world challenges into elegant, inclusive solutions. Our comprehensive implementation proves not just technical competence, but deep understanding of both AI capabilities and human needs.

**Impact Goal**: Empowering independence and communication accessibility for the 466 million people worldwide with hearing loss.

# 📘 live_captions_xr – Android XR Captioning PRD

## 🧩 Overview

live_captions_xr is a **real-time closed captioning application** specifically designed for **Android XR headsets**, providing immersive and spatially-aware captions for the Deaf and Hard of Hearing (D/HH) community. Built with **on-device multimodal AI** powered by **Google Gemma 3n**, it delivers seamless captioning experiences for users wearing **Android-compatible XR headsets** or **smartglasses** that support **ARCore**, **OpenXR**, or similar runtimes.

live_captions_xr transforms traditional closed captioning by adding spatial context and directional awareness—essential for XR environments where understanding the source and context of speech is critical for full immersion and accessibility.

> **"As someone who can't reliably tell where a sound came from in real life, building spatial captioning isn't just a feature—it's a solution to a real, daily problem. live_captions_xr is what I wish I had years ago. Now I'm building it with Gemma 3n and Flutter for everyone who needs it."** - Craig Merry, Developer

---

## 🎯 Goals

- Deliver **immersive real-time captioning** optimized for Android XR environments.
- Provide **spatial awareness captions** with directional indicators showing sound source location.
- Maintain real-time on-device processing for speech recognition and visual context analysis.
- Deliver accessible caption display via:
  - **Floating readable overlays** positioned in user's field of view
  - **Directional caption anchors** showing speaker location
  - **XR-compatible haptic feedback** for caption alerts and speaker changes
- Support **Android XR headsets** as the primary platform (Meta Quest Pro, Lenovo A3, etc.).

---

## 🧠 Feature Breakdown

### 🎥 1. XR Caption Visualization Layer (Flutter → XR)

| Sub-Feature | Description |
|-------------|-------------|
| Floating Caption Overlays | Display real-time speech transcriptions as readable, positioned overlays in XR space |
| Speaker Direction Indicators | Overlay directional arrows or rings pointing to the location of current speaker |
| Multi-Speaker Management | Color-coded captions for different speakers with spatial positioning |
| Contextual Caption Anchors | Anchor captions to relevant objects/people using Gemma 3n's multimodal understanding |
| Caption Interaction Mode | Gaze-based or gesture controls for caption history, speaker focus, and settings |

### 🔊 2. XR Caption Feedback Systems

| Sub-Feature | Description |
|-------------|-------------|
| Haptic Caption Alerts | Trigger vibrations through XR device controllers when new speakers begin talking |
| Caption Change Notifications | Use haptic patterns to indicate speaker changes or important dialogue |
| LED Status Indicators | Use onboard LED for caption system status and urgent speech alerts |

### 🧱 3. XR Captioning Integration Bridge

#### Platform Choices for XR Caption Rendering:

| Option | Pros | Cons |
|--------|------|------|
| Flutter + ARCore Plugin | Fast integration, optimal for caption overlays | Limited to mobile-based XR |
| Flutter → Unity XR Bridge | Full OpenXR support, immersive caption positioning | Requires Unity build management |
| Android NDK Plugin Layer | Maximum caption rendering performance | Highest development complexity |

---

## 🔧 MVP Architecture

**Data Flow Architecture:**

```
Mic Input → TFLite Sound Model ↘
                                 ↘
                                  Fusion Engine → Flutter AR UI → ARCore Layer → XR Device View
                                 ↗                                                        ↓
Camera Feed → TFLite Vision Model ↗                                            Haptic/LED/Spatial Audio
```

**Component Interaction:**
1. **Input Layer**: Microphone and camera capture environmental data
2. **Processing Layer**: TFLite models analyze audio and visual inputs  
3. **Fusion Layer**: Combine audio/visual results with spatial localization
4. **UI Layer**: Flutter renders AR overlays and user interface
5. **Output Layer**: ARCore provides spatial anchoring for XR devices
6. **Feedback Layer**: Multi-modal alerts via haptics, LED, and spatial audio

---

## 📦 Dependencies

| Tool | Use |
|------|-----|
| `arcore_flutter_plugin` | Base ARCore overlays |
| `flutter_unity_widget` | Connect Unity XR content to Flutter |
| `get_it` | Bridge for platform-specific services |
| `flutter_tts` | Optional verbalized labels in XR |
| Unity XR Toolkit | For 3D XR rendering and OpenXR support |
| TensorFlow Lite | Local inference engine for sound/vision |

---

## 🛠 Implementation Phases

### ✅ Phase 1 – Mobile AR Enhancements
- Upgrade Flutter AR overlay system (arrow, text, rings)
- Add spatial sound origin markers (on-screen)
- Simulate XR on phone screen for development

### 🚧 Phase 2 – XR Device Bridge
- Embed Flutter into Unity (as Android module)
- Render 3D anchors in XR space
- Communicate alerts from Flutter (via platform channel or method call)

### 🧪 Phase 3 – Native XR App Fork (Optional)
- Build a Unity/OpenXR viewer app
- Route all TFLite inference via background service
- Visualize real-time alert feed in immersive headset mode

---

## ✅ Acceptance Criteria

| Criterion | Description |
|----------|-------------|
| XR overlay performance | ≥ 25 FPS on target XR hardware |
| Alert direction accuracy | ≥ 80% spatial agreement with detected origin |
| Feedback delivery | Haptic and/or light alerts triggered for every urgent event |
| Multi-modal fallback | If XR rendering fails, fallback to 2D mobile AR UI |
| Device compatibility | Works with at least 1 Android XR headset (e.g., Lenovo A3, Quest Pro) |

---

## 🧪 Test Strategy

- Simulate fire alarm, doorbell, speech, and siren sounds
- Confirm spatial anchors are placed correctly
- Test in varying light and audio conditions
- Verify performance on real XR hardware
- Run accessibility checks (contrast, text size, motion, toggles)

---

## 💬 Open Questions

- How to optimize caption rendering latency on XR headsets for real-time speech?
- Can Flutter + Unity deliver sub-100ms caption display for natural conversation flow?
- Should caption history be stored locally or use cloud sync for multi-device access?
- Can we leverage Android's upcoming [ARCore Extensions for Glasses](https://developers.google.com/ar) for enhanced spatial caption positioning?

---

## 📣 Final Thoughts

live_captions_xr positions itself as **the first spatially-aware captioning application** built specifically for Android XR headsets and the D/HH community. By combining Gemma 3n's multimodal AI with immersive XR environments, it transforms closed captioning from flat text overlays into rich, contextual, and spatially-positioned communication aids that truly bridge the hearing gap in extended reality.
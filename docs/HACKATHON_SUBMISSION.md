# 📣 Project Description: LiveCaptionsXR

**Subtitle:**
*"On-device, real-time captioning and sound awareness for XR—built by a deaf developer using whisper_ggml and Gemma 3n to unlock spatial hearing for everyone."*

---

## 🎯 Vision

**LiveCaptionsXR** is a groundbreaking accessibility tool designed to provide **spatially-aware closed captioning in augmented and extended reality (XR) environments**. Powered entirely by on-device AI, it gives the Deaf and Hard of Hearing (D/HH) community a private, offline-first experience that transforms speech into **context-rich, directional captions**—like a pair of AI-enhanced ears.

The project was created by **Craig Merry**, who is deaf in one ear and mostly deaf in the other. This personal experience drives the focus on **sound localization**, ensuring captions are not just accurate, but anchored in **space**—telling users *where* speech comes from, not just *what* was said.

---

## 💡 What Makes It Unique?

### ✅ Real-World Accessibility

LiveCaptionsXR addresses a real problem: traditional captioning systems flatten conversations into 2D space, ignoring **who is speaking** and **where they are**. This app goes beyond, showing "Person behind you said..." or "Speaker on your left said..." to anchor understanding in physical reality.

### 🚀 Built on Cutting-Edge On-Device AI

This is not just a demo. It's a serious technical showcase of what **on-device AI** can do:

* **whisper_ggml** for private, offline speech recognition
* **flutter_gemma** with Gemma 3n for contextual text enhancement
* **Live caption rendering** in 3D space (ARKit/ARCore)
* **Hybrid localization** combining audio, vision, and IMU data

### 🔍 Spatial Intelligence Engine

A fusion pipeline combines:

* **Audio direction estimation** (RMS, TDOA, GCC-PHAT) via `flutter_sound`
* **Camera-based speaker detection** using ML Kit
* **IMU orientation** data
* All fused with a **Kalman filter** to track the speaker in 3D and ensure accurate placement of captions.

---

## 🧠 Who Is It For?

* **Deaf and Hard of Hearing XR users**
* **Conference participants, students, or workers** needing spatial captioning
* **Developers and researchers** exploring offline-first multimodal AI
* Anyone interested in **AI for impact**, especially on-device accessibility

---

## 🔬 Powered by On-Device AI Stack

LiveCaptionsXR implements a sophisticated on-device AI pipeline:

* **whisper_ggml** for high-performance, offline speech recognition
* **flutter_gemma** with Gemma 3n for contextual text enhancement
* **Flutter/Dart MethodChannels** for seamless integration
* **Native AR rendering** via ARKit/ARCore for spatial caption placement

This approach provides **maximum privacy, performance, and hardware optimization**—essential for XR and mobile accessibility applications.

---

## 📦 Distribution Targets

* ✅ **Android XR Headsets (primary)**
* ✅ ARCore-enabled Android phones
* ⏳ iOS (pending ARKit/Microphone multi-stream permissions)

---

## 🌍 Why It Matters

There are **466 million people globally** with disabling hearing loss. Current solutions lack **contextual awareness**. LiveCaptionsXR enables:

* **Private, on-device accessibility**
* **Real-time situational awareness**
* **Immersive, captioned conversations**—even in XR

Built not just for performance, but for **purpose**.

---

## 🏁 Hackathon Alignment

This project is a submission to the [Google Gemma 3n Hackathon](https://www.kaggle.com/competitions/google-gemma-3n-hackathon), built to demonstrate:

* Real-world utility
* On-device multimodal intelligence
* Meaningful personal and societal impact

Its technical stack, architecture, and emotional story align with the competition's mission to build a better world using Gemma 3n.

---

## 🔗 Key Links

* [GitHub Repository](https://github.com/craigm26/LiveCaptionsXR/blob/main/docs/TECHNICAL_WRITEUP.md)
* [Technical Writeup](./docs/TECHNICAL_WRITEUP.md)
* [Hackathon Submission Guide](https://github.com/craigm26/LiveCaptionsXR/blob/main/docs/HACKATHON_SUBMISSION.md)
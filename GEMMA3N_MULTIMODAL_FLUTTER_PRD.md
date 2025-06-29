# Gemma 3n Multimodal Flutter Integration PRD

## Overview
This document outlines the requirements and step-by-step plan for building a custom Flutter package/API to support on-device inference with Google Gemma 3n multimodal `.task` models (text + image, and optionally audio) for the live_captions_xr app. The approach is inspired by [flutter_gemma](https://github.com/DenisovAV/flutter_gemma) but tailored for our specific accessibility and multimodal needs.

---

## Goals
- **Enable on-device inference** for Gemma 3n `.task` models in Flutter (Android/iOS, future web support).
- **Support multimodal input**: text, image, and (optionally) audio.
- **Expose a clean Dart API** for session-based and chat-based LLM usage.
- **Leverage a native inference engine** integrated manually on the native side for efficient model execution.
- **Future-proof** for LoRA, streaming, and additional modalities.

---

## Functional Requirements
1. **Model Loading**
   - Load a Gemma 3n `.task` file from Flutter assets.
   - Initialize the model on the native side (Android/iOS) using the native inference engine.

2. **Session Management**
   - Create and manage inference sessions (single-turn and chat/multi-turn).
   - Support session closing and resource cleanup.

3. **Multimodal Input**
   - Accept text-only, image-only, and text+image queries.
   - (Optional) Extend to audio input if model supports it.

4. **Inference & Response**
   - Run inference and return generated text responses.
   - Support both synchronous and streaming (token-by-token) responses.

5. **Dart API Design**
   - Provide classes such as `GemmaTaskModel`, `Session`, and `Message`.
   - Expose methods for adding query chunks, getting responses, and managing chat context.

6. **Platform Support**
   - Android and iOS (using platform channels or FFI).
   - Web (future, once a native inference engine supports it).

7. **Performance & Resource Management**
   - Support GPU/CPU backend selection.
   - Handle memory and session cleanup.

8. **Error Handling & Fallbacks**
   - Graceful error handling for missing models, unsupported modalities, or device limitations.

---

## Non-Functional Requirements
- **Open Source Friendly**: MIT or similar license for internal and community use.
- **Documentation**: Clear README, API docs, and usage examples.
- **Test Coverage**: Unit and integration tests for Dart and native code.
- **Accessibility**: Ensure API and sample apps are accessible.

---

## Step-by-Step Implementation Plan

### 1. Research & Design
- Study [flutter_gemma](https://github.com/DenisovAV/flutter_gemma) and native inference engine integration docs.
- Define the Dart API surface (classes, methods, message types).
- Decide on platform channel vs. FFI for native integration.

### 2. Project Setup
- Create a new Flutter package (e.g., `gemma3n_multimodal_flutter`).
- Set up example app for testing.

### 3. Native Integration
- **Android**: Implement Kotlin code to load and run `.task` files using the native inference engine.
- **iOS**: Implement Swift code for the same.
- Expose native methods via platform channels or FFI.

### 4. Dart API Implementation
- Implement `GemmaTaskModel` for model loading and lifecycle.
- Implement `Session` for single-turn and chat-based inference.
- Implement `Message` abstraction for text, image, and multimodal input.
- Add support for streaming responses.

### 5. Asset Management
- Document how to bundle `.task` files in Flutter assets.
- Implement asset loading logic in Dart and native code.

### 6. Multimodal Support
- Ensure API supports text-only, image-only, and text+image queries.
- (Optional) Prototype audio input support if the native inference engine allows.

### 7. Testing & Validation
- Write unit and integration tests for Dart and native code.
- Test on a range of Android and iOS devices (memory, performance, accuracy).
- Validate with real `.task` models (Gemma 3n E4B, etc.).

### 8. Documentation & Examples
- Write comprehensive README and API docs.
- Provide example app demonstrating multimodal inference.

### 9. Optimization & Release
- Profile performance (CPU/GPU, memory usage).
- Optimize for low-latency and low-memory devices.
- Prepare for open source release (if desired).

---

## References
- [flutter_gemma](https://github.com/DenisovAV/flutter_gemma)
- [MediaPipe LLM Inference Guide](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference)
- [Google Gemma Models on Kaggle](https://www.kaggle.com/models/google/gemma-3n/tfLite/gemma-3n-e4b-it-int4)

---

## Appendix: Example Dart API
```dart
final model = await GemmaTaskModel.create('assets/models/gemma3n_multimodal.task');
final session = await model.createSession(supportImage: true);

await session.addQueryChunk(Message.text(text: 'Describe this image', isUser: true));
await session.addQueryChunk(Message.imageOnly(imageBytes: imageBytes, isUser: true));
String response = await session.getResponse();

await session.close();
``` 
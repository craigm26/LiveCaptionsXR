# gemma3n_multimodal

A cross-platform Flutter plugin for **on-device, privacy-preserving, multimodal inference** with the Gemma 3n model (`.task` file), supporting real-time audio (ASR), image, and text input with streaming output. Powered by MediaPipe GenAI LLM Inference API for Android and iOS.

---

## Features
- **On-device inference**: No cloud required, all data stays on device.
- **Multimodal input**: Audio (PCM16), image, and text supported in any combination.
- **Streaming output**: Real-time partial results for ASR and multimodal tasks.
- **Cross-platform**: Android and iOS, with consistent Dart API.
- **Privacy-first**: No data leaves the device.

---

## Quick Start

### 1. Add Dependency
```yaml
dependencies:
  gemma3n_multimodal:
    path: ../plugins/gemma3n_multimodal # or use your registry
```

### 2. Model Requirements
- Download a MediaPipe-compatible Gemma 3n `.task` model (see [MediaPipe GenAI LLM Inference](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference)).
- Place the model on device storage (not bundled in APK/IPA due to size).

### 3. Permissions
- **Android**: Microphone (for ASR), storage (if loading model from external storage).
- **iOS**: Microphone (for ASR), file access for model.

---

## Dart API Reference

### Load/Unload Model
```dart
await plugin.loadModel('/path/to/model.task', useGPU: true); // useANE: true for iOS
await plugin.unloadModel();
bool loaded = await plugin.isModelLoaded;
```

### Transcribe Audio (ASR)
```dart
final result = await plugin.transcribeAudio(audioBytes); // PCM16 mono 16kHz
```

### Multimodal Inference
```dart
final result = await plugin.runMultimodal(audio: audioBytes, image: imageBytes, text: 'Describe this');
```

### Streaming Transcription
```dart
plugin.streamTranscription(audioBytes).listen((partial) {
  print('Partial: $partial');
});
```

### Streaming Multimodal
```dart
plugin.streamMultimodal(audio: audioBytes, image: imageBytes, text: 'Describe this').listen((partial) {
  print('Partial: $partial');
});
```

---

## Example: Live ASR
```dart
final plugin = Gemma3nMultimodal();
await plugin.loadModel('/path/to/model.task');
plugin.streamTranscription(audioBytes).listen((partial) {
  // Update UI with partial transcription
});
```

## Example: Multimodal Captioning
```dart
final plugin = Gemma3nMultimodal();
await plugin.loadModel('/path/to/model.task');
plugin.streamMultimodal(audio: audioBytes, image: imageBytes, text: 'What is happening?').listen((partial) {
  // Update UI with partial multimodal result
});
```

---

## Platform Notes
- **Android**: Model path must be accessible to the app. Use `useGPU: true` for best performance on supported devices.
- **iOS**: Use `useANE: true` to leverage Apple Neural Engine. Model path must be accessible (e.g., app sandbox).
- **Audio**: Input must be PCM16 mono, 16kHz, as required by Gemma 3n.

---

## Troubleshooting / FAQ
- **Q: Why do I get 'Model not loaded'?**
  - A: Call `loadModel` and await completion before inference.
- **Q: What format should audio be in?**
  - A: PCM16 mono, 16kHz. See example for conversion.
- **Q: How do I get partial results?**
  - A: Use the streaming APIs (`streamTranscription`, `streamMultimodal`).
- **Q: Can I use this in production?**
  - A: This plugin is experimental. Test thoroughly on your target devices.

---

## Roadmap
- [x] Model loading/unloading (Android/iOS)
- [x] Dart API & MethodChannel/EventChannel
- [x] Streaming inference (ASR, multimodal)
- [x] Testing & CI
- [ ] More advanced error handling
- [ ] Example app with UI
- [ ] Community contributions

---

## References
- [MediaPipe GenAI LLM Inference](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference)
- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [Plugin PRDs](./prd/)

---

## Contributing
Pull requests and issues are welcome! See the [CONTRIBUTING](CONTRIBUTING.md) guide (if available) or open an issue to discuss your use case.


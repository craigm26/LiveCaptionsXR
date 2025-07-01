# PRD: iOS Model Loading for gemma3n_multimodal Plugin

## Overview
The `gemma3n_multimodal` plugin provides on-device inference using Google's Gemma 3n model. This PRD describes how the model is loaded on iOS devices. Loading is performed via the `flutter_gemma` package, which wraps MediaPipe Tasks and provides a high level Dart API for model initialization.

## Goals
- Copy the `.task` model from the application bundle to a writable location on first launch.
- Initialize the model using `flutter_gemma` with hardware acceleration when available (ANE > GPU > CPU).
- Provide a Dart method `loadModel` returning a `Future<void>` that completes when initialization succeeds.
- Emit detailed errors when the model cannot be loaded.
- Record load time and chosen backend for debugging.

## Requirements
- Rely on `flutter_gemma` for the underlying model manager and initialization APIs.
- Support specifying the backend preference through the Dart API (`useANE`, `useGPU`).
- Verify file existence and available memory before loading.
- Log results via `print` statements during development; integrate with app logging later.
- Unit tests must mock `FlutterGemmaPlugin` to ensure correct method calls.

## Dart API
```dart
Future<void> loadModel(
  String path, {
  bool useANE = true,
  bool useGPU = false,
});
```
- `useANE` maps to `PreferredBackend.tpu` on iOS.
- When both flags are false the CPU backend is used.
- Throws an exception if initialization fails.

## Milestones
- [ ] Bundle copy utility written in Swift.
- [ ] Swift implementation calling `FlutterGemmaPlugin`.
- [ ] Dart wrapper with injectable `FlutterGemmaPlugin` for testing.
- [ ] Unit tests verifying path copy and plugin calls.

## References
- [MediaPipe GenAI iOS Docs](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference/ios)
- [flutter_gemma package](https://pub.dev/packages/flutter_gemma)
- [Flutter Plugin Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)

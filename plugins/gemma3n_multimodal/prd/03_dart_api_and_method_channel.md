# PRD: Dart API & MethodChannel Integration for gemma3n_multimodal Plugin

## Overview
Design and implement the Dart API and MethodChannel communication layer for the gemma3n_multimodal plugin, targeting the MediaPipe GenAI LLM Inference API and Gemma-3n `.task` model. This enables the Flutter app to interact with native model loading and multimodal inference features (audio, image, text) on both Android and iOS.

## Goals
- Expose a clean, high-level Dart API for model loading and multimodal inference.
- Implement MethodChannel communication for both Android and iOS using MediaPipe GenAI APIs.
- Ensure consistent API and error handling across platforms.

## Requirements
- Define Dart methods for model loading, audio transcription, and multimodal inference.
- Implement MethodChannel handlers in native code (Kotlin/Swift) that use MediaPipe GenAI LLM Inference API.
- Pass data (audio/image/text) as byte arrays or strings.
- Return results and errors to Dart in a consistent format.
- Document the Dart API with usage examples.

## Dart API Example
```dart
Future<void> loadModel(String path, {bool useGPU, bool useANE});
Future<String> transcribeAudio(Uint8List audioBytes);
Future<String> runMultimodal({Uint8List? audio, Uint8List? image, String? text});
```

## Milestones
- [ ] Define Dart API in `lib/gemma3n_multimodal.dart`
- [ ] Implement MethodChannel on Android (Kotlin) using MediaPipe GenAI
- [ ] Implement MethodChannel on iOS (Swift) using MediaPipe GenAI
- [ ] Consistent error/result handling
- [ ] Dart API documentation and usage examples
- [ ] Unit/integration tests

## References
- [MediaPipe GenAI LLM Inference](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference)
- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [Flutter Plugin API Design](https://docs.flutter.dev/development/packages-and-plugins/developing-packages) 
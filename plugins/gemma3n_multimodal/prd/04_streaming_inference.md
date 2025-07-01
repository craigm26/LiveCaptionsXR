# PRD: Streaming Inference for gemma3n_multimodal Plugin

## Overview
Implement streaming inference for Gemma 3n in the plugin, allowing partial (token-by-token or chunked) results to be sent from native code to Dart as they are generated. This enables real-time captioning and low-latency user experiences.

## Goals
- Support streaming output for ASR and multimodal inference.
- Use EventChannel to send partial results from native code to Dart.
- Ensure consistent API and error handling across Android and iOS.

## Requirements
- Implement native streaming callbacks using MediaPipe/GenAI APIs (e.g., `generateResponseAsync`).
- Forward partial results to Dart via EventChannel.
- Provide a Dart Stream API for listening to streaming results.
- Handle stream completion, errors, and cancellation.
- Document usage and best practices.

## Dart API Example
```dart
Stream<String> streamTranscription(Uint8List audioBytes);
Stream<String> streamMultimodal({Uint8List audio, Uint8List image, String text});
```

## Milestones
- [ ] Implement native streaming callbacks (Kotlin/Swift)
- [ ] Set up EventChannel for streaming results
- [ ] Dart Stream API for streaming inference
- [ ] Error/edge case handling (completion, cancellation, errors)
- [ ] Documentation and usage examples
- [ ] Unit/integration tests

## References
- [MediaPipe GenAI Streaming](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference)
- [Flutter EventChannel Docs](https://docs.flutter.dev/platform-integration/platform-channels#event-channels) 
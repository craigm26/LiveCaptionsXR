# PRD: iOS Model Loading for gemma3n_multimodal Plugin

## Overview
Implement native model loading for the Gemma 3n .task file on iOS using MediaPipe Tasks/GenAI or Google AI Edge SDK. This is the foundation for all inference features in the plugin on iOS.

## Goals
- Load the Gemma 3n .task model from app bundle or device storage.
- Support hardware acceleration (ANE/GPU/CPU fallback).
- Expose a Dart API to trigger model loading and report success/failure.

## Requirements
- Use MediaPipe's or Google AI Edge's iOS API to load the model from a file path.
- Copy the .task file from the app bundle to a writable location if needed.
- Handle errors (file not found, insufficient memory, etc.) gracefully.
- Log model loading time and backend used.

## Dart API
```dart
Future<void> loadModel(String path, {bool useANE, bool useGPU});
```
- Returns when the model is loaded and ready for inference.
- Throws on error (with descriptive message).

## Milestones
- [ ] Copy .task file from bundle to device storage
- [ ] Implement native model loading in Swift/ObjC
- [ ] Expose MethodChannel for Dart API
- [ ] Error handling and logging
- [ ] Unit/integration tests

## References
- [MediaPipe GenAI iOS Docs](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference/ios)
- [Flutter Plugin Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels) 
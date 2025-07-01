# PRD: Android Model Loading for gemma3n_multimodal Plugin

## Overview
In **LiveCaptionsXR**, all captioning runs directly on device using Google's Gemma 3n `.task` model. This document defines how the Android side of the `gemma3n_multimodal` plugin loads that model so the app can deliver the real-time, spatial captions described in the project's [README](../../README.md).

## Goals
- Provide a Kotlin implementation that loads the Gemma 3n `.task` file from assets or external storage.
- Support GPU acceleration when available with CPU/NNAPI fallback.
- Expose a simple Dart API so the Flutter layer knows when the model is ready.
- Keep initialization time low to maintain the app's fast startup.

## Requirements
- Copy the `.task` file from assets to a writable directory on first launch if direct asset access is not permitted.
- Use `LlmInference.createFromOptions` (MediaPipe/Google AI Edge) to initialize the model with hardware acceleration flags.
- Validate the file path and available memory before loading.
- Emit descriptive errors for missing files or unsupported hardware.
- Log the model path, selected backend and load time for troubleshooting.
- Provide a method to unload the model when the plugin is disposed.

## Dart API
```dart
Future<void> loadModel(String path, {bool useGPU = false});
Future<void> unloadModel();
bool get isModelLoaded;
```
- `loadModel` resolves when native loading completes or throws on error.
- `unloadModel` frees native resources.
- `isModelLoaded` allows the app to guard calls that require the model.

## Milestones
- [ ] Asset copy and storage permission handling
- [ ] Kotlin implementation using MediaPipe/Google AI Edge
- [ ] MethodChannel interface for `loadModel` and `unloadModel`
- [ ] Error propagation and logging
- [ ] Basic unit tests for the loader

## References
- [MediaPipe GenAI Android Docs](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference/android)
- [Flutter Plugin Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [LiveCaptionsXR README](../../README.md)


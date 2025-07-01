# PRD: Multimodal Input Handling for gemma3n_multimodal Plugin

## Overview
Implement support for multimodal inference (audio + image + text) in the plugin, leveraging the MediaPipe GenAI LLM Inference API and the Gemma-3n `.task` model. This enables the model to process and fuse multiple input types for richer, context-aware results, as supported by MediaPipe Tasks.

## Goals
- Accept and preprocess audio, image, and text inputs from Dart.
- Pass multimodal data to the native inference engine using MediaPipe GenAI's `LlmInference.MultimodalInput`.
- Ensure correct input ordering and data format for the model as per MediaPipe documentation.
- Expose a Dart API for multimodal inference.

## Requirements
- Validate and preprocess audio (mono, 16kHz, float32), image (JPEG/PNG), and text inputs.
- Package and send inputs to the native layer using the MediaPipe GenAI multimodal API.
- Handle missing/optional modalities gracefully (any combination of audio, image, text).
- Document supported input types and formats according to MediaPipe GenAI guidelines.

## Dart API Example
```dart
Future<String> runMultimodal({Uint8List? audio, Uint8List? image, String? text});
Stream<String> streamMultimodal({Uint8List? audio, Uint8List? image, String? text});
```

## Milestones
- [ ] Input validation and preprocessing (Dart/native)
- [ ] Native multimodal inference implementation using MediaPipe GenAI
- [ ] Dart API and documentation
- [ ] Unit/integration tests

## References
- [MediaPipe GenAI Multimodal](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference) 
# Product Requirements Document: Gemma 3n Native Plugin/FFI Integration

## Overview & Goals
- Build a cross-platform native plugin for Flutter that enables direct, on-device inference with the Gemma 3n model and its .task file.
- Support all Gemma 3n modalities: ASR (audio), AST (audio translation), multimodal (audio+image+text), and streaming.
- No Dart/Flutter inference packages will be used; all inference is handled natively (Swift/ObjC for iOS, Kotlin/Java for Android, C++/Rust as needed).
- Expose a simple, high-level Dart API for the main app via FFI or platform channels.

## Supported Platforms
- Android (Kotlin/Java, MediaPipe/Google AI Edge)
- iOS (Swift/ObjC, MediaPipe/Google AI Edge)
- (Optional/Future) macOS, Windows, Linux (C++/Rust)

## Native Technology Choices
- Use MediaPipe Tasks/GenAI or Google AI Edge SDK for model loading and inference.
- Use platform-native audio/image preprocessing as required by Gemma 3n.
- Use FFI or platform channels for Dart ↔ Native communication.

## Dart API Design
- Model loading: `Future<void> loadModel(String path, {bool useGPU})`
- Inference: `Future<String> transcribeAudio(Uint8List audioBytes)`
- Multimodal: `Future<String> runMultimodal({Uint8List audio, Uint8List? visual_snapshot, String text})`
- Streaming: `Stream<String> streamTranscription(Uint8List audioBytes)`

## Model Loading & Inference Flow
- Copy .task file from assets to device storage if needed.
- Initialize model with hardware acceleration (GPU/ANE/CPU fallback).
- Accept audio/image/text input from Dart, preprocess natively, and run inference.
- Return results (full or streaming) to Dart.

## Testing & CI/CD
- Unit and integration tests for native and Dart layers.
- CI pipeline to build, test, and package plugin for all supported platforms.

## Milestones & Deliverables
- [ ] Initial plugin scaffold (Android/iOS)
- [ ] Model loading and basic inference
- [ ] Multimodal and streaming support
- [ ] Dart API and documentation
- [ ] CI/CD integration
- [ ] Production-ready release

## References
- Google MediaPipe GenAI/Tasks documentation
- Gemma 3n model and .task file specs
- Flutter FFI and plugin development guides 
# Gemma 3n Native Plugin/FFI Starter Guide

## 1. Scaffold the Plugin
- Use `flutter create --template=plugin --platforms=android,ios gemma3n_plugin` to create a new plugin project.
- Organize native code in `android/` (Kotlin/Java) and `ios/` (Swift/ObjC) folders.

## 2. Add Native Dependencies
- Android: Add MediaPipe Tasks/GenAI or Google AI Edge SDK to `build.gradle`.
- iOS: Add MediaPipe Tasks/GenAI or Google AI Edge SDK via CocoaPods or Swift Package Manager.

## 3. Model Asset Management
- Place the `.task` file in the plugin or app assets.
- On first run, copy the model to device storage for native loading.

## 4. Native Model Loading
- Android: Use MediaPipe's `LlmInference.createFromOptions` with the model path.
- iOS: Use the equivalent MediaPipe/GenAI API to load the model.
- Enable hardware acceleration (GPU/ANE) if available.

## 5. Dart ↔ Native Communication
- Use MethodChannel for simple calls (model loading, inference).
- Use EventChannel for streaming responses (token-by-token output).
- Pass audio/image/text data as byte arrays or strings.

## 6. Dart API Example
```dart
await Gemma3nPlugin.loadModel('assets/gemma-3n-E4B-it-int4.task', useGPU: true);
final result = await Gemma3nPlugin.transcribeAudio(audioBytes);
final multimodal = await Gemma3nPlugin.runMultimodal(audio: audioBytes, image: imageBytes, text: 'Describe the scene');
Gemma3nPlugin.streamTranscription(audioBytes).listen((token) => print(token));
```

## 7. Testing & Debugging
- Write unit tests for Dart and native code.
- Use device/emulator logs to debug native model loading and inference.
- Validate output against reference Python/HuggingFace results.

## 8. CI/CD Integration
- Add build/test steps for Android and iOS native code.
- Package and publish the plugin for internal or public use.

## References
- [Google MediaPipe GenAI/Tasks](https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference)
- [Flutter Plugin Development](https://docs.flutter.dev/development/packages-and-plugins/developing-packages)
- [FFI Documentation](https://dart.dev/guides/libraries/c-interop) 
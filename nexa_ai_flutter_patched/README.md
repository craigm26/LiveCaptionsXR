# nexa_ai_flutter

Flutter plugin for the Nexa AI SDK. Run AI models directly on Android devices - LLMs, vision models, embeddings, speech recognition, and more. Works with Qualcomm NPU, GPU, and CPU.

## What's This About?

This plugin lets you run AI models on Android phones without needing internet or cloud services. It's built on top of Nexa AI's Android SDK and supports hardware acceleration through Qualcomm's NPU (Neural Processing Unit).

**Supported Models:**
- Large Language Models (text generation, chat)
- Vision-Language Models (image understanding)
- Text Embeddings (semantic search, RAG)
- Speech Recognition
- Document Reranking
- Computer Vision (OCR)

## Quick Start

Add to your `pubspec.yaml`:

```yaml
dependencies:
  nexa_ai_flutter: ^0.0.1
```

Initialize in your app:

```dart
import 'package:nexa_ai_flutter/nexa_ai_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NexaSdk.getInstance().init();
  runApp(MyApp());
}
```

## Requirements

**Android Only** (for now)
- Min SDK 27 (Android 8.1+)
- ARM64 device
- Kotlin 2.1.0+

**Best Performance:**
- Snapdragon 8 Gen 3 or 8 Gen 4 (NPU support)
- Other Snapdragon 8 series work fine with GPU
- Any ARM64 device will work with CPU (slower)

## Downloading Models

The plugin includes 8 ready-to-use models. Here's how to get them:

### See what's available

```dart
final models = await ModelDownloader.getAvailableModels();

for (var model in models) {
  print('${model.displayName} - ${model.sizeGb} GB');
  print('Type: ${model.type}');
}
```

### Download with progress

```dart
ModelDownloader().downloadModel('SmolVLM-256M-Instruct-f16').listen(
  (progress) {
    if (progress.status == DownloadStatus.downloading) {
      print('${progress.percentage}% at ${progress.speedMBps.toStringAsFixed(1)} MB/s');
    } else if (progress.status == DownloadStatus.completed) {
      print('Done!');
    }
  },
);
```

### Cancel if needed

```dart
await ModelDownloader.cancelDownload('model-id');
```

### Check device compatibility

```dart
final compat = await ModelDownloader.checkModelCompatibility('SmolVLM-256M-Instruct-f16');

if (compat.isCompatible) {
  print('This model will run ${compat.speedText} on your device');
  print(compat.recommendation);
}
```

### Available models

| Model | Size | Type | Notes |
|-------|------|------|-------|
| SmolVLM-256M-Instruct-f16 | 0.48 GB | Vision+Chat | Good for testing, works on most devices |
| LFM2-1.2B-GGUF | 0.75 GB | Chat | Fast chat model |
| OmniNeural-4B | 4 GB | Vision+Chat | Better quality, needs good device |
| LFM2-1.2B-npu | 0.75 GB | Chat | NPU optimized |
| embeddinggemma-300m-npu | 0.25 GB | Embeddings | For semantic search |
| parakeet-tdt-0.6b-v3-npu | 0.6 GB | Speech-to-text | Audio transcription |
| jina-v2-rerank-npu | 1.0 GB | Reranking | Search improvement |
| paddleocr-npu | 0.25 GB | OCR | Text recognition |

Models are saved to `/data/data/{your_package}/files/models/`

## Using the Models

### Chat with LLM

```dart
// Load the model
final llm = await LlmWrapper.create(
  LlmCreateInput(
    modelPath: '/path/to/model.gguf',
    config: ModelConfig(nCtx: 4096, maxTokens: 2048),
    pluginId: 'cpu_gpu', // or 'npu' if your device supports it
  ),
);

// Have a conversation
final messages = [
  ChatMessage('user', 'What is machine learning?'),
];

final template = await llm.applyChatTemplate(messages);

llm.generateStream(template.formattedText, GenerationConfig(maxTokens: 512)).listen(
  (result) {
    if (result is LlmStreamToken) {
      print(result.text); // Prints token by token
    } else if (result is LlmStreamCompleted) {
      print('\nDone! Speed: ${result.profile.decodingSpeed.toStringAsFixed(1)} tokens/sec');
    }
  },
);

// Clean up when done
await llm.destroy();
```

### Vision + Language

```dart
final vlm = await VlmWrapper.create(
  VlmCreateInput(
    modelPath: '/path/to/model',
    config: ModelConfig(maxTokens: 2048),
    pluginId: 'cpu_gpu',
  ),
);

// Ask about an image
final message = VlmChatMessage('user', [
  VlmContent('image', '/path/to/photo.jpg'),
  VlmContent('text', 'What do you see?'),
]);

final template = await vlm.applyChatTemplate([message]);
final config = vlm.injectMediaPathsToConfig([message], GenerationConfig(maxTokens: 512));

vlm.generateStream(template.formattedText, config).listen((result) {
  // Same as LLM streaming
});

await vlm.destroy();
```

### Text Embeddings

```dart
final embedder = await EmbedderWrapper.create(
  EmbedderCreateInput(
    modelPath: '/path/to/embedder',
    config: ModelConfig(),
    pluginId: 'cpu_gpu',
  ),
);

final embeddings = await embedder.embed(
  ['Hello world', 'Machine learning is cool'],
  EmbeddingConfig(normalize: true),
);

print('Got ${embeddings.length} values');
await embedder.destroy();
```

### Speech Recognition

```dart
final asr = await AsrWrapper.create(
  AsrCreateInput(
    modelPath: '/path/to/asr',
    config: ModelConfig(),
    pluginId: 'cpu_gpu',
  ),
);

final result = await asr.transcribe(
  AsrTranscribeInput(
    audioPath: '/path/to/audio.wav',
    language: 'en',
  ),
);

print('Transcript: ${result.result.transcript}');
await asr.destroy();
```

### Document Reranking

```dart
final reranker = await RerankerWrapper.create(
  RerankerCreateInput(
    modelPath: '/path/to/reranker',
    config: ModelConfig(),
    pluginId: 'cpu_gpu',
  ),
);

final result = await reranker.rerank(
  'What is deep learning?',
  [
    'Neural networks are used in deep learning',
    'The weather is nice today',
    'Deep learning tutorial for beginners',
  ],
  RerankConfig(topN: 3),
);

// Results are sorted by relevance score
for (var i = 0; i < result.scores.length; i++) {
  print('${result.scores[i].toStringAsFixed(3)}: ${result.documents[i]}');
}

await reranker.destroy();
```

### OCR / Computer Vision

```dart
final cv = await CvWrapper.create(
  CVCreateInput(
    modelName: 'paddleocr',
    config: CVModelConfig(
      capabilities: CVCapability.ocr,
      detModelPath: '/path/to/detection',
      recModelPath: '/path/to/recognition',
      charDictPath: '/path/to/dict',
    ),
    pluginId: 'npu',
  ),
);

final results = await cv.infer('/path/to/image.jpg');

for (var result in results) {
  print('Found text: ${result.text}');
  print('Confidence: ${result.confidence}');
}

await cv.destroy();
```

## Model Name Reference (NPU Models)

If you're using NPU-optimized models, you need to specify the model name:

| Model | Name to Use | Plugin |
|-------|-------------|--------|
| LFM2-1.2B-npu | liquid-v2 | npu |
| OmniNeural-4B | omni-neural | npu |
| embeddinggemma-300m-npu | embed-gemma | npu |
| parakeet-tdt-0.6b-v3-npu | parakeet | npu |
| jina-v2-rerank-npu | jina-rerank | npu |
| paddleocr-npu | paddleocr | npu |

For GGUF models, just use the file path and `pluginId: 'cpu_gpu'`.

## Tips

**Choose the right hardware:**
- Use `pluginId: 'npu'` on Snapdragon 8 Gen 3/4 for best performance
- Use `pluginId: 'cpu_gpu'` for everything else
- Check compatibility first with `checkModelCompatibility()`

**Memory management:**
- Always call `.destroy()` when you're done with a model
- Don't load multiple large models at once
- Use streaming for LLM/VLM to show results faster

**Generation settings:**
```dart
GenerationConfig(
  maxTokens: 512,
  samplerConfig: SamplerConfig(
    temperature: 0.7,  // Lower = more focused, Higher = more creative
    topK: 40,
    topP: 0.95,
  ),
)
```

**Managing conversations:**
```dart
List<ChatMessage> history = [];

// Add messages to history
history.add(ChatMessage('user', 'Hello'));
history.add(ChatMessage('assistant', response));
history.add(ChatMessage('user', 'Follow-up question'));

// Apply template with full history
final template = await llm.applyChatTemplate(history);

// Reset if needed
await llm.reset();
```

## Example App

Check the `/example` folder for a complete app that shows:
- Model downloading with progress
- Device compatibility detection
- Model management (download/delete)
- Interactive chat with streaming
- Storage monitoring

Run it with:
```bash
cd example
flutter run
```

## Limitations

- Android only right now
- Models need to be downloaded first (they're big)
- NPU only works on specific Qualcomm chips
- File paths must be absolute and readable by your app

## Getting Help

- File bugs: https://github.com/bhanuka96/nexa_ai_flutter/issues
- Nexa AI docs: https://docs.nexaai.com/

## Credits

Built using Nexa AI Android SDK v0.0.10. Thanks to the Nexa AI team for the underlying SDK.

## License

MIT License - see LICENSE file

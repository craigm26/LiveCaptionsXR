# Model Download Feature - Implementation Guide

## ✅ Completed Components

### 1. Dart Layer
- ✅ `lib/models/download_models.dart` - Download model classes
- ✅ `lib/model_downloader.dart` - Public API for downloads
- ✅ `assets/model_list.json` - Bundled model list
- ✅ `pubspec.yaml` - Assets configuration

### 2. Kotlin Layer
- ✅ `ModelDownloadManager.kt` - Core download logic with OkHttp
- ✅ `DownloadProgressHandler.kt` - EventChannel handler
- ✅ `android/build.gradle` - Dependencies added:
  - `kotlinx-serialization-json:1.6.0`
  - `okhttp:4.12.0`
  - `kotlin-serialization` plugin

## 🔧 Remaining Work

### Step 1: Update NexaAiFlutterPlugin.kt

Add the following to the plugin class at `/Users/bhanukaisuru/Desktop/nexa_ai_flutter/android/src/main/kotlin/com/example/nexa_ai_flutter/NexaAiFlutterPlugin.kt`:

#### 1.1 Add fields (after existing fields):
```kotlin
private lateinit var downloadProgressChannel: EventChannel
private lateinit var downloadManager: ModelDownloadManager
```

#### 1.2 Update onAttachedToEngine (add after vlmStreamChannel):
```kotlin
downloadManager = ModelDownloadManager(context)

downloadProgressChannel = EventChannel(flutterPluginBinding.binaryMessenger, "nexa_ai_flutter/download_progress")
downloadProgressChannel.setStreamHandler(DownloadProgressHandler(downloadManager, modelScope))
```

#### 1.3 Add download method handlers (add these methods before onDetachedFromEngine):
```kotlin
private fun getAvailableModels(result: Result) {
    try {
        val models = downloadManager.getAvailableModels()
        result.success(models)
    } catch (e: Exception) {
        result.error("GET_MODELS_ERROR", e.message, null)
    }
}

private fun isModelDownloaded(call: MethodCall, result: Result) {
    try {
        val modelId = call.argument<String>("modelId")!!
        val isDownloaded = downloadManager.isModelDownloaded(modelId)
        result.success(isDownloaded)
    } catch (e: Exception) {
        result.error("CHECK_DOWNLOAD_ERROR", e.message, null)
    }
}

private fun getModelPath(call: MethodCall, result: Result) {
    try {
        val modelId = call.argument<String>("modelId")!!
        val path = downloadManager.getModelPath(modelId)
        result.success(path)
    } catch (e: Exception) {
        result.error("GET_PATH_ERROR", e.message, null)
    }
}

private fun cancelDownload(call: MethodCall, result: Result) {
    try {
        val modelId = call.argument<String>("modelId")!!
        downloadManager.cancelDownload(modelId)
        result.success(null)
    } catch (e: Exception) {
        result.error("CANCEL_ERROR", e.message, null)
    }
}

private fun deleteModel(call: MethodCall, result: Result) {
    try {
        val modelId = call.argument<String>("modelId")!!
        downloadManager.deleteModel(modelId)
        result.success(null)
    } catch (e: Exception) {
        result.error("DELETE_ERROR", e.message, null)
    }
}

private fun getStorageInfo(result: Result) {
    try {
        val info = downloadManager.getStorageInfo()
        result.success(info)
    } catch (e: Exception) {
        result.error("STORAGE_INFO_ERROR", e.message, null)
    }
}

private fun getModelsDirectory(result: Result) {
    try {
        val dir = downloadManager.getModelsDirectory()
        result.success(dir.absolutePath)
    } catch (e: Exception) {
        result.error("GET_DIR_ERROR", e.message, null)
    }
}

private fun cleanupIncompleteDownloads(result: Result) {
    try {
        downloadManager.cleanupIncompleteDownloads()
        result.success(null)
    } catch (e: Exception) {
        result.error("CLEANUP_ERROR", e.message, null)
    }
}

private fun getDownloadedModels(result: Result) {
    try {
        val models = downloadManager.getDownloadedModels()
        result.success(models)
    } catch (e: Exception) {
        result.error("GET_DOWNLOADED_ERROR", e.message, null)
    }
}
```

#### 1.4 Update onMethodCall (add to the when block):
```kotlin
// Download methods
"getAvailableModels" -> getAvailableModels(result)
"isModelDownloaded" -> isModelDownloaded(call, result)
"getModelPath" -> getModelPath(call, result)
"cancelDownload" -> cancelDownload(call, result)
"deleteModel" -> deleteModel(call, result)
"getStorageInfo" -> getStorageInfo(result)
"getModelsDirectory" -> getModelsDirectory(result)
"cleanupIncompleteDownloads" -> cleanupIncompleteDownloads(result)
"getDownloadedModels" -> getDownloadedModels(result)
```

#### 1.5 Update onDetachedFromEngine:
```kotlin
override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    llmStreamChannel.setStreamHandler(null)
    vlmStreamChannel.setStreamHandler(null)
    downloadProgressChannel.setStreamHandler(null)
    modelScope.cancel()
}
```

### Step 2: Update README.md

Add a new section after "## Getting Started":

```markdown
## Model Management

### Downloading Pre-trained Models

The plugin includes a built-in model downloader for easy access to official Nexa AI models.

#### 1. Get Available Models

\`\`\`dart
final models = await ModelDownloader.getAvailableModels();

for (var model in models) {
  print('${model.displayName} - ${model.sizeGb} GB');
  print('Features: ${model.features.join(", ")}');
}
\`\`\`

#### 2. Download a Model with Progress

\`\`\`dart
ModelDownloader downloader = ModelDownloader();

downloader.downloadModel('OmniNeural-4B').listen(
  (progress) {
    if (progress.status == DownloadStatus.downloading) {
      print('${progress.percentage}% - ${progress.speedMBps.toStringAsFixed(2)} MB/s');
    } else if (progress.status == DownloadStatus.completed) {
      print('Download completed!');
    } else if (progress.status == DownloadStatus.failed) {
      print('Download failed');
    }
  },
  onError: (error) {
    print('Error: $error');
  },
);
\`\`\`

#### 3. Check if Model is Downloaded

\`\`\`dart
bool isDownloaded = await ModelDownloader.isModelDownloaded('OmniNeural-4B');
if (isDownloaded) {
  String? path = await ModelDownloader.getModelPath('OmniNeural-4B');
  print('Model available at: $path');
}
\`\`\`

#### 4. Use Downloaded Model

\`\`\`dart
// Get the model path
String? modelPath = await ModelDownloader.getModelPath('OmniNeural-4B');

if (modelPath != null) {
  // Create VLM with the downloaded model
  final vlm = await VlmWrapper.create(
    VlmCreateInput(
      modelName: 'omni-neural',
      modelPath: modelPath,
      config: ModelConfig(maxTokens: 2048),
      pluginId: 'npu',
    ),
  );

  // Use the model...
}
\`\`\`

#### 5. Manage Storage

\`\`\`dart
// Get storage information
final storage = await ModelDownloader.getStorageInfo();
print('Total: ${storage.totalSpaceGB.toStringAsFixed(2)} GB');
print('Free: ${storage.freeSpaceGB.toStringAsFixed(2)} GB');
print('Used by models: ${storage.usedByModelsGB.toStringAsFixed(2)} GB');

// Delete a model to free space
await ModelDownloader.deleteModel('OmniNeural-4B');

// Get list of downloaded models
List<String> downloaded = await ModelDownloader.getDownloadedModels();
print('Downloaded models: ${downloaded.join(", ")}');
\`\`\`

### Available Models

The plugin includes the following pre-configured models:

| Model ID | Name | Type | Size | Features |
|----------|------|------|------|----------|
| OmniNeural-4B | OmniNeural-4B | VLM | 4 GB | Chat, Vision |
| paddleocr-npu | PaddleOCR NPU | CV | 0.25 GB | OCR |
| parakeet-tdt-0.6b-v3-npu | Parakeet ASR | ASR | 0.6 GB | Speech-to-Text |
| embeddinggemma-300m-npu | Embedding Gemma | Embedder | 0.25 GB | Embeddings |
| jina-v2-rerank-npu | Jina Reranker | Reranker | 1.0 GB | Reranking |
| LFM2-1.2B-npu | LFM2 Chat | LLM | 0.75 GB | Chat |
| SmolVLM-256M-Instruct-f16 | SmolVLM | VLM | 0.48 GB | Chat, Vision |
| LFM2-1.2B-GGUF-GGUF | LFM2 GGUF | LLM | 0.75 GB | Chat |

\`\`\`
```

## Testing

1. Build the plugin:
   ```bash
   cd /Users/bhanukaisuru/Desktop/nexa_ai_flutter
   flutter pub get
   ```

2. Test in the example app:
   ```bash
   cd example
   flutter run
   ```

3. Test download functionality:
   ```dart
   final models = await ModelDownloader.getAvailableModels();
   print('Found ${models.length} models');
   ```

## Next Steps

1. ✅ Complete plugin integration (add methods to NexaAiFlutterPlugin.kt)
2. ⏭️ Create model management UI in example app
3. ⏭️ Update README with download documentation
4. ⏭️ Test on actual Android device with NPU support

## Notes

- Models are downloaded to: `/data/data/{package}/files/models/`
- Download state is tracked in SharedPreferences
- OkHttp handles all network operations
- Progress is streamed via EventChannel
- Downloads can be cancelled anytime
- Multiple files per model are downloaded sequentially

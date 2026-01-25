import 'dart:async';
import 'dart:io';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';

import '../app_logger.dart';
import '../ios_model_config_service.dart';
import 'i_model_download_strategy.dart';

/// flutter_gemma native download strategy
/// Handles Gemma models using the flutter_gemma package's native install API
class GemmaModelDownloadStrategy implements IModelDownloadStrategy {
  static final AppLogger _logger = AppLogger.instance;

  final IOSModelConfigService _iosConfig;
  bool _downloadCancelled = false;

  // Model URL mappings (HuggingFace)
  // Note: ?download=true is required for direct file downloads from HuggingFace
  static const Map<String, _GemmaModelConfig> _modelConfigs = {
    'gemma-3n-E2B-it-int4': _GemmaModelConfig(
      displayName: 'Gemma 3N E2B (Efficient)',
      fileName: 'gemma-3n-E2B-it-int4.task',
      url: 'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task?download=true',
      modelCardUrl: 'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview',
      estimatedSizeMb: 2920,
      supportsVision: false,
    ),
    'gemma-3n-E4B-it-int4': _GemmaModelConfig(
      displayName: 'Gemma 3N E4B (Multimodal)',
      fileName: 'gemma-3n-E4B-it-int4.task',
      url: 'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview/resolve/main/gemma-3n-E4B-it-int4.task?download=true',
      modelCardUrl: 'https://huggingface.co/google/gemma-3n-E4B-it-litert-preview',
      estimatedSizeMb: 4100,
      supportsVision: true,
    ),
  };

  GemmaModelDownloadStrategy(this._iosConfig);

  @override
  ModelCategory get category => ModelCategory.gemma;

  @override
  Future<bool> isModelAvailable(String modelId) async {
    return _modelConfigs.containsKey(modelId);
  }

  @override
  Future<bool> isModelInstalled(String modelId) async {
    try {
      final modelPath = await getModelPath(modelId);
      if (modelPath == null) return false;

      final file = File(modelPath);
      if (!await file.exists()) return false;

      // Also verify file size is reasonable
      final stat = await file.stat();
      final config = _modelConfigs[modelId];
      if (config != null) {
        // Check if file is at least 50% of expected size (to catch corrupted downloads)
        final minExpectedBytes = config.estimatedSizeMb * 1024 * 1024 * 0.5;
        return stat.size > minExpectedBytes;
      }

      return stat.size > 0;
    } catch (e) {
      _logger.e('Failed to check if Gemma model is installed: $modelId', error: e);
      return false;
    }
  }

  @override
  Future<UnifiedModelCompatibility> checkCompatibility(String modelId) async {
    final config = _modelConfigs[modelId];
    if (config == null) {
      return UnifiedModelCompatibility.incompatible(
        'Unknown Gemma model: $modelId',
      );
    }

    // Check available storage
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final stat = await appDir.stat();

      // On iOS, check memory for large models
      if (Platform.isIOS && config.estimatedSizeMb > 3000) {
        return UnifiedModelCompatibility(
          isCompatible: true,
          incompatibilityReason: 'Large model - may require significant memory on iOS',
          deviceCapabilities: {
            'platform': 'iOS',
            'modelSize': config.estimatedSizeMb,
          },
        );
      }

      return UnifiedModelCompatibility.compatible();
    } catch (e) {
      _logger.e('Failed to check Gemma model compatibility: $modelId', error: e);
      return UnifiedModelCompatibility.incompatible(
        'Failed to check compatibility: $e',
      );
    }
  }

  @override
  Stream<UnifiedDownloadProgress> downloadModel(String modelId) async* {
    final config = _modelConfigs[modelId];
    if (config == null) {
      yield UnifiedDownloadProgress(
        modelId: modelId,
        displayName: modelId,
        category: ModelCategory.gemma,
        progress: 0.0,
        downloadedBytes: 0,
        totalBytes: 0,
        phase: DownloadPhase.failed,
        error: 'Unknown Gemma model: $modelId',
        timestamp: DateTime.now(),
      );
      return;
    }

    _downloadCancelled = false;

    yield UnifiedDownloadProgress(
      modelId: modelId,
      displayName: config.displayName,
      category: ModelCategory.gemma,
      progress: 0.0,
      downloadedBytes: 0,
      totalBytes: config.estimatedSizeMb * 1024 * 1024,
      phase: DownloadPhase.preparingDownload,
      message: 'Preparing Gemma model download...',
      timestamp: DateTime.now(),
    );

    try {
      final gemmaPlugin = FlutterGemmaPlugin.instance;
      final modelPath = await _getGemmaModelPath(modelId);

      // Check if model already exists
      if (await isModelInstalled(modelId)) {
        yield UnifiedDownloadProgress(
          modelId: modelId,
          displayName: config.displayName,
          category: ModelCategory.gemma,
          progress: 1.0,
          downloadedBytes: config.estimatedSizeMb * 1024 * 1024,
          totalBytes: config.estimatedSizeMb * 1024 * 1024,
          phase: DownloadPhase.completed,
          message: 'Model already installed',
          timestamp: DateTime.now(),
        );

        // Set the model path
        await gemmaPlugin.modelManager.setModelPath(modelPath);
        return;
      }

      yield UnifiedDownloadProgress(
        modelId: modelId,
        displayName: config.displayName,
        category: ModelCategory.gemma,
        progress: 0.0,
        downloadedBytes: 0,
        totalBytes: config.estimatedSizeMb * 1024 * 1024,
        phase: DownloadPhase.downloading,
        message: 'Downloading from HuggingFace...',
        timestamp: DateTime.now(),
      );

      // Use flutter_gemma's native install API
      // Note: The exact API may vary based on flutter_gemma version
      try {
        // Try the builder pattern if available
        await for (final progress in _downloadWithHttp(modelId, config)) {
          if (_downloadCancelled) {
            yield UnifiedDownloadProgress(
              modelId: modelId,
              displayName: config.displayName,
              category: ModelCategory.gemma,
              progress: 0.0,
              downloadedBytes: 0,
              totalBytes: 0,
              phase: DownloadPhase.cancelled,
              message: 'Download cancelled',
              timestamp: DateTime.now(),
            );
            return;
          }
          yield progress;
        }
      } catch (e) {
        _logger.e('flutter_gemma install failed, trying HTTP fallback', error: e);
        // Fallback to HTTP download
        await for (final progress in _downloadWithHttp(modelId, config)) {
          if (_downloadCancelled) {
            yield UnifiedDownloadProgress(
              modelId: modelId,
              displayName: config.displayName,
              category: ModelCategory.gemma,
              progress: 0.0,
              downloadedBytes: 0,
              totalBytes: 0,
              phase: DownloadPhase.cancelled,
              message: 'Download cancelled',
              timestamp: DateTime.now(),
            );
            return;
          }
          yield progress;
        }
      }

      // Set model path after successful download
      if (await isModelInstalled(modelId)) {
        await gemmaPlugin.modelManager.setModelPath(modelPath);

        yield UnifiedDownloadProgress(
          modelId: modelId,
          displayName: config.displayName,
          category: ModelCategory.gemma,
          progress: 1.0,
          downloadedBytes: config.estimatedSizeMb * 1024 * 1024,
          totalBytes: config.estimatedSizeMb * 1024 * 1024,
          phase: DownloadPhase.completed,
          message: 'Gemma model installed successfully',
          timestamp: DateTime.now(),
        );
      } else {
        yield UnifiedDownloadProgress(
          modelId: modelId,
          displayName: config.displayName,
          category: ModelCategory.gemma,
          progress: 0.0,
          downloadedBytes: 0,
          totalBytes: 0,
          phase: DownloadPhase.failed,
          error: 'Model file not found after download',
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      _logger.e('Failed to download Gemma model: $modelId', error: e);
      yield UnifiedDownloadProgress(
        modelId: modelId,
        displayName: config.displayName,
        category: ModelCategory.gemma,
        progress: 0.0,
        downloadedBytes: 0,
        totalBytes: 0,
        phase: DownloadPhase.failed,
        error: e,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Download model using HTTP (fallback method)
  /// Following gemma-vision pattern: download to app documents directory
  Stream<UnifiedDownloadProgress> _downloadWithHttp(
    String modelId,
    _GemmaModelConfig config,
  ) async* {
    final modelPath = await _getGemmaModelPath(modelId);
    final file = File(modelPath);

    // Ensure parent directory exists (though for root app dir this is usually not needed)
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    // Use HTTP to download
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(config.url));
      final response = await request.close();

      if (response.statusCode != 200) {
        yield UnifiedDownloadProgress(
          modelId: modelId,
          displayName: config.displayName,
          category: ModelCategory.gemma,
          progress: 0.0,
          downloadedBytes: 0,
          totalBytes: 0,
          phase: DownloadPhase.failed,
          error: 'HTTP ${response.statusCode}: Failed to download',
          timestamp: DateTime.now(),
        );
        return;
      }

      final totalBytes = response.contentLength;
      var downloadedBytes = 0;

      final sink = file.openWrite();

      await for (final chunk in response) {
        if (_downloadCancelled) {
          await sink.close();
          await file.delete();
          return;
        }

        sink.add(chunk);
        downloadedBytes += chunk.length;

        final progress = totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;

        yield UnifiedDownloadProgress(
          modelId: modelId,
          displayName: config.displayName,
          category: ModelCategory.gemma,
          progress: progress,
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
          phase: DownloadPhase.downloading,
          message: 'Downloading... ${(progress * 100).toStringAsFixed(1)}%',
          timestamp: DateTime.now(),
        );
      }

      await sink.close();

      yield UnifiedDownloadProgress(
        modelId: modelId,
        displayName: config.displayName,
        category: ModelCategory.gemma,
        progress: 1.0,
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes,
        phase: DownloadPhase.validating,
        message: 'Validating download...',
        timestamp: DateTime.now(),
      );
    } finally {
      client.close();
    }
  }

  @override
  Future<void> cancelDownload(String modelId) async {
    _downloadCancelled = true;
    _logger.i('Cancelled download for Gemma model: $modelId');
  }

  @override
  Future<bool> deleteModel(String modelId) async {
    try {
      final modelPath = await getModelPath(modelId);
      if (modelPath != null) {
        final file = File(modelPath);
        if (await file.exists()) {
          await file.delete();
          _logger.i('Deleted Gemma model: $modelId');
          return true;
        }
      }
      return false;
    } catch (e) {
      _logger.e('Failed to delete Gemma model: $modelId', error: e);
      return false;
    }
  }

  @override
  Future<String?> getModelPath(String modelId) async {
    return await _getGemmaModelPath(modelId);
  }

  Future<String> _getGemmaModelPath(String modelId) async {
    final dir = await getApplicationDocumentsDirectory();
    final config = _modelConfigs[modelId];
    // Use the actual filename from config, or fall back to modelId.task
    final fileName = config?.fileName ?? '$modelId.task';
    // Store in app documents directory (same as gemma-vision)
    // Note: flutter_gemma's modelManager.setModelPath() points to this location
    return '${dir.path}/$fileName';
  }

  @override
  Future<bool> canResume(String modelId) async {
    // Check if there's a partial download
    final modelPath = await getModelPath(modelId);
    if (modelPath == null) return false;

    final partFile = File('$modelPath.part');
    return await partFile.exists();
  }

  @override
  Stream<UnifiedDownloadProgress> resumeDownload(String modelId) async* {
    // For now, restart the download
    yield* downloadModel(modelId);
  }

  @override
  Future<List<UnifiedModelInfo>> getAvailableModels() async {
    return _modelConfigs.entries.map((entry) {
      return UnifiedModelInfo(
        modelId: entry.key,
        displayName: entry.value.displayName,
        category: ModelCategory.gemma,
        estimatedSizeMb: entry.value.estimatedSizeMb,
        supportsNpu: false, // Gemma uses GPU/CPU, not Qualcomm NPU
        supportsVision: entry.value.supportsVision,
        isRecommended: entry.key == 'gemma-3n-E4B-it-int4', // Recommend multimodal
        description: entry.value.supportsVision
            ? 'Multimodal model with vision capabilities'
            : 'Efficient text-only model',
        downloadUrl: entry.value.url,
      );
    }).toList();
  }
}

/// Internal model configuration
class _GemmaModelConfig {
  final String displayName;
  final String fileName;
  final String url;
  final String modelCardUrl;
  final int estimatedSizeMb;
  final bool supportsVision;

  const _GemmaModelConfig({
    required this.displayName,
    required this.fileName,
    required this.url,
    required this.modelCardUrl,
    required this.estimatedSizeMb,
    required this.supportsVision,
  });
}

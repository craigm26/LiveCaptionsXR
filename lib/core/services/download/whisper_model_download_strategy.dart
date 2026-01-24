import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../app_logger.dart';
import '../model_download_manager.dart';
import 'i_model_download_strategy.dart';

/// Legacy HTTP-based download strategy for Whisper models
/// Wraps the existing ModelDownloadManager for backward compatibility
class WhisperModelDownloadStrategy implements IModelDownloadStrategy {
  static final AppLogger _logger = AppLogger.instance;

  final ModelDownloadManager _legacyManager;
  bool _downloadCancelled = false;

  // Whisper model configurations
  static const Map<String, _WhisperModelConfig> _modelConfigs = {
    'whisper-base': _WhisperModelConfig(
      displayName: 'Whisper Base',
      estimatedSizeMb: 141,
      description: 'Base model for real-time transcription',
    ),
    'whisper-small': _WhisperModelConfig(
      displayName: 'Whisper Small',
      estimatedSizeMb: 466,
      description: 'Higher accuracy transcription model',
    ),
    'whisper-tiny': _WhisperModelConfig(
      displayName: 'Whisper Tiny',
      estimatedSizeMb: 75,
      description: 'Fastest, lowest memory transcription model',
    ),
  };

  WhisperModelDownloadStrategy(this._legacyManager);

  @override
  ModelCategory get category => ModelCategory.whisper;

  @override
  Future<bool> isModelAvailable(String modelId) async {
    return _modelConfigs.containsKey(modelId) ||
           _legacyManager.availableModels.contains(modelId);
  }

  @override
  Future<bool> isModelInstalled(String modelId) async {
    try {
      // Check via legacy manager first
      if (await _legacyManager.modelIsComplete(modelId)) {
        return true;
      }

      // Fallback to file check
      final modelPath = await getModelPath(modelId);
      if (modelPath == null) return false;

      final file = File(modelPath);
      return await file.exists();
    } catch (e) {
      _logger.e('Failed to check if Whisper model is installed: $modelId', error: e);
      return false;
    }
  }

  @override
  Future<UnifiedModelCompatibility> checkCompatibility(String modelId) async {
    final config = _modelConfigs[modelId];

    // Check if model is known
    if (config == null && !_legacyManager.availableModels.contains(modelId)) {
      return UnifiedModelCompatibility.incompatible(
        'Unknown Whisper model: $modelId',
      );
    }

    // Whisper models work on all platforms
    return UnifiedModelCompatibility.compatible();
  }

  @override
  Stream<UnifiedDownloadProgress> downloadModel(String modelId) async* {
    final config = _modelConfigs[modelId];
    final displayName = config?.displayName ?? modelId;
    final estimatedSize = config?.estimatedSizeMb ??
                          _legacyManager.getModelSize(modelId) ~/ (1024 * 1024);

    _downloadCancelled = false;

    yield UnifiedDownloadProgress(
      modelId: modelId,
      displayName: displayName,
      category: ModelCategory.whisper,
      progress: 0.0,
      downloadedBytes: 0,
      totalBytes: estimatedSize * 1024 * 1024,
      phase: DownloadPhase.preparingDownload,
      message: 'Preparing Whisper model download...',
      timestamp: DateTime.now(),
    );

    // Check if already installed
    if (await isModelInstalled(modelId)) {
      yield UnifiedDownloadProgress(
        modelId: modelId,
        displayName: displayName,
        category: ModelCategory.whisper,
        progress: 1.0,
        downloadedBytes: estimatedSize * 1024 * 1024,
        totalBytes: estimatedSize * 1024 * 1024,
        phase: DownloadPhase.completed,
        message: 'Model already installed',
        timestamp: DateTime.now(),
      );
      return;
    }

    try {
      // Start download via legacy manager
      _legacyManager.downloadModel(modelId);

      yield UnifiedDownloadProgress(
        modelId: modelId,
        displayName: displayName,
        category: ModelCategory.whisper,
        progress: 0.0,
        downloadedBytes: 0,
        totalBytes: estimatedSize * 1024 * 1024,
        phase: DownloadPhase.downloading,
        message: 'Starting download...',
        timestamp: DateTime.now(),
      );

      // Poll for progress updates
      while (_legacyManager.isDownloading(modelId)) {
        if (_downloadCancelled) {
          yield UnifiedDownloadProgress(
            modelId: modelId,
            displayName: displayName,
            category: ModelCategory.whisper,
            progress: 0.0,
            downloadedBytes: 0,
            totalBytes: 0,
            phase: DownloadPhase.cancelled,
            message: 'Download cancelled',
            timestamp: DateTime.now(),
          );
          return;
        }

        final progress = _legacyManager.getProgress(modelId);
        final downloadedBytes = (progress * estimatedSize * 1024 * 1024).toInt();

        yield UnifiedDownloadProgress(
          modelId: modelId,
          displayName: displayName,
          category: ModelCategory.whisper,
          progress: progress,
          downloadedBytes: downloadedBytes,
          totalBytes: estimatedSize * 1024 * 1024,
          phase: DownloadPhase.downloading,
          message: 'Downloading... ${(progress * 100).toStringAsFixed(1)}%',
          timestamp: DateTime.now(),
        );

        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Check final state
      final error = _legacyManager.getError(modelId);
      if (error != null) {
        yield UnifiedDownloadProgress(
          modelId: modelId,
          displayName: displayName,
          category: ModelCategory.whisper,
          progress: 0.0,
          downloadedBytes: 0,
          totalBytes: 0,
          phase: DownloadPhase.failed,
          error: error,
          timestamp: DateTime.now(),
        );
      } else if (await isModelInstalled(modelId)) {
        yield UnifiedDownloadProgress(
          modelId: modelId,
          displayName: displayName,
          category: ModelCategory.whisper,
          progress: 1.0,
          downloadedBytes: estimatedSize * 1024 * 1024,
          totalBytes: estimatedSize * 1024 * 1024,
          phase: DownloadPhase.completed,
          message: 'Whisper model installed successfully',
          timestamp: DateTime.now(),
        );
      } else {
        yield UnifiedDownloadProgress(
          modelId: modelId,
          displayName: displayName,
          category: ModelCategory.whisper,
          progress: 0.0,
          downloadedBytes: 0,
          totalBytes: 0,
          phase: DownloadPhase.failed,
          error: 'Download completed but model not found',
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      _logger.e('Failed to download Whisper model: $modelId', error: e);
      yield UnifiedDownloadProgress(
        modelId: modelId,
        displayName: displayName,
        category: ModelCategory.whisper,
        progress: 0.0,
        downloadedBytes: 0,
        totalBytes: 0,
        phase: DownloadPhase.failed,
        error: e,
        timestamp: DateTime.now(),
      );
    }
  }

  @override
  Future<void> cancelDownload(String modelId) async {
    _downloadCancelled = true;
    // Legacy manager doesn't have a cancel method, but setting the flag
    // will cause the polling loop to exit
    _logger.i('Cancelled download for Whisper model: $modelId');
  }

  @override
  Future<bool> deleteModel(String modelId) async {
    try {
      return await _legacyManager.deleteModel(modelId);
    } catch (e) {
      _logger.e('Failed to delete Whisper model: $modelId', error: e);
      return false;
    }
  }

  @override
  Future<String?> getModelPath(String modelId) async {
    try {
      return await _legacyManager.getModelPath(modelId);
    } catch (e) {
      _logger.e('Failed to get Whisper model path: $modelId', error: e);

      // Fallback to default path
      final dir = await getApplicationDocumentsDirectory();
      return '${dir.path}/models/$modelId';
    }
  }

  @override
  Future<bool> canResume(String modelId) async {
    // Legacy manager doesn't support resume
    return false;
  }

  @override
  Stream<UnifiedDownloadProgress> resumeDownload(String modelId) async* {
    // Just restart the download
    yield* downloadModel(modelId);
  }

  @override
  Future<List<UnifiedModelInfo>> getAvailableModels() async {
    final models = <UnifiedModelInfo>[];

    // Add known Whisper models
    for (final entry in _modelConfigs.entries) {
      models.add(UnifiedModelInfo(
        modelId: entry.key,
        displayName: entry.value.displayName,
        category: ModelCategory.whisper,
        estimatedSizeMb: entry.value.estimatedSizeMb,
        supportsNpu: false,
        supportsVision: false,
        isRecommended: entry.key == 'whisper-base',
        description: entry.value.description,
      ));
    }

    // Add any additional models from legacy manager
    for (final modelId in _legacyManager.whisperModels) {
      if (!models.any((m) => m.modelId == modelId)) {
        models.add(UnifiedModelInfo(
          modelId: modelId,
          displayName: modelId,
          category: ModelCategory.whisper,
          estimatedSizeMb: _legacyManager.getModelSize(modelId) ~/ (1024 * 1024),
          supportsNpu: false,
          supportsVision: false,
          isRecommended: false,
          description: 'Whisper speech recognition model',
        ));
      }
    }

    return models;
  }
}

/// Internal Whisper model configuration
class _WhisperModelConfig {
  final String displayName;
  final int estimatedSizeMb;
  final String description;

  const _WhisperModelConfig({
    required this.displayName,
    required this.estimatedSizeMb,
    required this.description,
  });
}

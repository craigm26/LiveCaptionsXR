import 'dart:async';
import 'dart:io';

import 'package:nexa_ai_flutter/nexa_ai_flutter.dart' hide ModelCompatibility, DownloadStatus, DownloadProgress;
import 'package:path_provider/path_provider.dart';

import '../../models/device_model_config.dart';
import '../app_logger.dart';
import 'i_model_download_strategy.dart';

/// Nexa SDK-native download strategy using ModelDownloader
/// Handles ASR (Parakeet), LLM (Granite), and VLM (OmniNeural) models
class NexaModelDownloadStrategy implements IModelDownloadStrategy {
  static final AppLogger _logger = AppLogger.instance;

  final DeviceModelRegistry _deviceRegistry;
  final Map<String, StreamController<UnifiedDownloadProgress>> _activeDownloads = {};
  bool _downloadCancelled = false;

  NexaModelDownloadStrategy(this._deviceRegistry);

  @override
  ModelCategory get category => ModelCategory.nexa;

  @override
  Future<bool> isModelAvailable(String modelId) async {
    if (!Platform.isAndroid) return false;

    try {
      final models = await ModelDownloader.getAvailableModels();
      return models.any((m) =>
          m.displayName.toLowerCase() == modelId.toLowerCase() ||
          m.type.toLowerCase().contains(modelId.toLowerCase()));
    } catch (e) {
      _logger.e('Failed to check model availability: $modelId', error: e);
      return false;
    }
  }

  @override
  Future<bool> isModelInstalled(String modelId) async {
    if (!Platform.isAndroid) return false;

    try {
      final modelPath = await getModelPath(modelId);
      if (modelPath == null) return false;

      final file = File(modelPath);
      return await file.exists();
    } catch (e) {
      _logger.e('Failed to check if model is installed: $modelId', error: e);
      return false;
    }
  }

  @override
  Future<UnifiedModelCompatibility> checkCompatibility(String modelId) async {
    if (!Platform.isAndroid) {
      return UnifiedModelCompatibility.incompatible(
        'Nexa SDK is only available on Android',
      );
    }

    try {
      // Check if the model exists in available models
      final models = await ModelDownloader.getAvailableModels();
      final model = models.where((m) =>
          m.displayName.toLowerCase().contains(modelId.toLowerCase()) ||
          m.type.toLowerCase().contains(modelId.toLowerCase())).firstOrNull;

      if (model == null) {
        return UnifiedModelCompatibility.incompatible(
          'Model $modelId is not available in Nexa SDK',
        );
      }

      // Check NPU availability for NPU models
      final isNpuModel = model.displayName.toLowerCase().contains('npu') ||
          model.type.toLowerCase().contains('npu');

      if (isNpuModel) {
        final npuAvailable = await _isNpuAvailable();
        if (!npuAvailable) {
          return UnifiedModelCompatibility(
            isCompatible: true, // Can still run on CPU/GPU
            deviceCapabilities: {'npuAvailable': false},
            incompatibilityReason: 'NPU not available, will use CPU/GPU fallback',
          );
        }
      }

      return UnifiedModelCompatibility(
        isCompatible: true,
        deviceCapabilities: {
          'npuAvailable': await _isNpuAvailable(),
          'modelType': model.type,
        },
      );
    } catch (e) {
      _logger.e('Failed to check model compatibility: $modelId', error: e);
      return UnifiedModelCompatibility.incompatible(
        'Failed to check compatibility: $e',
      );
    }
  }

  Future<bool> _isNpuAvailable() async {
    try {
      final models = await ModelDownloader.getAvailableModels();
      return models.any((m) =>
          m.displayName.toLowerCase().contains('npu') ||
          m.type.toLowerCase().contains('npu'));
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<UnifiedDownloadProgress> downloadModel(String modelId) async* {
    if (!Platform.isAndroid) {
      yield UnifiedDownloadProgress(
        modelId: modelId,
        displayName: modelId,
        category: ModelCategory.nexa,
        progress: 0.0,
        downloadedBytes: 0,
        totalBytes: 0,
        phase: DownloadPhase.failed,
        error: 'Nexa SDK is only available on Android',
        timestamp: DateTime.now(),
      );
      return;
    }

    _downloadCancelled = false;

    yield UnifiedDownloadProgress(
      modelId: modelId,
      displayName: modelId,
      category: ModelCategory.nexa,
      progress: 0.0,
      downloadedBytes: 0,
      totalBytes: 0,
      phase: DownloadPhase.checkingCompatibility,
      message: 'Checking model compatibility...',
      timestamp: DateTime.now(),
    );

    // Check compatibility first
    final compatibility = await checkCompatibility(modelId);
    if (!compatibility.isCompatible) {
      yield UnifiedDownloadProgress(
        modelId: modelId,
        displayName: modelId,
        category: ModelCategory.nexa,
        progress: 0.0,
        downloadedBytes: 0,
        totalBytes: 0,
        phase: DownloadPhase.failed,
        error: 'Incompatible: ${compatibility.incompatibilityReason}',
        timestamp: DateTime.now(),
      );
      return;
    }

    yield UnifiedDownloadProgress(
      modelId: modelId,
      displayName: modelId,
      category: ModelCategory.nexa,
      progress: 0.0,
      downloadedBytes: 0,
      totalBytes: 0,
      phase: DownloadPhase.downloading,
      message: 'Starting download via Nexa SDK...',
      timestamp: DateTime.now(),
    );

    try {
      // Use Nexa SDK ModelDownloader to download the model
      final downloader = ModelDownloader();
      await for (final nexaProgress in downloader.downloadModel(modelId)) {
        if (_downloadCancelled) {
          yield UnifiedDownloadProgress(
            modelId: modelId,
            displayName: modelId,
            category: ModelCategory.nexa,
            progress: 0.0,
            downloadedBytes: 0,
            totalBytes: 0,
            phase: DownloadPhase.cancelled,
            message: 'Download cancelled',
            timestamp: DateTime.now(),
          );
          return;
        }

        // Map Nexa progress to unified progress
        // The nexa_ai_flutter DownloadProgress has: downloadedBytes, totalBytes, status
        final progress = nexaProgress.totalBytes > 0
            ? nexaProgress.downloadedBytes / nexaProgress.totalBytes
            : 0.0;

        final phase = _mapNexaProgress(nexaProgress);

        yield UnifiedDownloadProgress(
          modelId: modelId,
          displayName: modelId,
          category: ModelCategory.nexa,
          progress: progress,
          downloadedBytes: nexaProgress.downloadedBytes,
          totalBytes: nexaProgress.totalBytes,
          phase: phase,
          message: _getProgressMessage(progress, phase),
          timestamp: DateTime.now(),
        );

        if (phase == DownloadPhase.completed) {
          _logger.i('Nexa model $modelId downloaded successfully');
          break;
        }

        if (phase == DownloadPhase.failed) {
          _logger.e('Nexa model $modelId download failed');
          break;
        }
      }
    } catch (e) {
      _logger.e('Failed to download Nexa model: $modelId', error: e);
      yield UnifiedDownloadProgress(
        modelId: modelId,
        displayName: modelId,
        category: ModelCategory.nexa,
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
    try {
      _downloadCancelled = true;
      await ModelDownloader.cancelDownload(modelId);
      _activeDownloads[modelId]?.close();
      _activeDownloads.remove(modelId);
      _logger.i('Cancelled download for Nexa model: $modelId');
    } catch (e) {
      _logger.e('Failed to cancel download: $modelId', error: e);
    }
  }

  @override
  Future<bool> deleteModel(String modelId) async {
    try {
      final modelPath = await getModelPath(modelId);
      if (modelPath != null) {
        final file = File(modelPath);
        if (await file.exists()) {
          await file.delete();
          _logger.i('Deleted Nexa model: $modelId');
          return true;
        }
      }
      return false;
    } catch (e) {
      _logger.e('Failed to delete model: $modelId', error: e);
      return false;
    }
  }

  @override
  Future<String?> getModelPath(String modelId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      // Nexa models are stored in the app's models directory
      return '${appDir.path}/models/nexa/$modelId';
    } catch (e) {
      _logger.e('Failed to get model path: $modelId', error: e);
      return null;
    }
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
    if (!Platform.isAndroid) return [];

    try {
      final models = await ModelDownloader.getAvailableModels();
      final deviceConfig = await _deviceRegistry.getDeviceConfig();

      return models.map((m) {
        final isRecommended =
            m.displayName == deviceConfig.asrModel.displayName ||
            m.displayName == deviceConfig.llmModel.displayName;

        return UnifiedModelInfo(
          modelId: m.displayName,
          displayName: m.displayName,
          category: ModelCategory.nexa,
          estimatedSizeMb: _estimateModelSize(m.type),
          supportsNpu: m.displayName.toLowerCase().contains('npu') ||
              m.type.toLowerCase().contains('npu'),
          supportsVision: m.type.toLowerCase().contains('vlm') ||
              m.type.toLowerCase().contains('vision'),
          isRecommended: isRecommended,
          description: _getModelDescription(m.type),
        );
      }).toList();
    } catch (e) {
      _logger.e('Failed to get available Nexa models', error: e);
      return [];
    }
  }

  /// Map Nexa download progress to our unified DownloadPhase
  DownloadPhase _mapNexaProgress(dynamic nexaProgress) {
    // Check based on progress values
    if (nexaProgress.totalBytes > 0 &&
        nexaProgress.downloadedBytes >= nexaProgress.totalBytes) {
      return DownloadPhase.completed;
    }

    if (nexaProgress.downloadedBytes > 0) {
      return DownloadPhase.downloading;
    }

    return DownloadPhase.preparingDownload;
  }

  String _getProgressMessage(double progress, DownloadPhase phase) {
    switch (phase) {
      case DownloadPhase.preparingDownload:
        return 'Preparing download...';
      case DownloadPhase.downloading:
        return 'Downloading... ${(progress * 100).toStringAsFixed(1)}%';
      case DownloadPhase.completed:
        return 'Download complete';
      case DownloadPhase.failed:
        return 'Download failed';
      case DownloadPhase.cancelled:
        return 'Download cancelled';
      default:
        return 'Downloading...';
    }
  }

  int _estimateModelSize(String type) {
    // Estimate sizes based on model type
    if (type.toLowerCase().contains('asr')) {
      return 600; // ~600MB for Parakeet
    } else if (type.toLowerCase().contains('vlm')) {
      return 4000; // ~4GB for OmniNeural
    } else if (type.toLowerCase().contains('llm')) {
      return 750; // ~750MB for LFM2
    }
    return 500; // Default estimate
  }

  String _getModelDescription(String type) {
    if (type.toLowerCase().contains('asr')) {
      return 'Speech-to-text model optimized for Qualcomm NPU';
    } else if (type.toLowerCase().contains('vlm')) {
      return 'Vision-language model for image understanding';
    } else if (type.toLowerCase().contains('llm')) {
      return 'Language model for text enhancement';
    }
    return 'Nexa AI model';
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/device_model_config.dart';
import '../app_logger.dart';
import '../ios_model_config_service.dart';
import '../model_download_manager.dart';
import 'download_state_persistence.dart';
import 'gemma_model_download_strategy.dart';
import 'i_model_download_strategy.dart';
import 'nexa_model_download_strategy.dart';
import 'whisper_model_download_strategy.dart';

/// Unified facade that routes downloads to appropriate strategies
/// and provides crash recovery via SharedPreferences
class UnifiedDownloadManager extends ChangeNotifier {
  static final AppLogger _logger = AppLogger.instance;

  final DeviceModelRegistry _deviceRegistry;
  final DownloadStatePersistence _statePersistence;
  final ModelDownloadManager _legacyManager;

  late final NexaModelDownloadStrategy _nexaStrategy;
  late final GemmaModelDownloadStrategy _gemmaStrategy;
  late final WhisperModelDownloadStrategy _whisperStrategy;

  final Map<String, UnifiedDownloadProgress> _downloadStates = {};
  final Map<String, StreamSubscription> _activeSubscriptions = {};
  final StreamController<UnifiedDownloadProgress> _progressController =
      StreamController<UnifiedDownloadProgress>.broadcast();

  bool _isInitialized = false;

  /// Stream of all download progress events
  Stream<UnifiedDownloadProgress> get progressStream => _progressController.stream;

  /// Get all current download states
  Map<String, UnifiedDownloadProgress> get downloadStates =>
      Map.unmodifiable(_downloadStates);

  /// Check if any downloads are active
  bool get hasActiveDownloads => _downloadStates.values.any((s) => s.isActive);

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  UnifiedDownloadManager({
    required DeviceModelRegistry deviceRegistry,
    required ModelDownloadManager legacyManager,
    required DownloadStatePersistence statePersistence,
  })  : _deviceRegistry = deviceRegistry,
        _legacyManager = legacyManager,
        _statePersistence = statePersistence {
    _nexaStrategy = NexaModelDownloadStrategy(deviceRegistry);
    _gemmaStrategy = GemmaModelDownloadStrategy(IOSModelConfigService());
    _whisperStrategy = WhisperModelDownloadStrategy(legacyManager);
  }

  /// Initialize and check for interrupted downloads
  Future<void> initialize() async {
    if (_isInitialized) return;

    _logger.i('Initializing UnifiedDownloadManager...', category: LogCategory.system);

    try {
      await _recoverInterruptedDownloads();
      _isInitialized = true;
      _logger.i('UnifiedDownloadManager initialized', category: LogCategory.system);
    } catch (e) {
      _logger.e('Failed to initialize UnifiedDownloadManager', error: e);
      _isInitialized = true; // Continue anyway
    }
  }

  /// Get the appropriate strategy for a model category
  IModelDownloadStrategy getStrategy(ModelCategory category) {
    switch (category) {
      case ModelCategory.nexa:
        return _nexaStrategy;
      case ModelCategory.gemma:
        return _gemmaStrategy;
      case ModelCategory.whisper:
        return _whisperStrategy;
    }
  }

  /// Determine model category from model ID
  ModelCategory categorizeModel(String modelId) {
    final lowerModelId = modelId.toLowerCase();

    // Nexa models (Parakeet ASR, Granite LLM, OmniNeural VLM)
    if (lowerModelId.contains('parakeet') ||
        lowerModelId.contains('granite') ||
        lowerModelId.contains('omnineural') ||
        lowerModelId.contains('lfm') ||
        lowerModelId.contains('smolvlm')) {
      return ModelCategory.nexa;
    }

    // Gemma models
    if (lowerModelId.contains('gemma')) {
      return ModelCategory.gemma;
    }

    // Default to Whisper for speech models
    return ModelCategory.whisper;
  }

  /// Get all available models combining device registry and package APIs
  Future<List<UnifiedModelInfo>> getAvailableModels() async {
    final models = <UnifiedModelInfo>[];
    final seenIds = <String>{};

    try {
      // Get Nexa models
      final nexaModels = await _nexaStrategy.getAvailableModels();
      for (final model in nexaModels) {
        if (!seenIds.contains(model.modelId)) {
          models.add(model);
          seenIds.add(model.modelId);
        }
      }

      // Get Gemma models
      final gemmaModels = await _gemmaStrategy.getAvailableModels();
      for (final model in gemmaModels) {
        if (!seenIds.contains(model.modelId)) {
          models.add(model);
          seenIds.add(model.modelId);
        }
      }

      // Get Whisper models
      final whisperModels = await _whisperStrategy.getAvailableModels();
      for (final model in whisperModels) {
        if (!seenIds.contains(model.modelId)) {
          models.add(model);
          seenIds.add(model.modelId);
        }
      }

      // Mark device-recommended models
      final deviceConfig = await _deviceRegistry.getDeviceConfig();
      return models.map((m) {
        if (m.modelId == deviceConfig.asrModel.name ||
            m.modelId == deviceConfig.llmModel.name) {
          return UnifiedModelInfo(
            modelId: m.modelId,
            displayName: m.displayName,
            category: m.category,
            estimatedSizeMb: m.estimatedSizeMb,
            supportsNpu: m.supportsNpu,
            supportsVision: m.supportsVision,
            isRecommended: true,
            description: m.description,
            downloadUrl: m.downloadUrl,
          );
        }
        return m;
      }).toList();
    } catch (e) {
      _logger.e('Failed to get available models', error: e);
      return models;
    }
  }

  /// Check if a model is installed
  Future<bool> isModelInstalled(String modelId) async {
    final category = categorizeModel(modelId);
    final strategy = getStrategy(category);
    return await strategy.isModelInstalled(modelId);
  }

  /// Get the path to an installed model
  Future<String?> getModelPath(String modelId) async {
    final category = categorizeModel(modelId);
    final strategy = getStrategy(category);
    return await strategy.getModelPath(modelId);
  }

  /// Download a model using the appropriate strategy
  Stream<UnifiedDownloadProgress> downloadModel(String modelId) async* {
    final category = categorizeModel(modelId);
    final strategy = getStrategy(category);

    _logger.i('Starting download for $modelId (category: ${category.name})',
        category: LogCategory.system);

    // Persist download start for crash recovery
    await _statePersistence.saveDownloadState(DownloadState(
      modelId: modelId,
      category: category,
      phase: DownloadPhase.preparingDownload,
      startTime: DateTime.now(),
    ));

    try {
      await for (final progress in strategy.downloadModel(modelId)) {
        _downloadStates[modelId] = progress;
        _progressController.add(progress);
        notifyListeners();

        // Update persisted state
        await _statePersistence.updateDownloadProgress(modelId, progress);

        yield progress;

        // Clean up on completion or failure
        if (progress.isComplete) {
          await _statePersistence.markDownloadCompleted(modelId);
        } else if (progress.hasFailed || progress.isCancelled) {
          await _statePersistence.markDownloadFailed(modelId);
        }
      }
    } catch (e) {
      _logger.e('Download failed for $modelId', error: e);

      final errorProgress = UnifiedDownloadProgress(
        modelId: modelId,
        displayName: modelId,
        category: category,
        progress: 0.0,
        downloadedBytes: 0,
        totalBytes: 0,
        phase: DownloadPhase.failed,
        error: e,
        timestamp: DateTime.now(),
      );

      _downloadStates[modelId] = errorProgress;
      _progressController.add(errorProgress);
      notifyListeners();

      await _statePersistence.markDownloadFailed(modelId);

      yield errorProgress;
    }
  }

  /// Cancel an active download
  Future<void> cancelDownload(String modelId) async {
    final category = categorizeModel(modelId);
    final strategy = getStrategy(category);

    _logger.i('Cancelling download for $modelId', category: LogCategory.system);

    await strategy.cancelDownload(modelId);
    await _statePersistence.clearDownloadState(modelId);

    _activeSubscriptions[modelId]?.cancel();
    _activeSubscriptions.remove(modelId);

    final cancelledProgress = UnifiedDownloadProgress(
      modelId: modelId,
      displayName: modelId,
      category: category,
      progress: 0.0,
      downloadedBytes: 0,
      totalBytes: 0,
      phase: DownloadPhase.cancelled,
      message: 'Download cancelled',
      timestamp: DateTime.now(),
    );

    _downloadStates[modelId] = cancelledProgress;
    _progressController.add(cancelledProgress);
    notifyListeners();
  }

  /// Delete an installed model
  Future<bool> deleteModel(String modelId) async {
    final category = categorizeModel(modelId);
    final strategy = getStrategy(category);

    _logger.i('Deleting model $modelId', category: LogCategory.system);

    final result = await strategy.deleteModel(modelId);

    if (result) {
      _downloadStates.remove(modelId);
      notifyListeners();
    }

    return result;
  }

  /// Recover interrupted downloads after app restart
  Future<void> _recoverInterruptedDownloads() async {
    final pendingDownloads = await _statePersistence.getPendingDownloads();

    if (pendingDownloads.isEmpty) {
      _logger.i('No pending downloads to recover', category: LogCategory.system);
      return;
    }

    _logger.i('Recovering ${pendingDownloads.length} pending downloads',
        category: LogCategory.system);

    for (final state in pendingDownloads) {
      final strategy = getStrategy(state.category);

      // Check if download can be resumed
      if (await strategy.canResume(state.modelId)) {
        _logger.i('Resuming download for ${state.modelId}',
            category: LogCategory.system);

        // Auto-resume in background
        final subscription = strategy.resumeDownload(state.modelId).listen(
          (progress) {
            _downloadStates[state.modelId] = progress;
            _progressController.add(progress);
            notifyListeners();

            if (progress.isComplete || progress.hasFailed || progress.isCancelled) {
              _activeSubscriptions[state.modelId]?.cancel();
              _activeSubscriptions.remove(state.modelId);
            }
          },
          onError: (e) {
            _logger.e('Failed to resume download for ${state.modelId}', error: e);
            _activeSubscriptions[state.modelId]?.cancel();
            _activeSubscriptions.remove(state.modelId);
          },
        );

        _activeSubscriptions[state.modelId] = subscription;
      } else {
        // Clear stale state
        _logger.i('Cannot resume download for ${state.modelId}, clearing state',
            category: LogCategory.system);
        await _statePersistence.clearDownloadState(state.modelId);
      }
    }
  }

  /// Get current download state for a model
  UnifiedDownloadProgress? getDownloadState(String modelId) {
    return _downloadStates[modelId];
  }

  /// Check if a specific model is currently downloading
  bool isDownloading(String modelId) {
    final state = _downloadStates[modelId];
    return state?.isActive ?? false;
  }

  /// Get download progress for a model (0.0 to 1.0)
  double getProgress(String modelId) {
    return _downloadStates[modelId]?.progress ?? 0.0;
  }

  @override
  void dispose() {
    // Cancel all active subscriptions
    for (final subscription in _activeSubscriptions.values) {
      subscription.cancel();
    }
    _activeSubscriptions.clear();

    _progressController.close();
    super.dispose();
  }
}

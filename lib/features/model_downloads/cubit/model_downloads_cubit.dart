import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/model_info.dart';
import '../services/model_download_service.dart';
import '../../../core/services/ios_model_config_service.dart';
import '../../../core/services/download/unified_download_manager.dart';
import '../../../core/services/download/i_model_download_strategy.dart';
import '../../../core/di/service_locator.dart';

part 'model_downloads_state.dart';

class ModelDownloadsCubit extends Cubit<ModelDownloadsState> {
  final IOSModelConfigService _iosConfig = IOSModelConfigService();

  late final UnifiedDownloadManager _downloadManager;
  StreamSubscription<UnifiedDownloadProgress>? _progressSubscription;

  ModelDownloadsCubit() : super(const ModelDownloadsState()) {
    _downloadManager = sl<UnifiedDownloadManager>();
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize the download manager
    await _downloadManager.initialize();

    // Listen to unified progress stream
    _progressSubscription = _downloadManager.progressStream.listen(_onDownloadProgress);

    // Load models from all strategies
    await _loadModels();
    await _checkDownloadedModels();
  }

  void _onDownloadProgress(UnifiedDownloadProgress progress) {
    // Convert UnifiedDownloadProgress to DownloadProgress for UI compatibility
    final legacyProgress = DownloadProgress(
      downloadedBytes: progress.downloadedBytes,
      totalBytes: progress.totalBytes,
      progress: progress.progress,
      status: _mapPhaseToStatus(progress.phase),
      error: progress.error?.toString(),
    );

    final newProgress = Map<String, DownloadProgress>.from(state.downloadProgress);
    newProgress[progress.modelId] = legacyProgress;
    final newPhase = Map<String, DownloadPhase>.from(state.downloadPhase);
    newPhase[progress.modelId] = progress.phase;
    final newMessage = Map<String, String>.from(state.downloadMessage);
    newMessage[progress.modelId] = progress.message ?? '';

    // Update active downloads
    var activeDownloads = Set<String>.from(state.activeDownloads);
    var downloadedModels = Set<String>.from(state.downloadedModels);

    if (progress.isActive) {
      activeDownloads.add(progress.modelId);
    } else {
      activeDownloads.remove(progress.modelId);
      if (progress.isComplete) {
        downloadedModels.add(progress.modelId);
      }
    }

    emit(state.copyWith(
      downloadProgress: newProgress,
      downloadPhase: newPhase,
      downloadMessage: newMessage,
      activeDownloads: activeDownloads,
      downloadedModels: downloadedModels,
      error: progress.hasFailed ? progress.error?.toString() : null,
    ));
  }

  DownloadStatus _mapPhaseToStatus(DownloadPhase phase) {
    switch (phase) {
      case DownloadPhase.idle:
        return DownloadStatus.notStarted;
      case DownloadPhase.checkingCompatibility:
      case DownloadPhase.preparingDownload:
      case DownloadPhase.downloading:
      case DownloadPhase.validating:
      case DownloadPhase.installing:
        return DownloadStatus.downloading;
      case DownloadPhase.completed:
        return DownloadStatus.completed;
      case DownloadPhase.failed:
        return DownloadStatus.failed;
      case DownloadPhase.cancelled:
        return DownloadStatus.cancelled;
      case DownloadPhase.paused:
        return DownloadStatus.downloading;
    }
  }

  Future<void> _loadModels() async {
    emit(state.copyWith(isLoading: true));

    try {
      // Get models from UnifiedDownloadManager (combines all strategies)
      final unifiedModels = await _downloadManager.getAvailableModels();

      // Convert to legacy ModelInfo format for UI compatibility
      final models = unifiedModels.map((m) => ModelInfo(
        name: m.displayName,
        description: m.description ?? _getDefaultDescription(m.category),
        fileName: m.modelId,
        downloadUrl: m.downloadUrl ?? '',
        sizeInBytes: m.estimatedSizeMb * 1024 * 1024,
        sizeDisplay: _formatSize(m.estimatedSizeMb * 1024 * 1024),
        version: '1.0.0',
        isRecommended: m.isRecommended,
        termsNotice: m.category == ModelCategory.gemma
          ? 'Gemma is provided under and subject to the Gemma Terms of Use found at ai.google.dev/gemma/terms. Users must comply with the Gemma Prohibited Use Policy at ai.google.dev/gemma/prohibited_use_policy and applicable laws and regulations.'
          : null,
      )).toList();

      emit(state.copyWith(
        models: models,
        isLoading: false,
      ));
    } catch (e) {
      // Fallback to static models if unified fetch fails
      emit(state.copyWith(
        models: _fallbackModels,
        isLoading: false,
        error: 'Failed to load models: $e',
      ));
    }
  }

  String _getDefaultDescription(ModelCategory category) {
    switch (category) {
      case ModelCategory.nexa:
        return 'NPU-accelerated on-device AI model';
      case ModelCategory.gemma:
        return 'Efficient language model for text generation';
      case ModelCategory.whisper:
        return 'Speech recognition model for real-time transcription';
    }
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    } else {
      return '$bytes B';
    }
  }

  // Fallback models for when unified fetch fails
  static const List<ModelInfo> _fallbackModels = [
    ModelInfo(
      name: 'Whisper Base Model',
      description: 'Fast speech recognition model for real-time transcription',
      fileName: 'whisper_base.bin',
      downloadUrl: 'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin?download=true',
      sizeInBytes: 147951465,
      sizeDisplay: '141 MB',
      version: '1.0.0',
      isRecommended: true,
    ),
    ModelInfo(
      name: 'Gemma 3N E2B Model',
      description: 'Efficient language model for text generation and processing',
      fileName: 'gemma-3n-E2B-it-int4.task',
      downloadUrl: 'https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/gemma-3n-E2B-it-int4.task',
      sizeInBytes: 3136226711,
      sizeDisplay: '2.92 GB',
      version: '1.0.0',
      termsNotice: 'Gemma is provided under and subject to the Gemma Terms of Use found at ai.google.dev/gemma/terms. Users must comply with the Gemma Prohibited Use Policy at ai.google.dev/gemma/prohibited_use_policy and applicable laws and regulations.',
    ),
    ModelInfo(
      name: 'Gemma 3N E4B Model',
      description: 'Advanced language model with enhanced capabilities',
      fileName: 'gemma-3n-E4B-it-int4.task',
      downloadUrl: 'https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/gemma-3n-E4B-it-int4.task',
      sizeInBytes: 4405655031,
      sizeDisplay: '4.11 GB',
      version: '1.0.0',
      termsNotice: 'Gemma is provided under and subject to the Gemma Terms of Use found at ai.google.dev/gemma/terms. Users must comply with the Gemma Prohibited Use Policy at ai.google.dev/gemma/prohibited_use_policy and applicable laws and regulations.',
    ),
  ];

  Future<void> _checkDownloadedModels() async {
    final downloadedModels = <String>{};
    final validationResults = <String, ModelValidationResult>{};

    for (final model in state.models) {
      final isDownloaded = await _downloadManager.isModelInstalled(model.fileName);
      if (isDownloaded) {
        downloadedModels.add(model.fileName);

        // Use legacy validation for now
        final validation = await ModelDownloadService.validateModel(model.fileName);
        validationResults[model.fileName] = validation;

        if (validation.status != ModelValidationStatus.valid) {
          downloadedModels.remove(model.fileName);
        }
      }
    }

    emit(state.copyWith(
      downloadedModels: downloadedModels,
      validationResults: validationResults,
    ));
  }

  Future<void> downloadModel(ModelInfo model) async {
    // Check if already downloading
    if (state.activeDownloads.contains(model.fileName)) {
      return;
    }

    // Add to active downloads
    final activeDownloads = Set<String>.from(state.activeDownloads)..add(model.fileName);
    emit(state.copyWith(activeDownloads: activeDownloads));

    // Use UnifiedDownloadManager to download
    try {
      await for (final progress in _downloadManager.downloadModel(model.fileName)) {
        // Progress updates are handled by _progressSubscription
        // This just completes when download is done
        if (progress.isComplete || progress.hasFailed || progress.isCancelled) {
          break;
        }
      }
    } catch (e) {
      final newActiveDownloads = Set<String>.from(state.activeDownloads)..remove(model.fileName);
      emit(state.copyWith(
        activeDownloads: newActiveDownloads,
        error: e.toString(),
      ));
    }
  }

  Future<void> cancelDownload(String fileName) async {
    await _downloadManager.cancelDownload(fileName);

    final newActiveDownloads = Set<String>.from(state.activeDownloads)..remove(fileName);
    emit(state.copyWith(activeDownloads: newActiveDownloads));
  }

  Future<void> deleteModel(String fileName) async {
    final success = await _downloadManager.deleteModel(fileName);
    if (success) {
      final newDownloadedModels = Set<String>.from(state.downloadedModels)..remove(fileName);
      final newValidationResults = Map<String, ModelValidationResult>.from(state.validationResults);
      newValidationResults.remove(fileName);
      final newProgress = Map<String, DownloadProgress>.from(state.downloadProgress);
      newProgress.remove(fileName);
      final newPhase = Map<String, DownloadPhase>.from(state.downloadPhase);
      newPhase.remove(fileName);
      final newMessage = Map<String, String>.from(state.downloadMessage);
      newMessage.remove(fileName);

      emit(state.copyWith(
        downloadedModels: newDownloadedModels,
        downloadProgress: newProgress,
        downloadPhase: newPhase,
        downloadMessage: newMessage,
        validationResults: newValidationResults,
      ));
    }
  }

  Future<void> refreshDownloadedModels() async {
    await _checkDownloadedModels();
  }

  void clearError() {
    emit(state.copyWith(error: null));
  }

  /// Get iOS-specific recommendations for model loading
  Map<String, dynamic> getIOSRecommendations() {
    return _iosConfig.getDiagnosticInfo();
  }

  /// Get optimal configuration for a specific model
  IOSModelConfig getOptimalConfig(String modelName) {
    return _iosConfig.getOptimalConfig(modelName);
  }

  /// Validate a specific model
  Future<ModelValidationResult> validateModel(String fileName) async {
    return await ModelDownloadService.validateModel(fileName);
  }

  @override
  Future<void> close() {
    _progressSubscription?.cancel();
    // Cancel all active downloads via the download manager
    for (final fileName in state.activeDownloads) {
      _downloadManager.cancelDownload(fileName);
    }
    return super.close();
  }
}

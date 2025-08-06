import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/model_info.dart';
import '../services/model_download_service.dart';
import '../../../core/services/ios_model_config_service.dart';

part 'model_downloads_state.dart';

class ModelDownloadsCubit extends Cubit<ModelDownloadsState> {
  final IOSModelConfigService _iosConfig = IOSModelConfigService();

  ModelDownloadsCubit() : super(const ModelDownloadsState()) {
    _loadModels();
    _checkDownloadedModels();
  }

  static const List<ModelInfo> _availableModels = [
    ModelInfo(
      name: 'Whisper Base Model',
      description: 'Fast speech recognition model for real-time transcription',
      fileName: 'whisper_base.bin',
      downloadUrl: 'https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/whisper_base.bin',
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

  void _loadModels() {
    emit(state.copyWith(
      models: _availableModels,
      isLoading: false,
    ));
  }

  Future<void> _checkDownloadedModels() async {
    final downloadedModels = <String>{};
    final validationResults = <String, ModelValidationResult>{};
    
    for (final model in _availableModels) {
      final isDownloaded = await ModelDownloadService.isModelDownloaded(model.fileName);
      if (isDownloaded) {
        downloadedModels.add(model.fileName);
        
        // Validate downloaded model
        final validation = await ModelDownloadService.validateModel(model.fileName);
        validationResults[model.fileName] = validation;
        
        // If validation failed, remove from downloaded models
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

    // Start download with validation
    final downloadStream = ModelDownloadService.downloadModel(
      model.fileName,
      model.name,
      validateAfterDownload: true,
    );

    await for (final progress in downloadStream) {
      switch (progress.status) {
        case DownloadStatus.downloading:
          emit(state.copyWith(
            downloadProgress: {
              ...state.downloadProgress,
              model.fileName: progress,
            },
          ));
          break;

        case DownloadStatus.completed:
          final newActiveDownloads = Set<String>.from(state.activeDownloads)..remove(model.fileName);
          final newDownloadedModels = Set<String>.from(state.downloadedModels)..add(model.fileName);
          
          // Validate the downloaded model
          final validation = await ModelDownloadService.validateModel(model.fileName);
          final newValidationResults = Map<String, ModelValidationResult>.from(state.validationResults);
          newValidationResults[model.fileName] = validation;
          
          emit(state.copyWith(
            activeDownloads: newActiveDownloads,
            downloadedModels: newDownloadedModels,
            downloadProgress: {
              ...state.downloadProgress,
              model.fileName: progress,
            },
            validationResults: newValidationResults,
          ));
          break;

        case DownloadStatus.failed:
          final newActiveDownloads = Set<String>.from(state.activeDownloads)..remove(model.fileName);
          emit(state.copyWith(
            activeDownloads: newActiveDownloads,
            downloadProgress: {
              ...state.downloadProgress,
              model.fileName: progress,
            },
            error: progress.error,
          ));
          break;

        case DownloadStatus.cancelled:
          final newActiveDownloads = Set<String>.from(state.activeDownloads)..remove(model.fileName);
          emit(state.copyWith(
            activeDownloads: newActiveDownloads,
            downloadProgress: {
              ...state.downloadProgress,
              model.fileName: progress,
            },
          ));
          break;

        default:
          break;
      }
    }
  }

  void cancelDownload(String fileName) {
    ModelDownloadService.cancelDownload(fileName);
    
    final newActiveDownloads = Set<String>.from(state.activeDownloads)..remove(fileName);
    emit(state.copyWith(activeDownloads: newActiveDownloads));
  }

  Future<void> deleteModel(String fileName) async {
    final success = await ModelDownloadService.deleteModel(fileName);
    if (success) {
      final newDownloadedModels = Set<String>.from(state.downloadedModels)..remove(fileName);
      final newValidationResults = Map<String, ModelValidationResult>.from(state.validationResults);
      newValidationResults.remove(fileName);
      
      emit(state.copyWith(
        downloadedModels: newDownloadedModels,
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
    // Cancel all active downloads
    for (final fileName in state.activeDownloads) {
      ModelDownloadService.cancelDownload(fileName);
    }
    return super.close();
  }
} 
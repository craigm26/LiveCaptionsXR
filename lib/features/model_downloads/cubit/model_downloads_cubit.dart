import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/model_info.dart';
import '../services/model_download_service.dart';

part 'model_downloads_state.dart';

class ModelDownloadsCubit extends Cubit<ModelDownloadsState> {
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
    ),
    ModelInfo(
      name: 'Gemma 3N E4B Model',
      description: 'Advanced language model with enhanced capabilities',
      fileName: 'gemma-3n-E4B-it-int4.task',
      downloadUrl: 'https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/gemma-3n-E4B-it-int4.task',
      sizeInBytes: 4405655031,
      sizeDisplay: '4.11 GB',
      version: '1.0.0',
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
    
    for (final model in _availableModels) {
      final isDownloaded = await ModelDownloadService.isModelDownloaded(model.fileName);
      if (isDownloaded) {
        downloadedModels.add(model.fileName);
      }
    }

    emit(state.copyWith(
      downloadedModels: downloadedModels,
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

    // Start download
    final downloadStream = ModelDownloadService.downloadModel(
      model.fileName,
      model.name,
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
          
          emit(state.copyWith(
            activeDownloads: newActiveDownloads,
            downloadedModels: newDownloadedModels,
            downloadProgress: {
              ...state.downloadProgress,
              model.fileName: progress,
            },
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
      emit(state.copyWith(downloadedModels: newDownloadedModels));
    }
  }

  Future<void> refreshDownloadedModels() async {
    await _checkDownloadedModels();
  }

  void clearError() {
    emit(state.copyWith(error: null));
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
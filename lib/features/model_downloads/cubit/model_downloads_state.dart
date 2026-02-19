part of 'model_downloads_cubit.dart';

class ModelDownloadsState extends Equatable {
  final List<ModelInfo> models;
  final Set<String> downloadedModels;
  final Set<String> activeDownloads;
  final Map<String, DownloadProgress> downloadProgress;
  final Map<String, DownloadPhase> downloadPhase;
  final Map<String, String> downloadMessage;
  final Map<String, ModelValidationResult> validationResults;
  final bool isLoading;
  final String? error;

  const ModelDownloadsState({
    this.models = const [],
    this.downloadedModels = const {},
    this.activeDownloads = const {},
    this.downloadProgress = const {},
    this.downloadPhase = const {},
    this.downloadMessage = const {},
    this.validationResults = const {},
    this.isLoading = true,
    this.error,
  });

  ModelDownloadsState copyWith({
    List<ModelInfo>? models,
    Set<String>? downloadedModels,
    Set<String>? activeDownloads,
    Map<String, DownloadProgress>? downloadProgress,
    Map<String, DownloadPhase>? downloadPhase,
    Map<String, String>? downloadMessage,
    Map<String, ModelValidationResult>? validationResults,
    bool? isLoading,
    String? error,
  }) {
    return ModelDownloadsState(
      models: models ?? this.models,
      downloadedModels: downloadedModels ?? this.downloadedModels,
      activeDownloads: activeDownloads ?? this.activeDownloads,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadPhase: downloadPhase ?? this.downloadPhase,
      downloadMessage: downloadMessage ?? this.downloadMessage,
      validationResults: validationResults ?? this.validationResults,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        models,
        downloadedModels,
        activeDownloads,
        downloadProgress,
        downloadPhase,
        downloadMessage,
        validationResults,
        isLoading,
        error,
      ];
} 
part of 'model_downloads_cubit.dart';

class ModelDownloadsState extends Equatable {
  final List<ModelInfo> models;
  final Set<String> downloadedModels;
  final Set<String> activeDownloads;
  final Map<String, DownloadProgress> downloadProgress;
  final bool isLoading;
  final String? error;

  const ModelDownloadsState({
    this.models = const [],
    this.downloadedModels = const {},
    this.activeDownloads = const {},
    this.downloadProgress = const {},
    this.isLoading = true,
    this.error,
  });

  ModelDownloadsState copyWith({
    List<ModelInfo>? models,
    Set<String>? downloadedModels,
    Set<String>? activeDownloads,
    Map<String, DownloadProgress>? downloadProgress,
    bool? isLoading,
    String? error,
  }) {
    return ModelDownloadsState(
      models: models ?? this.models,
      downloadedModels: downloadedModels ?? this.downloadedModels,
      activeDownloads: activeDownloads ?? this.activeDownloads,
      downloadProgress: downloadProgress ?? this.downloadProgress,
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
        isLoading,
        error,
      ];
} 
import 'dart:async';

/// Model category for routing to appropriate download strategy
enum ModelCategory {
  nexa,    // ASR, LLM, VLM via nexa_ai_flutter
  gemma,   // Gemma models via flutter_gemma
  whisper, // Whisper models via legacy HTTP
}

/// Download phases for state machine
enum DownloadPhase {
  idle,
  checkingCompatibility,
  preparingDownload,
  downloading,
  validating,
  installing,
  completed,
  failed,
  cancelled,
  paused,
}

/// Unified download progress event
class UnifiedDownloadProgress {
  final String modelId;
  final String displayName;
  final ModelCategory category;
  final double progress;        // 0.0 to 1.0
  final int downloadedBytes;
  final int totalBytes;
  final DownloadPhase phase;
  final String? message;
  final Object? error;
  final DateTime timestamp;

  const UnifiedDownloadProgress({
    required this.modelId,
    required this.displayName,
    required this.category,
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.phase,
    this.message,
    this.error,
    required this.timestamp,
  });

  bool get isComplete => phase == DownloadPhase.completed;
  bool get hasFailed => phase == DownloadPhase.failed;
  bool get isCancelled => phase == DownloadPhase.cancelled;
  bool get isActive => phase == DownloadPhase.downloading ||
                       phase == DownloadPhase.validating ||
                       phase == DownloadPhase.installing ||
                       phase == DownloadPhase.preparingDownload;

  UnifiedDownloadProgress copyWith({
    String? modelId,
    String? displayName,
    ModelCategory? category,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    DownloadPhase? phase,
    String? message,
    Object? error,
    DateTime? timestamp,
  }) {
    return UnifiedDownloadProgress(
      modelId: modelId ?? this.modelId,
      displayName: displayName ?? this.displayName,
      category: category ?? this.category,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      phase: phase ?? this.phase,
      message: message ?? this.message,
      error: error ?? this.error,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'UnifiedDownloadProgress(modelId: $modelId, phase: $phase, progress: ${(progress * 100).toStringAsFixed(1)}%)';
  }
}

/// Model compatibility result
class UnifiedModelCompatibility {
  final bool isCompatible;
  final String? incompatibilityReason;
  final Map<String, dynamic>? deviceCapabilities;
  final String? recommendedAlternative;

  const UnifiedModelCompatibility({
    required this.isCompatible,
    this.incompatibilityReason,
    this.deviceCapabilities,
    this.recommendedAlternative,
  });

  factory UnifiedModelCompatibility.compatible() => const UnifiedModelCompatibility(
    isCompatible: true,
  );

  factory UnifiedModelCompatibility.incompatible(String reason, {String? alternative}) =>
    UnifiedModelCompatibility(
      isCompatible: false,
      incompatibilityReason: reason,
      recommendedAlternative: alternative,
    );
}

/// Unified model info combining device registry and package APIs
class UnifiedModelInfo {
  final String modelId;
  final String displayName;
  final ModelCategory category;
  final int estimatedSizeMb;
  final bool supportsNpu;
  final bool supportsVision;
  final bool isRecommended;
  final String? description;
  final String? downloadUrl;

  const UnifiedModelInfo({
    required this.modelId,
    required this.displayName,
    required this.category,
    required this.estimatedSizeMb,
    this.supportsNpu = false,
    this.supportsVision = false,
    this.isRecommended = false,
    this.description,
    this.downloadUrl,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedModelInfo &&
          runtimeType == other.runtimeType &&
          modelId == other.modelId;

  @override
  int get hashCode => modelId.hashCode;
}

/// Abstract strategy interface for package-specific download implementations
abstract class IModelDownloadStrategy {
  /// Get the model category this strategy handles
  ModelCategory get category;

  /// Check if a model is available for download via this strategy
  Future<bool> isModelAvailable(String modelId);

  /// Check if a model is already downloaded and valid
  Future<bool> isModelInstalled(String modelId);

  /// Check device compatibility for a model
  Future<UnifiedModelCompatibility> checkCompatibility(String modelId);

  /// Download a model with progress streaming
  Stream<UnifiedDownloadProgress> downloadModel(String modelId);

  /// Cancel an active download
  Future<void> cancelDownload(String modelId);

  /// Delete an installed model
  Future<bool> deleteModel(String modelId);

  /// Get the local path for an installed model
  Future<String?> getModelPath(String modelId);

  /// Resume a partially downloaded model (if supported)
  Future<bool> canResume(String modelId);

  /// Resume a partially downloaded model
  Stream<UnifiedDownloadProgress> resumeDownload(String modelId);

  /// Get list of available models for this strategy
  Future<List<UnifiedModelInfo>> getAvailableModels();
}

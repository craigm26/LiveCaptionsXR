import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'i_model_download_strategy.dart';

/// Serializable download state for persistence
class DownloadState {
  final String modelId;
  final ModelCategory category;
  final DownloadPhase phase;
  final int downloadedBytes;
  final int totalBytes;
  final DateTime startTime;
  final DateTime? lastUpdate;

  const DownloadState({
    required this.modelId,
    required this.category,
    required this.phase,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    required this.startTime,
    this.lastUpdate,
  });

  Map<String, dynamic> toJson() => {
    'modelId': modelId,
    'category': category.index,
    'phase': phase.index,
    'downloadedBytes': downloadedBytes,
    'totalBytes': totalBytes,
    'startTime': startTime.toIso8601String(),
    'lastUpdate': lastUpdate?.toIso8601String(),
  };

  factory DownloadState.fromJson(Map<String, dynamic> json) => DownloadState(
    modelId: json['modelId'] as String,
    category: ModelCategory.values[json['category'] as int],
    phase: DownloadPhase.values[json['phase'] as int],
    downloadedBytes: json['downloadedBytes'] as int? ?? 0,
    totalBytes: json['totalBytes'] as int? ?? 0,
    startTime: DateTime.parse(json['startTime'] as String),
    lastUpdate: json['lastUpdate'] != null
        ? DateTime.parse(json['lastUpdate'] as String)
        : null,
  );

  DownloadState copyWith({
    DownloadPhase? phase,
    int? downloadedBytes,
    int? totalBytes,
    DateTime? lastUpdate,
  }) => DownloadState(
    modelId: modelId,
    category: category,
    phase: phase ?? this.phase,
    downloadedBytes: downloadedBytes ?? this.downloadedBytes,
    totalBytes: totalBytes ?? this.totalBytes,
    startTime: startTime,
    lastUpdate: lastUpdate ?? this.lastUpdate,
  );

  /// Check if this download should be recovered
  bool get shouldRecover {
    // Only recover downloads that were actively in progress
    return phase == DownloadPhase.downloading ||
           phase == DownloadPhase.preparingDownload ||
           phase == DownloadPhase.checkingCompatibility;
  }

  /// Check if this download is stale (older than 24 hours)
  bool get isStale {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return startTime.isBefore(cutoff);
  }
}

/// Persists download state using SharedPreferences for crash recovery
class DownloadStatePersistence {
  static const String _keyPrefix = 'download_state_';
  static const String _activeDownloadsKey = 'active_downloads';

  SharedPreferences? _prefs;

  /// Get SharedPreferences instance (lazy initialization)
  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Save a new download state
  Future<void> saveDownloadState(DownloadState state) async {
    final prefs = await _getPrefs();

    // Save the state
    await prefs.setString(
      '$_keyPrefix${state.modelId}',
      jsonEncode(state.toJson()),
    );

    // Add to active downloads list
    final activeDownloads = await _getActiveDownloadIds();
    if (!activeDownloads.contains(state.modelId)) {
      activeDownloads.add(state.modelId);
      await prefs.setStringList(_activeDownloadsKey, activeDownloads);
    }
  }

  /// Update progress for an existing download
  Future<void> updateDownloadProgress(
    String modelId,
    UnifiedDownloadProgress progress,
  ) async {
    final prefs = await _getPrefs();
    final existingJson = prefs.getString('$_keyPrefix$modelId');
    if (existingJson != null) {
      final state = DownloadState.fromJson(
        jsonDecode(existingJson) as Map<String, dynamic>,
      );
      final updated = state.copyWith(
        phase: progress.phase,
        downloadedBytes: progress.downloadedBytes,
        totalBytes: progress.totalBytes,
        lastUpdate: DateTime.now(),
      );
      await saveDownloadState(updated);
    }
  }

  /// Clear download state for a model
  Future<void> clearDownloadState(String modelId) async {
    final prefs = await _getPrefs();
    await prefs.remove('$_keyPrefix$modelId');

    // Remove from active downloads list
    final activeDownloads = await _getActiveDownloadIds();
    activeDownloads.remove(modelId);
    await prefs.setStringList(_activeDownloadsKey, activeDownloads);
  }

  /// Clear all download states
  Future<void> clearAllDownloadStates() async {
    final prefs = await _getPrefs();
    final activeDownloads = await _getActiveDownloadIds();
    for (final modelId in activeDownloads) {
      await prefs.remove('$_keyPrefix$modelId');
    }
    await prefs.setStringList(_activeDownloadsKey, []);
  }

  /// Get all pending downloads that need to be recovered
  Future<List<DownloadState>> getPendingDownloads() async {
    final prefs = await _getPrefs();
    final pending = <DownloadState>[];
    final activeDownloads = await _getActiveDownloadIds();

    for (final modelId in activeDownloads) {
      final json = prefs.getString('$_keyPrefix$modelId');
      if (json != null) {
        try {
          final state = DownloadState.fromJson(
            jsonDecode(json) as Map<String, dynamic>,
          );

          // Only recover if not stale and should be recovered
          if (state.shouldRecover && !state.isStale) {
            pending.add(state);
          } else {
            // Clean up stale or completed states
            await clearDownloadState(modelId);
          }
        } catch (e) {
          // Invalid state, clean it up
          await clearDownloadState(modelId);
        }
      }
    }

    return pending;
  }

  /// Get download state for a specific model
  Future<DownloadState?> getDownloadState(String modelId) async {
    final prefs = await _getPrefs();
    final json = prefs.getString('$_keyPrefix$modelId');
    if (json == null) return null;

    try {
      return DownloadState.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } catch (e) {
      // Invalid state, clean it up
      await clearDownloadState(modelId);
      return null;
    }
  }

  /// Check if there are any pending downloads
  Future<bool> hasPendingDownloads() async {
    final pending = await getPendingDownloads();
    return pending.isNotEmpty;
  }

  /// Get active download IDs from preferences
  Future<List<String>> _getActiveDownloadIds() async {
    final prefs = await _getPrefs();
    return prefs.getStringList(_activeDownloadsKey) ?? [];
  }

  /// Mark a download as completed
  Future<void> markDownloadCompleted(String modelId) async {
    final state = await getDownloadState(modelId);
    if (state != null) {
      final updated = state.copyWith(
        phase: DownloadPhase.completed,
        lastUpdate: DateTime.now(),
      );
      await saveDownloadState(updated);
    }
    // Then clear it since it's complete
    await clearDownloadState(modelId);
  }

  /// Mark a download as failed
  Future<void> markDownloadFailed(String modelId) async {
    await clearDownloadState(modelId);
  }
}

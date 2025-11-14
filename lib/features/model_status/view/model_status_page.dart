import 'package:flutter/material.dart';
import 'package:live_captions_xr/core/services/model_download_manager.dart';
import '../../../core/services/app_logger.dart';

class ModelStatusPage extends StatefulWidget {
  const ModelStatusPage({super.key});

  @override
  State<ModelStatusPage> createState() => _ModelStatusPageState();
}

class _ModelStatusPageState extends State<ModelStatusPage> {
  static final AppLogger _logger = AppLogger.instance;
  late ModelDownloadManager _modelDownloadManager;
  Map<String, Map<String, dynamic>> _modelStatus = {};

  @override
  void initState() {
    super.initState();
    _modelDownloadManager = ModelDownloadManager();
    _loadModelStatus();
  }

  Future<void> _loadModelStatus() async {
    final status = await _modelDownloadManager.checkAllModelStatus();
    if (mounted) {
      setState(() {
        _modelStatus = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadModelStatus,
            tooltip: 'Refresh Model Status',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadModelStatus,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_modelStatus.isNotEmpty) ...[
              _buildOverviewCard(),
              const SizedBox(height: 16),
              _buildDownloadSourcesCard(),
              const SizedBox(height: 24),
            ],
            _buildSectionHeader('Whisper Models'),
            ..._buildModelCards(ModelType.whisper),
            const SizedBox(height: 24),
            _buildSectionHeader('Gemma Models'),
            ..._buildModelCards(ModelType.gemma),
            const SizedBox(height: 24),
            _buildStorageInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    final totalModels = _modelDownloadManager.availableModels.length;
    if (totalModels == 0) {
      return const SizedBox.shrink();
    }

    int readyCount = 0;
    int downloadingCount = 0;
    int errorCount = 0;

    for (final entry in _modelStatus.values) {
      final exists = entry['exists'] as bool? ?? false;
      final complete = entry['complete'] as bool? ?? false;
      final downloading = entry['downloading'] as bool? ?? false;
      final hasError = (entry['error'] as String?)?.isNotEmpty ?? false;
      if (exists && complete && !hasError) {
        readyCount++;
      }
      if (downloading) {
        downloadingCount++;
      }
      if (hasError) {
        errorCount++;
      }
    }

    final pendingCount = (totalModels - readyCount).clamp(0, totalModels);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Model Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.check_circle,
                    color: Colors.green,
                    label: 'Ready',
                    value: '$readyCount / $totalModels',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.downloading,
                    color: Colors.blue,
                    label: 'Downloading',
                    value: '$downloadingCount',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.cloud_download,
                    color: Colors.orange,
                    label: 'Needs Download',
                    value: '$pendingCount',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.error,
                    color: Colors.red,
                    label: 'Errors',
                    value: '$errorCount',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadSourcesCard() {
    if (_modelStatus.isEmpty) {
      return const SizedBox.shrink();
    }

    final summary = <String, int>{};
    for (final entry in _modelStatus.values) {
      final exists = entry['exists'] as bool? ?? false;
      final source = entry['downloadSource'] as String?;
      final key = source ?? (exists ? 'unknown' : 'not-downloaded');
      summary[key] = (summary[key] ?? 0) + 1;
    }

    if (summary.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Download Sources',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: summary.entries
                  .map(
                    (entry) => _buildSourceSummaryChip(
                      entry.key,
                      entry.value,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[800],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceSummaryChip(String sourceName, int count) {
    final visuals = _downloadSourceVisuals(sourceName);
    final label = '${visuals.label} • $count';
    return Chip(
      avatar: Icon(
        visuals.icon,
        size: 16,
        color: visuals.color,
      ),
      backgroundColor: visuals.color.withValues(alpha: 0.12),
      label: Text(label),
      labelStyle: TextStyle(
        color: visuals.color,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  ({IconData icon, Color color, String label}) _downloadSourceVisuals(
    String sourceName,
  ) {
    switch (sourceName) {
      case 'huggingface':
        return (
          icon: Icons.cloud,
          color: Colors.orange.shade600,
          label: 'HuggingFace',
        );
      case 'bucket':
        return (
          icon: Icons.storage,
          color: Colors.blue.shade600,
          label: 'LiveCaptionsXR Bucket',
        );
      case 'assets':
        return (
          icon: Icons.folder,
          color: Colors.green.shade600,
          label: 'App Assets',
        );
      case 'not-downloaded':
        return (
          icon: Icons.cloud_download,
          color: Colors.grey.shade600,
          label: 'Not downloaded',
        );
      default:
        return (
          icon: Icons.help_outline,
          color: Colors.grey.shade600,
          label: 'Unknown Source',
        );
    }
  }

  Widget _buildTypeChip(ModelType type) {
    final isGemma = type == ModelType.gemma;
    final color = isGemma ? Colors.deepPurple.shade600 : Colors.teal.shade600;
    final icon = isGemma ? Icons.auto_awesome : Icons.graphic_eq;
    final label = isGemma ? 'Gemma' : 'Whisper';
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      backgroundColor: color.withValues(alpha: 0.12),
      label: Text(label),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDownloadTimestampChip(String formattedLabel) {
    return Chip(
      avatar: Icon(
        Icons.schedule,
        size: 16,
        color: Colors.grey.shade700,
      ),
      backgroundColor: Colors.grey.shade200,
      label: Text('Downloaded $formattedLabel'),
      labelStyle: TextStyle(
        color: Colors.grey.shade800,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String? _formatTimestampLabel(String? isoString) {
    if (isoString == null) {
      return null;
    }
    final parsed = DateTime.tryParse(isoString);
    if (parsed == null) {
      return null;
    }
    return _formatDownloadTimestamp(parsed.toLocal());
  }

  String _formatDownloadTimestamp(DateTime date) {
    final localizations = MaterialLocalizations.of(context);
    final dateLabel = localizations.formatShortDate(date);
    final alwaysUse24Hour =
        MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false;
    final timeLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(date),
      alwaysUse24HourFormat: alwaysUse24Hour,
    );
    return '$dateLabel • $timeLabel';
  }

  List<Widget> _buildModelCards(ModelType type) {
    final models = _modelDownloadManager.getModelsByType(type);
    return models.map((modelKey) => _buildModelCard(modelKey)).toList();
  }

  Widget _buildModelCard(String modelKey) {
    final status = _modelStatus[modelKey];
    final config = _modelDownloadManager.getModelConfig(modelKey);

    if (status == null || config == null) {
      return const SizedBox.shrink();
    }

    final exists = status['exists'] as bool? ?? false;
    final complete = status['complete'] as bool? ?? false;
    final downloading = status['downloading'] as bool? ?? false;
    final progress = status['progress'] as double? ?? 0.0;
    final error = status['error'] as String?;
    final downloadSource = status['downloadSource'] as String?;
    final downloadedAtRaw = status['downloadedAt'] as String?;
    final sourceInferred = status['sourceInferred'] as bool? ?? false;
    final formattedDownloadLabel = _formatTimestampLabel(downloadedAtRaw);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.displayName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatModelSize(config.expectedSize),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildTypeChip(config.type),
                          if (downloadSource != null)
                            _buildDownloadSourceChip(
                              downloadSource,
                              isInferred: sourceInferred,
                            ),
                          if (downloadSource == null && exists)
                            _buildDownloadSourceChip(
                              'unknown',
                              isInferred: true,
                            ),
                          if (formattedDownloadLabel != null)
                            _buildDownloadTimestampChip(formattedDownloadLabel),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusIcon(exists, complete, downloading, error),
              ],
            ),
            if (downloading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  'Error: $error',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (!exists || !complete) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          downloading ? null : () => _downloadModel(modelKey),
                      icon: downloading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label: Text(downloading ? 'Downloading...' : 'Download'),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _deleteModel(modelKey),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showModelInfo(modelKey, config),
                    icon: const Icon(Icons.info),
                    label: const Text('Info'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(
      bool exists, bool complete, bool downloading, String? error) {
    if (error != null) {
      return Icon(Icons.error, color: Colors.red, size: 24);
    }
    if (downloading) {
      return Icon(Icons.downloading, color: Colors.blue, size: 24);
    }
    if (complete) {
      return Icon(Icons.check_circle, color: Colors.green, size: 24);
    }
    if (exists) {
      return Icon(Icons.warning, color: Colors.orange, size: 24);
    }
    return Icon(Icons.cloud_download, color: Colors.grey, size: 24);
  }

  String _formatModelSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '$bytes B';
    }
  }

  Widget _buildStorageInfo() {
    final totalSize = _modelDownloadManager.getTotalModelsSize();
    final totalSizeGB = totalSize / (1024 * 1024 * 1024);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total models size: ${totalSizeGB.toStringAsFixed(1)} GB',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Available models: ${_modelDownloadManager.availableModels.length}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadModel(String modelKey) async {
    try {
      _logger.i('📥 Starting download for model: $modelKey');
      await _modelDownloadManager.downloadModel(modelKey);
      await _loadModelStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully downloaded ${_modelDownloadManager.getModelConfig(modelKey)?.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('❌ Failed to download model: $modelKey', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download model: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteModel(String modelKey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: Text(
          'Are you sure you want to delete ${_modelDownloadManager.getModelConfig(modelKey)?.displayName}? '
          'This will free up storage space but you\'ll need to download it again to use it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _modelDownloadManager.deleteModel(modelKey);
        await _loadModelStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success
                  ? 'Model deleted successfully'
                  : 'Failed to delete model'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        _logger.e('❌ Error deleting model: $modelKey', error: e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting model: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildDownloadSourceChip(
    String sourceName, {
    bool isInferred = false,
  }) {
    final visuals = _downloadSourceVisuals(sourceName);
    final tooltip = isInferred
        ? 'Source inferred from legacy downloads'
        : 'Downloaded via ${visuals.label}';
    final label = isInferred ? '${visuals.label} · legacy' : visuals.label;

    return Tooltip(
      message: tooltip,
      child: Chip(
        avatar: Icon(
          visuals.icon,
          size: 16,
          color: visuals.color,
        ),
        backgroundColor: visuals.color.withValues(alpha: 0.12),
        label: Text(label),
        labelStyle: TextStyle(
          color: visuals.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showModelInfo(String modelKey, ModelConfig config) async {
    final metadata =
        await _modelDownloadManager.getModelDownloadMetadata(modelKey);
    final sourceName = metadata?.source.name;
    final inferred = metadata?.isInferred ?? false;
    final downloadedLabel = metadata?.downloadedAt != null
        ? _formatDownloadTimestamp(metadata!.downloadedAt!.toLocal())
        : null;

    if (!mounted) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(config.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${config.type.name.toUpperCase()}'),
            Text('File: ${config.fileName}'),
            Text(
                'Size: ${(config.expectedSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB'),
            Text('URL: ${config.url}'),
            if (sourceName != null || downloadedLabel != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (sourceName != null)
                    _buildDownloadSourceChip(
                      sourceName,
                      isInferred: inferred,
                    ),
                  if (downloadedLabel != null)
                    _buildDownloadTimestampChip(downloadedLabel),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

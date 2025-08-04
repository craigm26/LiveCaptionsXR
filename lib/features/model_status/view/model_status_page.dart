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
    setState(() {
      _modelStatus = status;
    });
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      onPressed: downloading ? null : () => _downloadModel(modelKey),
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

  Widget _buildStatusIcon(bool exists, bool complete, bool downloading, String? error) {
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
            content: Text('Successfully downloaded ${_modelDownloadManager.getModelConfig(modelKey)?.displayName}'),
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

  void _showModelInfo(String modelKey, ModelConfig config) {
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
            Text('Size: ${(config.expectedSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB'),
            Text('URL: ${config.url}'),
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
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:nexa_ai_flutter/nexa_ai_flutter.dart';
import 'chat_page.dart';

class ModelManagementPage extends StatefulWidget {
  const ModelManagementPage({super.key});

  @override
  State<ModelManagementPage> createState() => _ModelManagementPageState();
}

class _ModelManagementPageState extends State<ModelManagementPage> {
  List<ModelInfo> _models = [];
  Set<String> _downloadedModels = {};
  Map<String, DownloadProgress> _downloadProgress = {};
  Map<String, ModelCompatibility> _modelCompatibility = {};
  StorageInfo? _storageInfo;
  DeviceInfo? _deviceInfo;
  bool _loading = true;
  String? _filter;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() => _loading = true);

    try {
      final models = await ModelDownloader.getAvailableModels();
      final downloaded = await ModelDownloader.getDownloadedModels();
      final storage = await ModelDownloader.getStorageInfo();
      final deviceInfo = await ModelDownloader.getDeviceInfo();

      // Check compatibility for each model
      final compatibility = <String, ModelCompatibility>{};
      for (final model in models) {
        try {
          final compat = await ModelDownloader.checkModelCompatibility(model.id);
          compatibility[model.id] = compat;
        } catch (e) {
          log('Error checking compatibility for ${model.id}: $e');
        }
      }

      setState(() {
        _models = models;
        _downloadedModels = downloaded.toSet();
        _storageInfo = storage;
        _deviceInfo = deviceInfo;
        _modelCompatibility = compatibility;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      log('Error loading models: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading models: $e')));
      }
    }
  }

  void _downloadModel(ModelInfo model) {
    final downloader = ModelDownloader();

    downloader
        .downloadModel(model.id)
        .listen(
          (progress) {
            setState(() {
              _downloadProgress[model.id] = progress;
            });

            if (progress.status == DownloadStatus.completed) {
              setState(() {
                _downloadedModels.add(model.id);
                _downloadProgress.remove(model.id);
              });
              _loadModels(); // Refresh storage info
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${model.displayName} downloaded!')));
            } else if (progress.status == DownloadStatus.failed) {
              log('Download failed for ${model.displayName}');
              setState(() {
                _downloadProgress.remove(model.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed for ${model.displayName}')));
            }
          },
          onError: (error) {
            log('Error: $error');
            setState(() {
              _downloadProgress.remove(model.id);
            });
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
          },
        );
  }

  Future<void> _deleteModel(ModelInfo model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: Text('Delete ${model.displayName}? (${model.sizeGb} GB will be freed)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ModelDownloader.deleteModel(model.id);
        setState(() {
          _downloadedModels.remove(model.id);
        });
        _loadModels(); // Refresh storage info
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${model.displayName} deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting model: $e')));
        }
      }
    }
  }

  void _cancelDownload(String modelId) async {
    await ModelDownloader.cancelDownload(modelId);
    setState(() {
      _downloadProgress.remove(modelId);
    });
  }

  List<ModelInfo> get _filteredModels {
    if (_filter == null) return _models;
    return _models.where((m) => m.type == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadModels)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Device Info Card
                if (_deviceInfo != null) _buildDeviceInfoCard(),

                // Storage Info Card
                if (_storageInfo != null) _buildStorageCard(),

                // Filter Chips
                _buildFilterChips(),

                // Model List
                Expanded(
                  child: _filteredModels.isEmpty
                      ? const Center(child: Text('No models available'))
                      : ListView.builder(
                          itemCount: _filteredModels.length,
                          itemBuilder: (context, index) {
                            final model = _filteredModels[index];
                            return _buildModelCard(model);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDeviceInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16).copyWith(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone_android, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Your Device', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_deviceInfo!.deviceModel, style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text(_deviceInfo!.chipsetFriendlyName, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _deviceInfo!.hasNpu ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    _deviceInfo!.hasNpu ? 'NPU Supported' : 'CPU/GPU Only',
                    style: TextStyle(color: _deviceInfo!.hasNpu ? Colors.green[700] : Colors.orange[700], fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_deviceInfo!.performanceLevelText, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Storage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Total: ${_storageInfo!.totalSpaceGB.toStringAsFixed(2)} GB'), Text('Free: ${_storageInfo!.freeSpaceGB.toStringAsFixed(2)} GB')],
            ),
            const SizedBox(height: 4),
            Text('Used by models: ${_storageInfo!.usedByModelsGB.toStringAsFixed(2)} GB', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: (_storageInfo!.totalSpace - _storageInfo!.freeSpace) / _storageInfo!.totalSpace),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final types = ['all', 'multimodal', 'chat', 'embedder', 'asr', 'reranker', 'paddleocr'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: types.map((type) {
          final isSelected = (_filter == null && type == 'all') || _filter == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(type == 'all' ? 'All' : type),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _filter = type == 'all' ? null : type;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModelCard(ModelInfo model) {
    final isDownloaded = _downloadedModels.contains(model.id);
    final progress = _downloadProgress[model.id];
    final isDownloading = progress != null;
    final compatibility = _modelCompatibility[model.id];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: Icon(_getIconForType(model.type), color: isDownloaded ? Colors.green : Colors.grey),
        title: Row(
          children: [
            Expanded(child: Text(model.displayName)),
            if (compatibility != null) Text(compatibility.compatibilityEmoji, style: const TextStyle(fontSize: 20)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${model.sizeGb} GB • ${model.params} • ${model.features.join(", ")}'),
            if (compatibility != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  compatibility.isCompatible ? '${compatibility.speedText} on your device' : 'Not supported - requires ${compatibility.requiredPlugin.toUpperCase()}',
                  style: TextStyle(
                    color: compatibility.isCompatible ? (compatibility.expectedSpeed == 'fast' ? Colors.green : Colors.orange) : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        trailing: isDownloading
            ? SizedBox(
                width: 60,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${progress.percentage}%'),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: progress.percentage / 100),
                  ],
                ),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${model.type}'),
                Text('Model ID: ${model.id}'),
                if (compatibility != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: compatibility.isCompatible ? (compatibility.expectedSpeed == 'fast' ? Colors.green : Colors.orange).withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: compatibility.isCompatible ? (compatibility.expectedSpeed == 'fast' ? Colors.green : Colors.orange) : Colors.red, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          compatibility.isCompatible ? (compatibility.expectedSpeed == 'fast' ? Icons.check_circle : Icons.info) : Icons.warning,
                          color: compatibility.isCompatible ? (compatibility.expectedSpeed == 'fast' ? Colors.green : Colors.orange) : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            compatibility.recommendation,
                            style: TextStyle(
                              fontSize: 12,
                              color: compatibility.isCompatible ? (compatibility.expectedSpeed == 'fast' ? Colors.green[800] : Colors.orange[800]) : Colors.red[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (isDownloading) ...[
                  const SizedBox(height: 8),
                  Text('Speed: ${progress.speedMBps.toStringAsFixed(2)} MB/s', style: TextStyle(color: Colors.grey[600])),
                  Text(
                    '${(progress.downloadedBytes / (1024 * 1024)).toStringAsFixed(2)} / ${(progress.totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isDownloading)
                      ElevatedButton.icon(
                        onPressed: () => _cancelDownload(model.id),
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      )
                    else if (isDownloaded) ...[
                      if (compatibility?.isCompatible == true && (model.type == 'chat' || model.type == 'multimodal'))
                        ElevatedButton.icon(
                          onPressed: () => _openChat(model),
                          icon: const Icon(Icons.chat),
                          label: const Text('Chat'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      if (compatibility?.isCompatible == true && (model.type == 'chat' || model.type == 'multimodal')) const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _deleteModel(model),
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ] else
                      ElevatedButton.icon(
                        onPressed: compatibility?.isCompatible == true ? () => _downloadModel(model) : null,
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(ModelInfo model) async {
    try {
      final modelPath = await ModelDownloader.getModelPath(model.id);
      if (modelPath != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatPage(modelId: model.id, modelName: model.displayName, modelPath: modelPath, modelType: model.type, compatibility: _modelCompatibility[model.id]),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Model path not found')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening chat: $e')));
      }
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'multimodal':
        return Icons.image;
      case 'chat':
        return Icons.chat;
      case 'embedder':
        return Icons.account_tree;
      case 'asr':
        return Icons.mic;
      case 'reranker':
        return Icons.sort;
      case 'paddleocr':
        return Icons.camera_alt;
      default:
        return Icons.model_training;
    }
  }
}

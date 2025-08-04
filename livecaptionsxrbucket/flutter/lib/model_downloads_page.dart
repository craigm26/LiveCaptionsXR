import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// Enum for different model types
enum ModelType {
  gemma,
  whisper,
}

/// Model configuration class
class ModelConfig {
  final String fileName;
  final String url;
  final int expectedSize;
  final ModelType type;
  final String displayName;
  final String description;

  const ModelConfig({
    required this.fileName,
    required this.url,
    required this.expectedSize,
    required this.type,
    required this.displayName,
    required this.description,
  });
}

/// Model status information
class ModelStatus {
  final String key;
  final String displayName;
  final ModelType type;
  final bool exists;
  final bool complete;
  final bool downloading;
  final double progress;
  final String? error;
  final int expectedSize;
  final String url;

  const ModelStatus({
    required this.key,
    required this.displayName,
    required this.type,
    required this.exists,
    required this.complete,
    required this.downloading,
    required this.progress,
    this.error,
    required this.expectedSize,
    required this.url,
  });

  bool get isReady => exists && complete && !downloading && error == null;
  bool get needsDownload => !exists || !complete;
  bool get hasError => error != null;
}

/// Model download manager
class ModelDownloadManager extends ChangeNotifier {
  // Model configurations
  static const Map<String, ModelConfig> _modelConfigs = {
    'whisper-base': ModelConfig(
      fileName: 'whisper_base.bin',
      url: 'https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/whisper_base.bin',
      expectedSize: 147951465, // 141 MB
      type: ModelType.whisper,
      displayName: 'Whisper Base Model',
      description: 'Fast speech recognition model for real-time transcription',
    ),
    'gemma-3n-e2b': ModelConfig(
      fileName: 'gemma-3n-E2B-it-int4.task',
      url: 'https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/gemma-3n-E2B-it-int4.task',
      expectedSize: 3137331200, // 2.92 GB
      type: ModelType.gemma,
      displayName: 'Gemma 3N E2B Model',
      description: 'Advanced language model for enhanced text processing',
    ),
    'gemma-3n-e4b': ModelConfig(
      fileName: 'gemma-3n-E4B-it-int4.task',
      url: 'https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr/gemma-3n-E4B-it-int4.task',
      expectedSize: 4411973632, // 4.11 GB
      type: ModelType.gemma,
      displayName: 'Gemma 3N E4B Model',
      description: 'Large-scale language model for maximum performance',
    ),
  };

  // Download state
  final Map<String, double> _progress = {};
  final Map<String, String?> _errors = {};
  final Map<String, bool> _downloading = {};
  final Map<String, bool> _completed = {};

  // Getters
  double getProgress(String modelKey) => _progress[modelKey] ?? 0.0;
  String? getError(String modelKey) => _errors[modelKey];
  bool isDownloading(String modelKey) => _downloading[modelKey] ?? false;
  bool isCompleted(String modelKey) => _completed[modelKey] ?? false;
  
  // Get all available model keys
  List<String> get availableModels => _modelConfigs.keys.toList();
  
  // Get model config
  ModelConfig? getModelConfig(String modelKey) => _modelConfigs[modelKey];

  /// Get the path where a model should be stored
  Future<String> getModelPath(String modelKey) async {
    final config = _modelConfigs[modelKey];
    if (config == null) {
      throw ArgumentError('Unknown model key: $modelKey');
    }

    final dir = await getApplicationDocumentsDirectory();
    final modelDir = '${dir.path}/models';
    
    // Create directory if it doesn't exist
    final modelDirFile = Directory(modelDir);
    if (!await modelDirFile.exists()) {
      await modelDirFile.create(recursive: true);
    }
    
    return '$modelDir/${config.fileName}';
  }

  /// Check if a model file exists
  Future<bool> modelExists(String modelKey) async {
    final config = _modelConfigs[modelKey];
    if (config == null) return false;
    
    final path = await getModelPath(modelKey);
    return File(path).existsSync();
  }

  /// Check if a model file is complete
  Future<bool> modelIsComplete(String modelKey) async {
    final config = _modelConfigs[modelKey];
    if (config == null) return false;
    
    final path = await getModelPath(modelKey);
    final file = File(path);
    if (await file.exists()) {
      final stat = await file.stat();
      return stat.size >= config.expectedSize;
    }
    return false;
  }

  /// Download a specific model
  Future<void> downloadModel(String modelKey) async {
    final config = _modelConfigs[modelKey];
    if (config == null) {
      throw ArgumentError('Unknown model key: $modelKey');
    }

    _downloading[modelKey] = true;
    _completed[modelKey] = false;
    _errors[modelKey] = null;
    _progress[modelKey] = 0.0;
    notifyListeners();

    try {
      final path = await getModelPath(modelKey);
      final file = File(path);
      
      // Create parent directory if it doesn't exist
      final parentDir = Directory(file.parent.path);
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      final request = http.Request('GET', Uri.parse(config.url));
      final response = await request.send();
      
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }

      final contentLength = response.contentLength ?? 0;
      int bytesReceived = 0;
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        bytesReceived += chunk.length;
        if (contentLength > 0) {
          _progress[modelKey] = bytesReceived / contentLength;
          notifyListeners();
        }
      }

      await sink.close();
      _progress[modelKey] = 1.0;
      _completed[modelKey] = true;
      _downloading[modelKey] = false;
      notifyListeners();
    } catch (e) {
      _errors[modelKey] = e.toString();
      _downloading[modelKey] = false;
      _completed[modelKey] = false;
      notifyListeners();
    }
  }

  /// Get comprehensive model status for all models
  Future<Map<String, ModelStatus>> getDetailedModelStatus() async {
    final status = <String, ModelStatus>{};
    
    for (final modelKey in _modelConfigs.keys) {
      final config = _modelConfigs[modelKey]!;
      final exists = await modelExists(modelKey);
      final complete = await modelIsComplete(modelKey);
      final downloading = isDownloading(modelKey);
      final error = getError(modelKey);
      
      status[modelKey] = ModelStatus(
        key: modelKey,
        displayName: config.displayName,
        type: config.type,
        exists: exists,
        complete: complete,
        downloading: downloading,
        progress: getProgress(modelKey),
        error: error,
        expectedSize: config.expectedSize,
        url: config.url,
      );
    }
    
    return status;
  }

  /// Delete a model file
  Future<bool> deleteModel(String modelKey) async {
    try {
      final path = await getModelPath(modelKey);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        _progress[modelKey] = 0.0;
        _errors[modelKey] = null;
        _downloading[modelKey] = false;
        _completed[modelKey] = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errors[modelKey] = e.toString();
      notifyListeners();
      return false;
    }
  }
}

/// Model download page
class ModelDownloadsPage extends StatefulWidget {
  const ModelDownloadsPage({super.key});

  @override
  State<ModelDownloadsPage> createState() => _ModelDownloadsPageState();
}

class _ModelDownloadsPageState extends State<ModelDownloadsPage> {
  final ModelDownloadManager _downloadManager = ModelDownloadManager();
  Map<String, ModelStatus> _modelStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModelStatus();
    _downloadManager.addListener(_onDownloadManagerChanged);
  }

  @override
  void dispose() {
    _downloadManager.removeListener(_onDownloadManagerChanged);
    super.dispose();
  }

  void _onDownloadManagerChanged() {
    _loadModelStatus();
  }

  Future<void> _loadModelStatus() async {
    setState(() => _isLoading = true);
    final status = await _downloadManager.getDetailedModelStatus();
    setState(() {
      _modelStatus = status;
      _isLoading = false;
    });
  }

  Future<void> _downloadModel(String modelKey) async {
    await _downloadManager.downloadModel(modelKey);
  }

  Future<void> _deleteModel(String modelKey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: Text('Are you sure you want to delete ${_modelStatus[modelKey]?.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _downloadManager.deleteModel(modelKey);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '$bytes B';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Model Downloads'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadModelStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadModelStatus,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _modelStatus.length,
                itemBuilder: (context, index) {
                  final modelKey = _modelStatus.keys.elementAt(index);
                  final status = _modelStatus[modelKey]!;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                status.type == ModelType.whisper 
                                    ? Icons.mic 
                                    : Icons.psychology,
                                color: Colors.blue[600],
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      status.displayName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _formatBytes(status.expectedSize),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (status.isReady)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 24,
                                ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          if (status.downloading) ...[
                            LinearProgressIndicator(
                              value: status.progress,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Downloading... ${(status.progress * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                          
                          if (status.hasError) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Text(
                                'Error: ${status.error}',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              if (!status.isReady && !status.downloading)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _downloadModel(modelKey),
                                    icon: const Icon(Icons.download),
                                    label: const Text('Download'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[600],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              if (status.downloading)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: null,
                                    icon: const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    label: const Text('Downloading...'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[400],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              if (status.isReady) ...[
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${status.displayName} is ready to use!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.check),
                                    label: const Text('Ready'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _deleteModel(modelKey),
                                  icon: const Icon(Icons.delete),
                                  label: const Text('Delete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[600],
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

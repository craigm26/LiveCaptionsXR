import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

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

  const ModelConfig({
    required this.fileName,
    required this.url,
    required this.expectedSize,
    required this.type,
    required this.displayName,
  });
}

class ModelDownloadManager extends ChangeNotifier {
  // Model configurations
  static const Map<String, ModelConfig> _modelConfigs = {
    'gemma-3n-E4B-it-int4': ModelConfig(
      fileName: 'gemma-3n-E4B-it-int4.task',
      url: 'https://livecaptionsxrbucket.com/gemma-3n-E4B-it-int4.task',
      expectedSize: 4398046511, // 4.1 GB
      type: ModelType.gemma,
      displayName: 'Gemma 3n Multimodal',
    ),
    'whisper-base': ModelConfig(
      fileName: 'whisper_base.bin',
      url: 'https://livecaptionsxrbucket.com/whisper_base.bin',
      expectedSize: 155189248, // 147.95 MB (147.95 * 1024 * 1024)
      type: ModelType.whisper,
      displayName: 'Whisper Base',
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
    final modelDir = config.type == ModelType.whisper 
        ? '${dir.path}/whisper_models'
        : dir.path;
    
    // Create directory if it doesn't exist
    final modelDirFile = Directory(modelDir);
    if (!await modelDirFile.exists()) {
      await modelDirFile.create(recursive: true);
    }
    
    return '$modelDir/${config.fileName}';
  }

  /// Check if a model file exists
  Future<bool> modelExists(String modelKey) async {
    final path = await getModelPath(modelKey);
    return File(path).existsSync();
  }

  /// Check if a model file is complete (not partial)
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

  /// Get the total size of all models
  int getTotalModelsSize() {
    return _modelConfigs.values.fold(0, (sum, config) => sum + config.expectedSize);
  }

  /// Get the size of a specific model
  int getModelSize(String modelKey) {
    return _modelConfigs[modelKey]?.expectedSize ?? 0;
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
        throw Exception('Failed to download model: ${response.statusCode}');
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

  /// Download multiple models
  Future<void> downloadModels(List<String> modelKeys) async {
    for (final modelKey in modelKeys) {
      await downloadModel(modelKey);
    }
  }

  /// Get download status for all models
  Map<String, Map<String, dynamic>> getAllModelStatus() {
    final status = <String, Map<String, dynamic>>{};
    
    for (final modelKey in _modelConfigs.keys) {
      status[modelKey] = {
        'exists': false,
        'complete': false,
        'downloading': isDownloading(modelKey),
        'progress': getProgress(modelKey),
        'error': getError(modelKey),
        'config': _modelConfigs[modelKey],
      };
    }
    
    return status;
  }

  /// Check status of all models (async)
  Future<Map<String, Map<String, dynamic>>> checkAllModelStatus() async {
    final status = <String, Map<String, dynamic>>{};
    
    for (final modelKey in _modelConfigs.keys) {
      status[modelKey] = {
        'exists': await modelExists(modelKey),
        'complete': await modelIsComplete(modelKey),
        'downloading': isDownloading(modelKey),
        'progress': getProgress(modelKey),
        'error': getError(modelKey),
        'config': _modelConfigs[modelKey],
      };
    }
    
    return status;
  }

  /// Reset download state for a specific model
  void resetModel(String modelKey) {
    _progress[modelKey] = 0.0;
    _errors[modelKey] = null;
    _downloading[modelKey] = false;
    _completed[modelKey] = false;
    notifyListeners();
  }

  /// Reset all download states
  void reset() {
    _progress.clear();
    _errors.clear();
    _downloading.clear();
    _completed.clear();
    notifyListeners();
  }

  /// Delete a model file
  Future<bool> deleteModel(String modelKey) async {
    try {
      final path = await getModelPath(modelKey);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        resetModel(modelKey);
        return true;
      }
      return false;
    } catch (e) {
      _errors[modelKey] = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Get models by type
  List<String> getModelsByType(ModelType type) {
    return _modelConfigs.entries
        .where((entry) => entry.value.type == type)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get Whisper models
  List<String> get whisperModels => getModelsByType(ModelType.whisper);
  
  /// Get Gemma models
  List<String> get gemmaModels => getModelsByType(ModelType.gemma);
}

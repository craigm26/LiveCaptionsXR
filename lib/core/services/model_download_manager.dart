import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'debug_capturing_logger.dart';

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
  final String assetPath; // Path to the model in assets directory

  const ModelConfig({
    required this.fileName,
    required this.url,
    required this.expectedSize,
    required this.type,
    required this.displayName,
    required this.assetPath,
  });
}

class ModelDownloadManager extends ChangeNotifier {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();
  
  // Model configurations
  static const Map<String, ModelConfig> _modelConfigs = {
    'gemma-3n-E4B-it-int4': ModelConfig(
      fileName: 'gemma-3n-E4B-it-int4.task',
      url: 'https://livecaptionsxrbucket.com/gemma-3n-E4B-it-int4.task',
      expectedSize: 4398046511, // 4.1 GB
      type: ModelType.gemma,
      displayName: 'Gemma 3n Multimodal',
      assetPath: 'assets/models/gemma-3n-E4B-it-int4.task',
    ),
    'whisper-base': ModelConfig(
      fileName: 'ggml-base.bin',
      url: 'https://livecaptionsxrbucket.com/whisper_base.bin',
      expectedSize: 155189248, // 147.95 MB (147.95 * 1024 * 1024)
      type: ModelType.whisper,
      displayName: 'Whisper Base',
      assetPath: 'assets/models/whisper_base.bin',
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
        ? '${dir.path}/models'
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
    final config = _modelConfigs[modelKey];
    if (config == null) {
      _logger.w('⚠️ Unknown model key: $modelKey');
      return false;
    }
    
    _logger.d('🔍 Checking if model exists: $modelKey');
    
    // First check if the model exists in the documents directory
    final path = await getModelPath(modelKey);
    final fileExists = File(path).existsSync();
    
    _logger.d('📁 Model file exists in documents: $fileExists (path: $path)');
    
    if (fileExists) {
      _logger.d('✅ Model found in documents directory: $modelKey');
      return true;
    }
    
    // If not in documents, check if it exists as an asset
    _logger.d('🔍 Checking if model exists as asset: ${config.assetPath}');
    final assetExists = await _assetExists(config.assetPath);
    _logger.d('📦 Model exists as asset: $assetExists (${config.assetPath})');
    
    if (assetExists) {
      _logger.i('✅ Model found as asset: $modelKey');
    } else {
      _logger.w('⚠️ Model not found in documents or assets: $modelKey');
    }
    
    return assetExists;
  }

  /// Check if a model file is complete (not partial)
  Future<bool> modelIsComplete(String modelKey) async {
    final config = _modelConfigs[modelKey];
    if (config == null) {
      _logger.w('⚠️ Unknown model key: $modelKey');
      return false;
    }
    
    _logger.d('🔍 Checking if model is complete: $modelKey');
    
    // First check if the model exists in the documents directory
    final path = await getModelPath(modelKey);
    final file = File(path);
    if (await file.exists()) {
      final stat = await file.stat();
      final isComplete = stat.size >= config.expectedSize;
      _logger.d('📁 Model file in documents: size=${stat.size}, expected=${config.expectedSize}, complete=$isComplete');
      return isComplete;
    }
    
    // If not in documents, check if it exists as an asset (assets are always complete)
    _logger.d('🔍 Checking if model is complete as asset: ${config.assetPath}');
    final assetExists = await _assetExists(config.assetPath);
    _logger.d('📦 Model complete as asset: $assetExists (${config.assetPath})');
    
    if (assetExists) {
      _logger.i('✅ Model is complete as asset: $modelKey');
    } else {
      _logger.w('⚠️ Model not complete in documents or assets: $modelKey');
    }
    
    return assetExists;
  }

  /// Check if a model exists in the assets directory
  Future<bool> _assetExists(String assetPath) async {
    try {
      _logger.d('📦 Attempting to load asset: $assetPath');
      await rootBundle.load(assetPath);
      _logger.d('✅ Asset loaded successfully: $assetPath');
      return true;
    } catch (e) {
      _logger.w('⚠️ Failed to load asset: $assetPath - $e');
      return false;
    }
  }

  /// Copy a model from assets to the documents directory
  Future<void> _copyAssetToDocuments(String modelKey) async {
    final config = _modelConfigs[modelKey];
    if (config == null) {
      throw ArgumentError('Unknown model key: $modelKey');
    }

    _logger.d('📋 Copying model from assets to documents: $modelKey');
    final targetPath = await getModelPath(modelKey);
    final targetFile = File(targetPath);
    
    _logger.d('📁 Target path: $targetPath');
    
    // Create parent directory if it doesn't exist
    final parentDir = Directory(targetFile.parent.path);
    if (!await parentDir.exists()) {
      _logger.d('📁 Creating parent directory: ${parentDir.path}');
      await parentDir.create(recursive: true);
    }

    // Load the asset
    _logger.d('📦 Loading asset: ${config.assetPath}');
    final assetBytes = await rootBundle.load(config.assetPath);
    _logger.d('📦 Asset loaded, size: ${assetBytes.lengthInBytes} bytes');
    
    // Write to documents directory with the correct filename
    _logger.d('💾 Writing model to documents: $targetPath');
    await targetFile.writeAsBytes(assetBytes.buffer.asUint8List());
    _logger.d('✅ Model written to documents: $targetPath');
    
    // For Whisper models, also create a copy with the expected name
    if (config.type == ModelType.whisper) {
      final expectedName = 'ggml-${modelKey.replaceFirst('whisper-', '')}.bin';
      final expectedPath = '${parentDir.path}/$expectedName';
      final expectedFile = File(expectedPath);
      
      _logger.d('📁 Creating Whisper model copy: $expectedPath');
      
      if (!await expectedFile.exists()) {
        await expectedFile.writeAsBytes(assetBytes.buffer.asUint8List());
        _logger.i('📁 Created Whisper model file: $expectedPath');
      } else {
        _logger.d('📁 Whisper model file already exists: $expectedPath');
      }
    }
    
    _logger.i('✅ Model copy from assets completed: $modelKey');
  }

  /// Get the total size of all models
  int getTotalModelsSize() {
    return _modelConfigs.values.fold(0, (sum, config) => sum + config.expectedSize);
  }

  /// Get the size of a specific model
  int getModelSize(String modelKey) {
    return _modelConfigs[modelKey]?.expectedSize ?? 0;
  }

  /// Download a specific model (or copy from assets if available)
  Future<void> downloadModel(String modelKey) async {
    final config = _modelConfigs[modelKey];
    if (config == null) {
      throw ArgumentError('Unknown model key: $modelKey');
    }

    _logger.i('📥 Starting model download/copy process: $modelKey');
    _downloading[modelKey] = true;
    _completed[modelKey] = false;
    _errors[modelKey] = null;
    _progress[modelKey] = 0.0;
    notifyListeners();

    try {
      // First, check if the model exists in assets
      _logger.d('🔍 Checking if model exists in assets: ${config.assetPath}');
      final assetExists = await _assetExists(config.assetPath);
      
      if (assetExists) {
        _logger.i('📦 Model found in assets, copying to documents: $modelKey');
        // Copy from assets instead of downloading
        _progress[modelKey] = 0.5;
        notifyListeners();
        
        await _copyAssetToDocuments(modelKey);
        
        _progress[modelKey] = 1.0;
        _completed[modelKey] = true;
        _downloading[modelKey] = false;
        _logger.i('✅ Model copied from assets successfully: $modelKey');
        notifyListeners();
        return;
      }

      _logger.w('⚠️ Model not found in assets, attempting remote download: $modelKey');
      // Fallback to downloading from remote URL if asset doesn't exist
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

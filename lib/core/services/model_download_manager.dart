import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'app_logger.dart';

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
  final String? termsNotice; // Terms of use notice for specific models

  const ModelConfig({
    required this.fileName,
    required this.url,
    required this.expectedSize,
    required this.type,
    required this.displayName,
    required this.assetPath,
    this.termsNotice,
  });
}

class ModelDownloadManager extends ChangeNotifier {
  static final AppLogger _logger = AppLogger.instance;
  
  // Gemma Terms of Use notice as required by Google
  static const String _gemmaTermsNotice = 
      'Gemma is provided under and subject to the Gemma Terms of Use found at ai.google.dev/gemma/terms. '
      'Users must comply with the Gemma Prohibited Use Policy at ai.google.dev/gemma/prohibited_use_policy '
      'and applicable laws and regulations.';
  
  // Model configurations
  static const Map<String, ModelConfig> _modelConfigs = {
    'gemma-3n-E2B-it-int4': ModelConfig(
      fileName: 'gemma-3n-E2B-it-int4.task',
      url: 'https://livecaptionsxrbucket.com/gemma-3n-E2B-it-int4.task',
      expectedSize: 3133601792, // 2.92 GB
      type: ModelType.gemma,
      displayName: 'Gemma 3n E2B',
      assetPath: 'assets/models/gemma-3n-E2B-it-int4.task',
      termsNotice: _gemmaTermsNotice,
    ),
    'gemma-3n-E4B-it-int4': ModelConfig(
      fileName: 'gemma-3n-E4B-it-int4.task',
      url: 'https://livecaptionsxrbucket.com/gemma-3n-E4B-it-int4.task',
      expectedSize: 4398046511, // 4.1 GB
      type: ModelType.gemma,
      displayName: 'Gemma 3n Multimodal',
      assetPath: 'assets/models/gemma-3n-E4B-it-int4.task',
      termsNotice: _gemmaTermsNotice,
    ),
    'whisper-base': ModelConfig(
      fileName: 'ggml-base.bin',
      url: 'https://livecaptionsxrbucket.com/whisper_base.bin',
      expectedSize: 147951465, // Actual size from server
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

  /// Get terms notice for a specific model
  String? getTermsNotice(String modelKey) {
    return _modelConfigs[modelKey]?.termsNotice;
  }

  /// Get all models that require terms notices
  List<String> getModelsWithTermsNotices() {
    return _modelConfigs.entries
        .where((entry) => entry.value.termsNotice != null)
        .map((entry) => entry.key)
        .toList();
  }

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
      
      // Try to get the actual file size from server for comparison
      int? serverSize;
      try {
        final response = await http.head(Uri.parse(config.url));
        if (response.statusCode == 200) {
          serverSize = int.tryParse(response.headers['content-length'] ?? '');
          _logger.d('🌐 Server file size: $serverSize bytes');
        }
      } catch (e) {
        _logger.w('⚠️ Could not check server file size: $e');
      }
      
      // Use server size if available, otherwise fall back to config expected size
      final expectedSize = serverSize ?? config.expectedSize;
      final isComplete = stat.size >= expectedSize;
      
      // Additional validation: check if file is corrupted or empty
      final isValidFile = stat.size > 0 && await _validateModelFile(file, modelKey);
      
      _logger.d('📁 Model file in documents: size=${stat.size}, expected=$expectedSize, complete=$isComplete, valid=$isValidFile');
      return isComplete && isValidFile;
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

  /// Validate model file integrity
  Future<bool> _validateModelFile(File file, String modelKey) async {
    try {
      final config = _modelConfigs[modelKey];
      if (config == null) return false;
      
      // Check file size is reasonable (not empty, not too small)
      final stat = await file.stat();
      if (stat.size < 1024) { // Less than 1KB is suspicious
        _logger.w('⚠️ Model file too small: ${stat.size} bytes');
        return false;
      }
      
      // For Whisper models, check if it's a valid GGML file
      if (config.type == ModelType.whisper) {
        final bytes = await file.openRead(0, 16).first; // Read first 16 bytes
        // Check for GGML magic number or common model file patterns
        if (bytes.length >= 4) {
          final magic = bytes.take(4).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
          _logger.d('🔍 Model file magic: $magic');
          // GGML files typically start with specific patterns
          if (magic.startsWith('67676d6c') || magic.startsWith('67676d6d')) { // "ggml" or "ggmm"
            _logger.d('✅ Valid GGML model file detected');
            return true;
          }
        }
      }
      
      // For Gemma models, check if it's a valid task file
      if (config.type == ModelType.gemma) {
        final bytes = await file.openRead(0, 16).first; // Read first 16 bytes
        if (bytes.length >= 4) {
          final magic = bytes.take(4).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
          _logger.d('🔍 Model file magic: $magic');
          // Task files might have different patterns, but we can check for non-zero content
          if (bytes.any((b) => b != 0)) {
            _logger.d('✅ Valid Gemma model file detected');
            return true;
          }
        }
      }
      
      // If we can't validate the format, assume it's valid if it's not empty
      _logger.d('⚠️ Could not validate model format, assuming valid');
      return true;
    } catch (e) {
      _logger.e('❌ Error validating model file: $e');
      return false;
    }
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

      _logger.i('🌐 Downloading from URL: ${config.url}');
      final request = http.Request('GET', Uri.parse(config.url));
      final response = await request.send();
      
      _logger.i('📡 HTTP response status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        final errorMessage = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        _logger.e('❌ Download failed: $errorMessage');
        throw Exception('Failed to download model: $errorMessage');
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
      _logger.e('❌ Download error for $modelKey: $e');
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
        _logger.i('🗑️ Deleted model file: $modelKey');
        return true;
      }
      return false;
    } catch (e) {
      _errors[modelKey] = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear partial download and retry
  Future<void> retryDownload(String modelKey) async {
    _logger.i('🔄 Retrying download for: $modelKey');
    
    // Delete partial file if it exists
    final path = await getModelPath(modelKey);
    final file = File(path);
    if (await file.exists()) {
      final stat = await file.stat();
      final config = _modelConfigs[modelKey];
      if (config != null && stat.size < config.expectedSize) {
        _logger.i('🗑️ Deleting partial download: ${stat.size} bytes (expected: ${config.expectedSize})');
        await file.delete();
      }
    }
    
    // Reset state and retry
    resetModel(modelKey);
    await downloadModel(modelKey);
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
        termsNotice: config.termsNotice,
      );
    }
    
    return status;
  }
}

/// Comprehensive model status information
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
  final String? termsNotice;

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
    this.termsNotice,
  });

  bool get isReady => exists && complete && !downloading && error == null;
  bool get needsDownload => !exists || !complete;
  bool get hasError => error != null;

  @override
  String toString() {
    return 'ModelStatus($key: exists=$exists, complete=$complete, downloading=$downloading, error=$error)';
  }
}

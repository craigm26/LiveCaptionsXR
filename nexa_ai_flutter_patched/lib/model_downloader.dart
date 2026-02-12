import 'package:flutter/services.dart';
import 'models/models.dart';

class ModelDownloader {
  static const MethodChannel _channel = MethodChannel('nexa_ai_flutter');
  static const EventChannel _progressChannel =
      EventChannel('nexa_ai_flutter/download_progress');

  /// Get list of all available models from the bundled model list
  static Future<List<ModelInfo>> getAvailableModels() async {
    try {
      final result = await _channel.invokeMethod('getAvailableModels');
      final modelList = result as List<dynamic>;
      return modelList
          .map((m) => ModelInfo.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList();
    } on PlatformException catch (e) {
      throw Exception('Failed to get available models: ${e.message}');
    }
  }

  /// Get models filtered by type
  static Future<List<ModelInfo>> getModelsByType(String type) async {
    final allModels = await getAvailableModels();
    return allModels.where((m) => m.type == type).toList();
  }

  /// Check if a model is already downloaded
  static Future<bool> isModelDownloaded(String modelId) async {
    try {
      final result = await _channel.invokeMethod('isModelDownloaded', {
        'modelId': modelId,
      });
      return result as bool;
    } on PlatformException catch (e) {
      throw Exception('Failed to check model download status: ${e.message}');
    }
  }

  /// Get the local file path for a downloaded model
  /// Returns null if model is not downloaded
  static Future<String?> getModelPath(String modelId) async {
    try {
      final result = await _channel.invokeMethod('getModelPath', {
        'modelId': modelId,
      });
      return result as String?;
    } on PlatformException catch (e) {
      throw Exception('Failed to get model path: ${e.message}');
    }
  }

  /// Download a model with progress tracking
  /// Returns a stream of download progress
  Stream<DownloadProgress> downloadModel(String modelId) {
    return _progressChannel.receiveBroadcastStream({
      'modelId': modelId,
    }).map((event) {
      final map = event as Map<dynamic, dynamic>;
      return DownloadProgress.fromMap(Map<String, dynamic>.from(map));
    });
  }

  /// Cancel an ongoing download
  static Future<void> cancelDownload(String modelId) async {
    try {
      await _channel.invokeMethod('cancelDownload', {
        'modelId': modelId,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to cancel download: ${e.message}');
    }
  }

  /// Delete a downloaded model to free up space
  static Future<void> deleteModel(String modelId) async {
    try {
      await _channel.invokeMethod('deleteModel', {
        'modelId': modelId,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to delete model: ${e.message}');
    }
  }

  /// Get storage information
  static Future<StorageInfo> getStorageInfo() async {
    try {
      final result = await _channel.invokeMethod('getStorageInfo');
      return StorageInfo.fromMap(Map<String, dynamic>.from(result as Map));
    } on PlatformException catch (e) {
      throw Exception('Failed to get storage info: ${e.message}');
    }
  }

  /// Get the directory where models are stored
  static Future<String> getModelsDirectory() async {
    try {
      final result = await _channel.invokeMethod('getModelsDirectory');
      return result as String;
    } on PlatformException catch (e) {
      throw Exception('Failed to get models directory: ${e.message}');
    }
  }

  /// Clean up incomplete or corrupted downloads
  static Future<void> cleanupIncompleteDownloads() async {
    try {
      await _channel.invokeMethod('cleanupIncompleteDownloads');
    } on PlatformException catch (e) {
      throw Exception('Failed to cleanup downloads: ${e.message}');
    }
  }

  /// Get list of all downloaded models
  static Future<List<String>> getDownloadedModels() async {
    try {
      final result = await _channel.invokeMethod('getDownloadedModels');
      return (result as List<dynamic>).cast<String>();
    } on PlatformException catch (e) {
      throw Exception('Failed to get downloaded models: ${e.message}');
    }
  }

  /// Get device information including chipset, NPU/GPU/CPU support, and performance level
  static Future<DeviceInfo> getDeviceInfo() async {
    try {
      final result = await _channel.invokeMethod('getDeviceInfo');
      return DeviceInfo.fromMap(Map<String, dynamic>.from(result as Map));
    } on PlatformException catch (e) {
      throw Exception('Failed to get device info: ${e.message}');
    }
  }

  /// Check if a model is compatible with the current device
  /// Returns compatibility information including expected performance
  static Future<ModelCompatibility> checkModelCompatibility(
      String modelId) async {
    try {
      final result = await _channel.invokeMethod('checkModelCompatibility', {
        'modelId': modelId,
      });
      return ModelCompatibility.fromMap(Map<String, dynamic>.from(result as Map));
    } on PlatformException catch (e) {
      throw Exception('Failed to check model compatibility: ${e.message}');
    }
  }
}

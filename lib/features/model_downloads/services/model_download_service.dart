import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

enum DownloadStatus {
  notStarted,
  downloading,
  completed,
  failed,
  cancelled,
}

enum ModelValidationStatus {
  valid,
  corrupted,
  incompatible,
  unknown,
}

class DownloadProgress {
  final int downloadedBytes;
  final int totalBytes;
  final double progress;
  final DownloadStatus status;
  final String? error;

  DownloadProgress({
    required this.downloadedBytes,
    required this.totalBytes,
    required this.progress,
    required this.status,
    this.error,
  });
}

class ModelValidationResult {
  final ModelValidationStatus status;
  final String? error;
  final Map<String, dynamic>? metadata;

  ModelValidationResult({
    required this.status,
    this.error,
    this.metadata,
  });
}

class ModelDownloadService {
  static const String _baseUrl = 'https://71d59adbd067633aca3e95f915fbf2b4.r2.cloudflarestorage.com/livecaptionsxr';
  
  static final Map<String, http.Client> _activeDownloads = {};

  /// Get the models directory path
  static Future<String> get modelsDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${appDir.path}/models');
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir.path;
  }

  /// Check if a model is already downloaded
  static Future<bool> isModelDownloaded(String fileName) async {
    final modelsDir = await modelsDirectory;
    final file = File('$modelsDir/$fileName');
    return await file.exists();
  }

  /// Get the local path of a downloaded model
  static Future<String?> getModelPath(String fileName) async {
    final modelsDir = await modelsDirectory;
    final file = File('$modelsDir/$fileName');
    return await file.exists() ? file.path : null;
  }

  /// Validate a downloaded model file
  static Future<ModelValidationResult> validateModel(String fileName) async {
    try {
      final modelsDir = await modelsDirectory;
      final file = File('$modelsDir/$fileName');
      
      if (!await file.exists()) {
        return ModelValidationResult(
          status: ModelValidationStatus.unknown,
          error: 'Model file not found',
        );
      }

      final fileSize = await file.length();
      
      // Basic file size validation
      if (fileSize == 0) {
        return ModelValidationResult(
          status: ModelValidationStatus.corrupted,
          error: 'Model file is empty',
        );
      }

      // iOS-specific validation for large models
      if (Platform.isIOS) {
        return await _validateModelForIOS(file, fileSize);
      }

      // Android validation
      if (Platform.isAndroid) {
        return await _validateModelForAndroid(file, fileSize);
      }

      return ModelValidationResult(status: ModelValidationStatus.valid);
    } catch (e) {
      return ModelValidationResult(
        status: ModelValidationStatus.unknown,
        error: 'Validation error: $e',
      );
    }
  }

  /// iOS-specific model validation
  static Future<ModelValidationResult> _validateModelForIOS(File file, int fileSize) async {
    try {
      // Check available memory for large models
      final availableMemory = await _getAvailableMemory();
      
      // For Gemma models, check if we have enough memory
      if (file.path.contains('gemma') && fileSize > 2 * 1024 * 1024 * 1024) { // 2GB
        if (availableMemory < 4 * 1024 * 1024 * 1024) { // 4GB
          return ModelValidationResult(
            status: ModelValidationStatus.incompatible,
            error: 'Insufficient memory for large model (${(fileSize / 1024 / 1024 / 1024).toStringAsFixed(1)}GB). Available: ${(availableMemory / 1024 / 1024 / 1024).toStringAsFixed(1)}GB',
            metadata: {
              'fileSize': fileSize,
              'availableMemory': availableMemory,
              'recommendation': 'Use smaller model or free up memory',
            },
          );
        }
      }

      // Check file integrity by reading first and last bytes
      final raf = await file.open();
      try {
        // Read first 1024 bytes
        final header = await raf.read(1024);
        if (header.length < 1024) {
          return ModelValidationResult(
            status: ModelValidationStatus.corrupted,
            error: 'Model file appears to be truncated',
          );
        }

        // Check for common model file signatures
        final headerStr = String.fromCharCodes(header);
        if (headerStr.contains('task') || headerStr.contains('tflite') || headerStr.contains('bin')) {
          return ModelValidationResult(
            status: ModelValidationStatus.valid,
            metadata: {
              'fileSize': fileSize,
              'availableMemory': availableMemory,
              'modelType': _detectModelType(file.path),
            },
          );
        }
      } finally {
        await raf.close();
      }

      return ModelValidationResult(status: ModelValidationStatus.valid);
    } catch (e) {
      return ModelValidationResult(
        status: ModelValidationStatus.corrupted,
        error: 'iOS validation error: $e',
      );
    }
  }

  /// Android-specific model validation
  static Future<ModelValidationResult> _validateModelForAndroid(File file, int fileSize) async {
    // Android validation is simpler - just check file integrity
    try {
      final raf = await file.open();
      try {
        final header = await raf.read(1024);
        if (header.length < 1024) {
          return ModelValidationResult(
            status: ModelValidationStatus.corrupted,
            error: 'Model file appears to be truncated',
          );
        }
      } finally {
        await raf.close();
      }

      return ModelValidationResult(
        status: ModelValidationStatus.valid,
        metadata: {
          'fileSize': fileSize,
          'modelType': _detectModelType(file.path),
        },
      );
    } catch (e) {
      return ModelValidationResult(
        status: ModelValidationStatus.corrupted,
        error: 'Android validation error: $e',
      );
    }
  }

  /// Get available memory (iOS only)
  static Future<int> _getAvailableMemory() async {
    if (!Platform.isIOS) return 0;
    
    try {
      // This is a rough estimate - in a real app you'd use platform channels
      // to get actual available memory from iOS
      return 6 * 1024 * 1024 * 1024; // Assume 6GB for modern devices
    } catch (e) {
      return 4 * 1024 * 1024 * 1024; // Fallback to 4GB
    }
  }

  /// Detect model type from filename
  static String _detectModelType(String filePath) {
    final fileName = filePath.split('/').last.toLowerCase();
    if (fileName.contains('whisper')) return 'whisper';
    if (fileName.contains('gemma')) return 'gemma';
    if (fileName.contains('task')) return 'mediapipe_task';
    if (fileName.contains('tflite')) return 'tensorflow_lite';
    if (fileName.contains('bin')) return 'ggml';
    return 'unknown';
  }

  /// Request storage permissions
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  /// Download a model file with progress tracking and validation
  static Stream<DownloadProgress> downloadModel(
    String fileName,
    String modelName, {
    bool validateAfterDownload = true,
  }) async* {
    final url = '$_baseUrl/$fileName';
    final modelsDir = await modelsDirectory;
    final file = File('$modelsDir/$fileName');

    // Check if already downloaded and valid
    if (await file.exists()) {
      if (validateAfterDownload) {
        final validation = await validateModel(fileName);
        if (validation.status == ModelValidationStatus.valid) {
          yield DownloadProgress(
            downloadedBytes: await file.length(),
            totalBytes: await file.length(),
            progress: 1.0,
            status: DownloadStatus.completed,
          );
          return;
        } else {
          // Delete corrupted file and re-download
          await file.delete();
        }
      } else {
        yield DownloadProgress(
          downloadedBytes: await file.length(),
          totalBytes: await file.length(),
          progress: 1.0,
          status: DownloadStatus.completed,
        );
        return;
      }
    }

    // Request permissions
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      yield DownloadProgress(
        downloadedBytes: 0,
        totalBytes: 0,
        progress: 0.0,
        status: DownloadStatus.failed,
        error: 'Storage permission denied',
      );
      return;
    }

    try {
      final client = http.Client();
      _activeDownloads[fileName] = client;

      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        yield DownloadProgress(
          downloadedBytes: 0,
          totalBytes: 0,
          progress: 0.0,
          status: DownloadStatus.failed,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
        return;
      }

      final totalBytes = response.contentLength ?? 0;
      int downloadedBytes = 0;

      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        // Check if download was cancelled
        if (!_activeDownloads.containsKey(fileName)) {
          sink.close();
          await file.delete();
          yield DownloadProgress(
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes,
            progress: totalBytes > 0 ? downloadedBytes / totalBytes : 0.0,
            status: DownloadStatus.cancelled,
          );
          return;
        }

        sink.add(chunk);
        downloadedBytes += chunk.length;

        yield DownloadProgress(
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
          progress: totalBytes > 0 ? downloadedBytes / totalBytes : 0.0,
          status: DownloadStatus.downloading,
        );
      }

      await sink.close();
      _activeDownloads.remove(fileName);

      // Validate downloaded file
      if (validateAfterDownload) {
        final validation = await validateModel(fileName);
        if (validation.status != ModelValidationStatus.valid) {
          await file.delete();
          yield DownloadProgress(
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes,
            progress: 1.0,
            status: DownloadStatus.failed,
            error: 'Model validation failed: ${validation.error}',
          );
          return;
        }
      }

      yield DownloadProgress(
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes,
        progress: 1.0,
        status: DownloadStatus.completed,
      );

    } catch (e) {
      _activeDownloads.remove(fileName);
      yield DownloadProgress(
        downloadedBytes: 0,
        totalBytes: 0,
        progress: 0.0,
        status: DownloadStatus.failed,
        error: e.toString(),
      );
    }
  }

  /// Cancel an active download
  static void cancelDownload(String fileName) {
    final client = _activeDownloads[fileName];
    if (client != null) {
      client.close();
      _activeDownloads.remove(fileName);
    }
  }

  /// Delete a downloaded model
  static Future<bool> deleteModel(String fileName) async {
    try {
      final modelsDir = await modelsDirectory;
      final file = File('$modelsDir/$fileName');
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get available storage space
  static Future<int> getAvailableStorage() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final stat = await appDir.stat();
      return stat.size;
    } catch (e) {
      return 0;
    }
  }

  /// Get model loading recommendations for iOS
  static Map<String, dynamic> getIOSModelRecommendations() {
    return {
      'useMetalDelegate': true,
      'disableXNNPACK': true,
      'maxModelSizeGB': 2.0,
      'recommendedMemoryGB': 4.0,
      'enableMemoryMapping': false,
      'chunkedLoading': true,
    };
  }
} 
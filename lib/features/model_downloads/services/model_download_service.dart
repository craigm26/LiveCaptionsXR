import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

enum DownloadStatus {
  notStarted,
  downloading,
  completed,
  failed,
  cancelled,
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

  /// Request storage permissions
  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true;
  }

  /// Download a model file with progress tracking
  static Stream<DownloadProgress> downloadModel(
    String fileName,
    String modelName,
  ) async* {
    final url = '$_baseUrl/$fileName';
    final modelsDir = await modelsDirectory;
    final file = File('$modelsDir/$fileName');

    // Check if already downloaded
    if (await file.exists()) {
      yield DownloadProgress(
        downloadedBytes: await file.length(),
        totalBytes: await file.length(),
        progress: 1.0,
        status: DownloadStatus.completed,
      );
      return;
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
} 
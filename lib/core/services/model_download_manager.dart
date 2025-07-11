import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

class ModelDownloadManager extends ChangeNotifier {
  static const String modelFileName = 'gemma-3n-E4B-it-int4.task';
  // old development url: static const String modelUrl = 'https://pub-fdd38fc88d79463bb05e10b5ce7b5f2e.r2.dev/gemma-3n-E4B-it-int4.task';
  static const String modelUrl = 'https://livecaptionsxrbucket.com/gemma-3n-E4B-it-int4.task';
  static const int expectedModelFileSize = 4398046511; // 4.1 GB in bytes (update to exact size if needed)

  double _progress = 0.0;
  String? _error;
  bool _downloading = false;
  bool _completed = false;

  double get progress => _progress;
  String? get error => _error;
  bool get downloading => _downloading;
  bool get completed => _completed;

  Future<String> getModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$modelFileName';
  }

  Future<bool> modelExists() async {
    final path = await getModelPath();
    return File(path).existsSync();
  }

  /// Returns true if the model file exists and is the expected size (not partial)
  Future<bool> modelIsComplete() async {
    final path = await getModelPath();
    final file = File(path);
    if (await file.exists()) {
      final stat = await file.stat();
      return stat.size >= expectedModelFileSize;
    }
    return false;
  }

  Future<void> downloadModel() async {
    _downloading = true;
    _completed = false;
    _error = null;
    _progress = 0.0;
    notifyListeners();
    try {
      final path = await getModelPath();
      final file = File(path);
      final request = http.Request('GET', Uri.parse(modelUrl));
      final response = await request.send();
      if (response.statusCode != 200) {
        throw Exception('Failed to download model:  ${response.statusCode}');
      }
      final contentLength = response.contentLength ?? 0;
      int bytesReceived = 0;
      final sink = file.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        bytesReceived += chunk.length;
        if (contentLength > 0) {
          _progress = bytesReceived / contentLength;
          notifyListeners();
        }
      }
      await sink.close();
      _progress = 1.0;
      _completed = true;
      _downloading = false;
      notifyListeners();
      // Set the model path in flutter_gemma after successful download
      final gemma = FlutterGemmaPlugin.instance;
      final modelManager = gemma.modelManager;
      await modelManager.setModelPath(path);
    } catch (e) {
      _error = e.toString();
      _downloading = false;
      _completed = false;
      notifyListeners();
    }
  }

  void reset() {
    _progress = 0.0;
    _error = null;
    _downloading = false;
    _completed = false;
    notifyListeners();
  }
}
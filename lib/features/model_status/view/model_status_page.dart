import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/model_download_manager.dart';
import 'dart:io';

class ModelStatusPage extends StatefulWidget {
  const ModelStatusPage({super.key});

  @override
  State<ModelStatusPage> createState() => _ModelStatusPageState();
}

class _ModelStatusPageState extends State<ModelStatusPage> {
  late ModelDownloadManager _modelDownloadManager;
  File? _modelFile;
  int? _fileSize;
  DateTime? _lastModified;
  bool _isPartial = false;

  @override
  void initState() {
    super.initState();
    _modelDownloadManager = ModelDownloadManager();
    _loadModelFileInfo();
  }

  Future<void> _loadModelFileInfo() async {
    final path = await _modelDownloadManager.getModelPath();
    final file = File(path);
    if (await file.exists()) {
      final stat = await file.stat();
      final isComplete = await _modelDownloadManager.modelIsComplete();
      setState(() {
        _modelFile = file;
        _fileSize = stat.size;
        _lastModified = stat.modified;
        _isPartial = !isComplete;
      });
    } else {
      setState(() {
        _modelFile = null;
        _fileSize = null;
        _lastModified = null;
        _isPartial = false;
      });
    }
  }

  String _formatBytes(int? bytes) {
    if (bytes == null) return '-';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ModelDownloadManager>.value(
      value: _modelDownloadManager,
      child: Consumer<ModelDownloadManager>(
        builder: (context, manager, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Model File Status'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _modelFile != null ? Icons.check_circle : Icons.error,
                        color: _modelFile != null ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _modelFile != null ? 'Model file is present' : 'Model file not found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _modelFile != null ? Colors.green : Colors.red,
                        ),
                      ),
                      if (_isPartial && _modelFile != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.warning, color: Colors.orange, size: 28),
                      ],
                    ],
                  ),
                  if (_isPartial && _modelFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                      child: Row(
                        children: const [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Warning: Model file appears to be incomplete. Please re-download to ensure full functionality.',
                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text('File path:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_modelFile?.path ?? '-'),
                  const SizedBox(height: 12),
                  Text('File size:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_formatBytes(_fileSize)),
                  const SizedBox(height: 12),
                  Text('Last modified:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_lastModified?.toString() ?? '-'),
                  const SizedBox(height: 24),
                  if (manager.downloading)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(value: manager.progress),
                        const SizedBox(height: 8),
                        Text('Downloading: ${(manager.progress * 100).toStringAsFixed(1)}%'),
                      ],
                    )
                  else if (manager.error != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Error: ${manager.error}', style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            manager.reset();
                            manager.downloadModel().then((_) => _loadModelFileInfo());
                          },
                          child: const Text('Retry Download'),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: manager.downloading
                              ? null
                              : () async {
                                  await manager.downloadModel();
                                  _loadModelFileInfo();
                                },
                          icon: const Icon(Icons.download),
                          label: const Text('Re-download Model'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _loadModelFileInfo();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Status'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 
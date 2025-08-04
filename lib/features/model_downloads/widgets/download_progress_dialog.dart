import 'package:flutter/material.dart';
import '../services/model_download_service.dart';

class DownloadProgressDialog extends StatelessWidget {
  final String modelName;
  final DownloadProgress progress;
  final VoidCallback onCancel;

  const DownloadProgressDialog({
    super.key,
    required this.modelName,
    required this.progress,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Downloading $modelName'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: progress.progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress:'),
              Text('${(progress.progress * 100).toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Downloaded:'),
              Text(_formatBytes(progress.downloadedBytes)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total:'),
              Text(_formatBytes(progress.totalBytes)),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '$bytes B';
    }
  }
} 
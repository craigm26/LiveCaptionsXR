import 'package:flutter/material.dart';
import '../models/model_info.dart';
import '../services/model_download_service.dart';

class ModelCard extends StatelessWidget {
  final ModelInfo model;
  final bool isDownloaded;
  final bool isDownloading;
  final DownloadProgress? progress;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const ModelCard({
    super.key,
    required this.model,
    required this.isDownloaded,
    required this.isDownloading,
    this.progress,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and recommended badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    model.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (model.isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Recommended',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Description
            Text(
              model.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Size and version info
            Row(
              children: [
                Icon(Icons.storage, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  model.sizeDisplay,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'v${model.version}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Download progress or status
            if (isDownloading && progress != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Downloading...',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(progress!.progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress!.progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatBytes(progress!.downloadedBytes)} / ${_formatBytes(progress!.totalBytes)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ] else if (isDownloaded) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Downloaded',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                if (isDownloading) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.stop),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ] else if (isDownloaded) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                    ),
                  ),
                ],
                
                const SizedBox(width: 12),
                
                // Open in browser button
                OutlinedButton.icon(
                  onPressed: () => _openInBrowser(model.downloadUrl),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open'),
                ),
              ],
            ),
          ],
        ),
      ),
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

  void _openInBrowser(String url) {
    // This would typically use url_launcher package
    // For now, just print the URL
    print('Opening URL: $url');
  }
} 
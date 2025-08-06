class ModelInfo {
  final String name;
  final String description;
  final String fileName;
  final String downloadUrl;
  final int sizeInBytes;
  final String sizeDisplay;
  final String version;
  final bool isRecommended;
  final String? termsNotice;

  const ModelInfo({
    required this.name,
    required this.description,
    required this.fileName,
    required this.downloadUrl,
    required this.sizeInBytes,
    required this.sizeDisplay,
    required this.version,
    this.isRecommended = false,
    this.termsNotice,
  });

  String get formattedSize {
    if (sizeInBytes >= 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (sizeInBytes >= 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (sizeInBytes >= 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '$sizeInBytes B';
    }
  }
} 
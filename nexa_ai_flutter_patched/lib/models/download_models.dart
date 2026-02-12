class ModelFile {
  final String name;
  final String path;
  final String url;

  ModelFile({
    required this.name,
    required this.path,
    required this.url,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'path': path,
      'url': url,
    };
  }

  factory ModelFile.fromMap(Map<String, dynamic> map) {
    return ModelFile(
      name: map['name'] as String,
      path: map['path'] as String,
      url: map['url'] as String,
    );
  }
}

class ModelInfo {
  final String id;
  final String displayName;
  final String modelName;
  final String mmprojOrTokenName;
  final double sizeGb;
  final String params;
  final List<String> features;
  final String type;
  final int versionCode;
  final String? modelUrl;
  final String? mmprojOrTokenUrl;
  final List<ModelFile> files;

  ModelInfo({
    required this.id,
    required this.displayName,
    required this.modelName,
    required this.mmprojOrTokenName,
    required this.sizeGb,
    required this.params,
    required this.features,
    required this.type,
    required this.versionCode,
    this.modelUrl,
    this.mmprojOrTokenUrl,
    required this.files,
  });

  factory ModelInfo.fromMap(Map<String, dynamic> map) {
    return ModelInfo(
      id: map['id'] as String,
      displayName: map['displayName'] as String,
      modelName: map['modelName'] as String,
      mmprojOrTokenName: map['mmprojOrTokenName'] as String? ?? '',
      sizeGb: (map['sizeGb'] as num).toDouble(),
      params: map['params'] as String,
      features: (map['features'] as List<dynamic>).cast<String>(),
      type: map['type'] as String,
      versionCode: map['versionCode'] as int? ?? 0,
      modelUrl: map['modelUrl'] as String?,
      mmprojOrTokenUrl: map['mmprojOrTokenUrl'] as String?,
      files: (map['files'] as List<dynamic>?)
              ?.map((f) => ModelFile.fromMap(Map<String, dynamic>.from(f as Map)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'modelName': modelName,
      'mmprojOrTokenName': mmprojOrTokenName,
      'sizeGb': sizeGb,
      'params': params,
      'features': features,
      'type': type,
      'versionCode': versionCode,
      if (modelUrl != null) 'modelUrl': modelUrl,
      if (mmprojOrTokenUrl != null) 'mmprojOrTokenUrl': mmprojOrTokenUrl,
      'files': files.map((f) => f.toMap()).toList(),
    };
  }
}

class DownloadProgress {
  final String modelId;
  final int downloadedBytes;
  final int totalBytes;
  final int percentage;
  final double speedMBps;
  final DownloadStatus status;

  DownloadProgress({
    required this.modelId,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.percentage,
    required this.speedMBps,
    required this.status,
  });

  factory DownloadProgress.fromMap(Map<String, dynamic> map) {
    return DownloadProgress(
      modelId: map['modelId'] as String,
      downloadedBytes: map['downloadedBytes'] as int,
      totalBytes: map['totalBytes'] as int,
      percentage: map['percentage'] as int,
      speedMBps: (map['speedMBps'] as num).toDouble(),
      status: DownloadStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => DownloadStatus.downloading,
      ),
    );
  }
}

enum DownloadStatus {
  downloading,
  completed,
  failed,
  cancelled,
}

class StorageInfo {
  final int totalSpace;
  final int freeSpace;
  final int usedByModels;
  final List<String> downloadedModels;

  StorageInfo({
    required this.totalSpace,
    required this.freeSpace,
    required this.usedByModels,
    required this.downloadedModels,
  });

  factory StorageInfo.fromMap(Map<String, dynamic> map) {
    return StorageInfo(
      totalSpace: map['totalSpace'] as int,
      freeSpace: map['freeSpace'] as int,
      usedByModels: map['usedByModels'] as int,
      downloadedModels: (map['downloadedModels'] as List<dynamic>).cast<String>(),
    );
  }

  double get totalSpaceGB => totalSpace / (1024 * 1024 * 1024);
  double get freeSpaceGB => freeSpace / (1024 * 1024 * 1024);
  double get usedByModelsGB => usedByModels / (1024 * 1024 * 1024);
}

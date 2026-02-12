import 'model_config.dart';

class RerankerCreateInput {
  final String? modelName; // Required for NPU
  final String modelPath;
  final String? tokenizerPath;
  final ModelConfig config;
  final String? pluginId; // "npu" or null (CPU)
  final String? deviceId;

  RerankerCreateInput({
    this.modelName,
    required this.modelPath,
    this.tokenizerPath,
    required this.config,
    this.pluginId,
    this.deviceId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (modelName != null) 'modelName': modelName,
      'modelPath': modelPath,
      if (tokenizerPath != null) 'tokenizerPath': tokenizerPath,
      'config': config.toMap(),
      if (pluginId != null) 'pluginId': pluginId,
      if (deviceId != null) 'deviceId': deviceId,
    };
  }
}

class RerankConfig {
  final int? topN; // Return only top N results (null = all)

  RerankConfig({this.topN});

  Map<String, dynamic> toMap() {
    return {
      if (topN != null) 'topN': topN,
    };
  }
}

class RerankerResult {
  final List<double> scores; // Relevance scores (0.0 - 1.0)
  final int scoreCount;
  final String profileData;

  RerankerResult(this.scores, this.scoreCount, this.profileData);

  factory RerankerResult.fromMap(Map<String, dynamic> map) {
    return RerankerResult(
      (map['scores'] as List<dynamic>).cast<double>(),
      map['scoreCount'] as int,
      map['profileData'] as String,
    );
  }
}

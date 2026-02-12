import 'model_config.dart';

class EmbedderCreateInput {
  final String? modelName; // Required for NPU
  final String modelPath;
  final String? tokenizerPath;
  final ModelConfig config;
  final String? pluginId; // "npu" or null (CPU)
  final String? deviceId;

  EmbedderCreateInput({
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

class EmbeddingConfig {
  final bool normalize;

  EmbeddingConfig({this.normalize = true});

  Map<String, dynamic> toMap() {
    return {
      'normalize': normalize,
    };
  }
}

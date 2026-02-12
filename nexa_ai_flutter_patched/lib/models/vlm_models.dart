import 'model_config.dart';

class VlmCreateInput {
  final String? modelName; // Required for NPU
  final String modelPath;
  final String? tokenizerPath;
  final String? mmprojPath; // Vision projection weights (for GGUF models)
  final ModelConfig config;
  final String? pluginId; // "npu", "cpu_gpu", or null

  VlmCreateInput({
    this.modelName,
    required this.modelPath,
    this.tokenizerPath,
    this.mmprojPath,
    required this.config,
    this.pluginId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (modelName != null) 'modelName': modelName,
      'modelPath': modelPath,
      if (tokenizerPath != null) 'tokenizerPath': tokenizerPath,
      if (mmprojPath != null) 'mmprojPath': mmprojPath,
      'config': config.toMap(),
      if (pluginId != null) 'pluginId': pluginId,
    };
  }
}

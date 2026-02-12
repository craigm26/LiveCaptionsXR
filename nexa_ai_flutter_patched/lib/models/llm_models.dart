import 'model_config.dart';

class LlmCreateInput {
  final String? modelName; // Required for NPU
  final String modelPath;
  final String? tokenizerPath;
  final ModelConfig config;
  final String? pluginId; // "npu", "cpu_gpu", or null (defaults to CPU)

  LlmCreateInput({
    this.modelName,
    required this.modelPath,
    this.tokenizerPath,
    required this.config,
    this.pluginId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (modelName != null) 'modelName': modelName,
      'modelPath': modelPath,
      if (tokenizerPath != null) 'tokenizerPath': tokenizerPath,
      'config': config.toMap(),
      if (pluginId != null) 'pluginId': pluginId,
    };
  }
}

class GenerationProfile {
  final double ttftMs; // Time to first token in milliseconds
  final double decodingSpeed; // Tokens per second

  GenerationProfile(this.ttftMs, this.decodingSpeed);

  factory GenerationProfile.fromMap(Map<String, dynamic> map) {
    return GenerationProfile(
      (map['ttftMs'] as num).toDouble(),
      (map['decodingSpeed'] as num).toDouble(),
    );
  }
}

abstract class LlmStreamResult {}

class LlmStreamToken extends LlmStreamResult {
  final String text;

  LlmStreamToken(this.text);
}

class LlmStreamCompleted extends LlmStreamResult {
  final GenerationProfile profile;

  LlmStreamCompleted(this.profile);
}

class LlmStreamError extends LlmStreamResult {
  final String message;

  LlmStreamError(this.message);
}

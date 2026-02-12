import 'model_config.dart';

class AsrCreateInput {
  final String? modelName; // Required for NPU
  final String modelPath;
  final ModelConfig config;
  final String? pluginId; // "npu" or null (CPU)

  AsrCreateInput({
    this.modelName,
    required this.modelPath,
    required this.config,
    this.pluginId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (modelName != null) 'modelName': modelName,
      'modelPath': modelPath,
      'config': config.toMap(),
      if (pluginId != null) 'pluginId': pluginId,
    };
  }
}

class AsrTranscribeInput {
  final String audioPath; // Path to audio file (.wav, .mp3, etc.)
  final String language; // Language code: "en", "zh", "es", etc.
  final String? timestamps; // Optional timestamp format

  AsrTranscribeInput({
    required this.audioPath,
    required this.language,
    this.timestamps,
  });

  Map<String, dynamic> toMap() {
    return {
      'audioPath': audioPath,
      'language': language,
      if (timestamps != null) 'timestamps': timestamps,
    };
  }
}

class AsrResult {
  final String transcript;

  AsrResult(this.transcript);

  factory AsrResult.fromMap(Map<String, dynamic> map) {
    return AsrResult(map['transcript'] as String);
  }
}

class AsrTranscriptionResult {
  final AsrResult result;
  final String profileData;

  AsrTranscriptionResult(this.result, this.profileData);

  factory AsrTranscriptionResult.fromMap(Map<String, dynamic> map) {
    return AsrTranscriptionResult(
      AsrResult.fromMap(map['result'] as Map<String, dynamic>),
      map['profileData'] as String,
    );
  }
}

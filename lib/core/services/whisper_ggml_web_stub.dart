// Web stub for whisper_ggml - provides empty implementations for web builds

/// Stub Whisper class for web builds
class Whisper {
  Whisper({
    required WhisperModel model,
    required String modelDir,
  });
  
  Future<void> loadModel({
    required WhisperModel model,
    required String modelDir,
  }) async {
    throw UnsupportedError('Whisper not available on web platform');
  }
  
  String getVersion() => 'web-stub';
  
  Future<TranscribeResult> transcribe({
    required TranscribeRequest transcribeRequest,
    required String modelPath,
  }) async {
    throw UnsupportedError('Whisper not available on web platform');
  }
  
  void dispose() {}
}

/// Stub TranscribeRequest class
class TranscribeRequest {
  final String audio;
  final String? language;
  final bool isTranslate;
  final bool isSpecialTokens;
  final int threads;
  final bool isVerbose;
  final bool isNoTimestamps;
  
  TranscribeRequest({
    required this.audio,
    this.language,
    this.isTranslate = false,
    this.isSpecialTokens = false,
    this.threads = 4,
    this.isVerbose = false,
    this.isNoTimestamps = true,
  });
}

/// Stub TranscribeResult class
class TranscribeResult {
  final String text;
  final double confidence;
  
  TranscribeResult({
    required this.text,
    this.confidence = 0.0,
  });
}

/// Stub WhisperModel enum
enum WhisperModel {
  tiny,
  base,
  small,
  medium,
  large,
} 
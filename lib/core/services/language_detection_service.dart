import 'dart:async';
import 'dart:math' as math;

import '../models/speech_config.dart';
import 'app_logger.dart';

/// Language detection result
class LanguageDetectionResult {
  final String detectedLanguage;
  final double confidence;
  final Map<String, double> languageScores;

  const LanguageDetectionResult({
    required this.detectedLanguage,
    required this.confidence,
    required this.languageScores,
  });

  @override
  String toString() => 'LanguageDetectionResult(lang: $detectedLanguage, confidence: $confidence)';
}

/// Service for detecting language from speech audio using Gemma 3
class LanguageDetectionService {
  
  static final AppLogger _logger = AppLogger.instance;

  /// Detect language from audio buffer
  static Future<LanguageDetectionResult?> detectLanguage(
    List<double> audioBuffer,
    SpeechConfig config,
  ) async {
    if (!config.enableLanguageDetection) {
      return LanguageDetectionResult(
        detectedLanguage: config.language,
        confidence: 1.0,
        languageScores: {config.language: 1.0},
      );
    }

    try {
      _logger.d('🌍 Detecting language from audio buffer (${audioBuffer.length} samples)');

      // Create a prompt for language detection using Gemma 3
      final prompt = '''
You are a language detection AI. Analyze the following audio characteristics and determine the most likely language being spoken.

Audio buffer information:
- Sample count: ${audioBuffer.length}
- Audio features: ${_extractAudioFeatures(audioBuffer)}

Supported languages: ${config.supportedLanguages.join(', ')}

Please respond with ONLY a JSON object in this exact format:
{
  "language": "language_code",
  "confidence": 0.95,
  "scores": {
    "en": 0.95,
    "es": 0.03,
    "fr": 0.02
  }
}

Use ISO 639-1 language codes.
''';

      // TODO: Integrate with flutter_gemma for language detection when available
      // final result = await _channel.invokeMethod('generateText', {
      //   'prompt': prompt,
      //   'maxTokens': 200,
      //   'temperature': 0.1, // Low temperature for consistent format
      // });

      // if (result['success'] == true && result['text'] != null) {
      //   final response = result['text'] as String;
      //   return _parseLanguageDetectionResponse(response, config);
      // }
    } catch (e, stackTrace) {
      _logger.e('❌ Error detecting language', error: e, stackTrace: stackTrace);
    }

    // Fallback to default language
    return LanguageDetectionResult(
      detectedLanguage: config.language,
      confidence: 0.5,
      languageScores: {config.language: 0.5},
    );
  }

  /// Detect language from text using linguistic patterns
  static Future<LanguageDetectionResult?> detectLanguageFromText(
    String text,
    SpeechConfig config,
  ) async {
    if (!config.enableLanguageDetection || text.trim().isEmpty) {
      return LanguageDetectionResult(
        detectedLanguage: config.language,
        confidence: 1.0,
        languageScores: {config.language: 1.0},
      );
    }

    try {
      _logger.d('🔤 Detecting language from text: "${text.substring(0, text.length.clamp(0, 50))}..."');

      // Create a prompt for language detection using Gemma 3
      final prompt = '''
You are a language detection AI. Analyze the following text and determine which language it is written in.

Text to analyze: "$text"

Supported languages: ${config.supportedLanguages.join(', ')}

Please respond with ONLY a JSON object in this exact format:
{
  "language": "language_code",
  "confidence": 0.95,
  "scores": {
    "en": 0.95,
    "es": 0.03,
    "fr": 0.02
  }
}

Use ISO 639-1 language codes. Base your analysis on:
1. Character patterns and alphabet
2. Common words and phrases
3. Grammar structure
4. Language-specific features
''';

      // TODO: Integrate with flutter_gemma for language detection when available
      // final result = await _channel.invokeMethod('generateText', {
      //   'prompt': prompt,
      //   'maxTokens': 200,
      //   'temperature': 0.1,
      // });

      // if (result['success'] == true && result['text'] != null) {
      //   final response = result['text'] as String;
      //   return _parseLanguageDetectionResponse(response, config);
      // }
    } catch (e, stackTrace) {
      _logger.e('❌ Error detecting language from text', error: e, stackTrace: stackTrace);
    }

    // Fallback to default language
    return LanguageDetectionResult(
      detectedLanguage: config.language,
      confidence: 0.5,
      languageScores: {config.language: 0.5},
    );
  }

  /// Extract basic audio features for language detection
  static String _extractAudioFeatures(List<double> audioBuffer) {
    if (audioBuffer.isEmpty) return 'silent';

    // Calculate basic audio statistics
    final mean = audioBuffer.reduce((a, b) => a + b) / audioBuffer.length;
    final variance = audioBuffer.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / audioBuffer.length;
    final stdDev = variance > 0 ? math.sqrt(variance) : 0.0;
    
    // Find peak amplitude
    final maxAmplitude = audioBuffer.map((x) => x.abs()).reduce((a, b) => a > b ? a : b);
    
    // Calculate zero crossing rate (approximation)
    int zeroCrossings = 0;
    for (int i = 1; i < audioBuffer.length; i++) {
      if ((audioBuffer[i] >= 0) != (audioBuffer[i - 1] >= 0)) {
        zeroCrossings++;
      }
    }
    final zcr = zeroCrossings / audioBuffer.length;

    return 'mean: ${mean.toStringAsFixed(4)}, stdDev: ${stdDev.toStringAsFixed(4)}, '
           'maxAmp: ${maxAmplitude.toStringAsFixed(4)}, zcr: ${zcr.toStringAsFixed(4)}';
  }
}




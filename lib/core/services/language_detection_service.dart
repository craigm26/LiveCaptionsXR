import 'dart:async';
import 'package:flutter/services.dart';

import '../models/speech_config.dart';
import 'debug_capturing_logger.dart';

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
  static const _channel = MethodChannel('gemma3n_multimodal');
  static final DebugCapturingLogger _logger = DebugCapturingLogger();

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

      final result = await _channel.invokeMethod('generateText', {
        'prompt': prompt,
        'maxTokens': 200,
        'temperature': 0.1, // Low temperature for consistent format
      });

      if (result['success'] == true && result['text'] != null) {
        final response = result['text'] as String;
        return _parseLanguageDetectionResponse(response, config);
      }
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

      final result = await _channel.invokeMethod('generateText', {
        'prompt': prompt,
        'maxTokens': 200,
        'temperature': 0.1,
      });

      if (result['success'] == true && result['text'] != null) {
        final response = result['text'] as String;
        return _parseLanguageDetectionResponse(response, config);
      }
    } catch (e, stackTrace) {
      _logger.e('❌ Error detecting language from text', error: e, stackTrace: stackTrace);
    }

    // Fallback to pattern-based detection
    return _fallbackLanguageDetection(text, config);
  }

  /// Extract basic audio features for language detection
  static String _extractAudioFeatures(List<double> audioBuffer) {
    if (audioBuffer.isEmpty) return 'silent';

    // Calculate basic audio statistics
    final mean = audioBuffer.reduce((a, b) => a + b) / audioBuffer.length;
    final variance = audioBuffer.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / audioBuffer.length;
    final stdDev = variance > 0 ? variance.sqrt() : 0.0;
    
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

  /// Parse the language detection response from Gemma 3
  static LanguageDetectionResult? _parseLanguageDetectionResponse(
    String response,
    SpeechConfig config,
  ) {
    try {
      // Extract JSON from response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');
      
      if (jsonStart == -1 || jsonEnd == -1) {
        _logger.w('⚠️ No JSON found in language detection response');
        return null;
      }

      final jsonStr = response.substring(jsonStart, jsonEnd + 1);
      
      // Parse JSON manually to avoid import dependencies
      final parsed = _parseSimpleJson(jsonStr);
      
      if (parsed == null) {
        _logger.w('⚠️ Failed to parse language detection JSON');
        return null;
      }

      final language = parsed['language'] as String?;
      final confidence = (parsed['confidence'] as num?)?.toDouble();
      final scores = parsed['scores'] as Map<String, dynamic>?;

      if (language == null || confidence == null) {
        _logger.w('⚠️ Missing required fields in language detection response');
        return null;
      }

      // Validate language is supported
      if (!config.supportedLanguages.contains(language)) {
        _logger.w('⚠️ Detected language "$language" not in supported list');
        return LanguageDetectionResult(
          detectedLanguage: config.language,
          confidence: 0.5,
          languageScores: {config.language: 0.5},
        );
      }

      final languageScores = <String, double>{};
      if (scores != null) {
        for (final entry in scores.entries) {
          final score = (entry.value as num?)?.toDouble();
          if (score != null) {
            languageScores[entry.key] = score;
          }
        }
      }

      _logger.d('✅ Detected language: $language (confidence: $confidence)');
      
      return LanguageDetectionResult(
        detectedLanguage: language,
        confidence: confidence,
        languageScores: languageScores,
      );
    } catch (e, stackTrace) {
      _logger.e('❌ Error parsing language detection response', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Simple JSON parser for basic objects
  static Map<String, dynamic>? _parseSimpleJson(String jsonStr) {
    try {
      // This is a very basic JSON parser - in production, use dart:convert
      final result = <String, dynamic>{};
      
      // Remove braces and split by commas
      final content = jsonStr.substring(1, jsonStr.length - 1);
      final pairs = content.split(',');
      
      for (final pair in pairs) {
        final colonIndex = pair.indexOf(':');
        if (colonIndex == -1) continue;
        
        final key = pair.substring(0, colonIndex).trim().replaceAll('"', '');
        final valueStr = pair.substring(colonIndex + 1).trim();
        
        // Parse value
        dynamic value;
        if (valueStr.startsWith('"') && valueStr.endsWith('"')) {
          value = valueStr.substring(1, valueStr.length - 1);
        } else if (valueStr.startsWith('{')) {
          // Nested object - just return the raw string for now
          value = <String, dynamic>{};
        } else {
          value = double.tryParse(valueStr) ?? valueStr;
        }
        
        result[key] = value;
      }
      
      return result;
    } catch (e) {
      return null;
    }
  }

  /// Fallback language detection using simple pattern matching
  static LanguageDetectionResult _fallbackLanguageDetection(
    String text,
    SpeechConfig config,
  ) {
    final lower = text.toLowerCase();
    
    // Simple pattern-based detection
    final patterns = {
      'en': ['the', 'and', 'is', 'it', 'you', 'that', 'he', 'was', 'for', 'on'],
      'es': ['el', 'la', 'de', 'que', 'y', 'a', 'en', 'un', 'es', 'se'],
      'fr': ['le', 'de', 'et', 'à', 'un', 'il', 'être', 'et', 'en', 'avoir'],
      'de': ['der', 'die', 'und', 'in', 'den', 'von', 'zu', 'das', 'mit', 'sich'],
      'it': ['il', 'di', 'che', 'è', 'per', 'un', 'in', 'del', 'la', 'da'],
      'pt': ['o', 'de', 'e', 'do', 'da', 'em', 'um', 'para', 'é', 'com'],
      'zh': ['的', '一', '是', '在', '不', '了', '有', '和', '人', '这'],
    };

    final scores = <String, double>{};
    
    for (final lang in config.supportedLanguages) {
      final langPatterns = patterns[lang] ?? [];
      int matches = 0;
      
      for (final pattern in langPatterns) {
        if (lower.contains(pattern)) {
          matches++;
        }
      }
      
      scores[lang] = matches / langPatterns.length;
    }

    // Find best match
    String bestLang = config.language;
    double bestScore = scores[bestLang] ?? 0.0;
    
    for (final entry in scores.entries) {
      if (entry.value > bestScore) {
        bestLang = entry.key;
        bestScore = entry.value;
      }
    }

    _logger.d('🔍 Fallback language detection: $bestLang (score: $bestScore)');
    
    return LanguageDetectionResult(
      detectedLanguage: bestLang,
      confidence: bestScore.clamp(0.1, 0.8), // Conservative confidence
      languageScores: scores,
    );
  }
}

extension on double {
  double sqrt() => this >= 0 ? math.sqrt(this) : 0.0;
}

// Import math for sqrt function
import 'dart:math' as math;
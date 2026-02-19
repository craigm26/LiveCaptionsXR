import '../models/speech_config.dart';

/// Result of a language detection operation.
class LanguageDetectionResult {
  final String detectedLanguage;
  final double confidence;
  final Map<String, double> languageScores;

  const LanguageDetectionResult({
    required this.detectedLanguage,
    required this.confidence,
    this.languageScores = const {},
  });

  @override
  String toString() =>
      'LanguageDetectionResult(language: $detectedLanguage, confidence: $confidence)';
}

/// Lightweight on-device language detection using text n-gram heuristics
/// and basic audio feature analysis.
class LanguageDetectionService {
  // Common words / markers per language for fast text-based detection.
  static const Map<String, List<String>> _languageMarkers = {
    'en': ['the', 'is', 'and', 'of', 'to', 'in', 'that', 'it', 'for', 'was'],
    'es': ['el', 'la', 'de', 'en', 'que', 'los', 'es', 'un', 'por', 'está'],
    'fr': ['le', 'la', 'de', 'et', 'les', 'des', 'en', 'un', 'une', 'est'],
    'de': ['der', 'die', 'und', 'in', 'den', 'von', 'ist', 'das', 'ein', 'mit'],
    'it': ['il', 'di', 'che', 'la', 'per', 'un', 'una', 'del', 'sono', 'con'],
    'pt': ['de', 'que', 'em', 'um', 'para', 'com', 'uma', 'os', 'no', 'da'],
    'zh': ['的', '是', '在', '了', '不', '有', '人', '这', '中', '我'],
    'ja': ['の', 'に', 'は', 'を', 'た', 'が', 'で', 'と', 'し', 'て'],
    'ko': ['의', '에', '는', '을', '이', '가', '는', '한', '로', '다'],
    'ar': ['في', 'من', 'على', 'إلى', 'أن', 'هذا', 'التي', 'هو', 'ما', 'مع'],
  };

  /// Detect language from raw audio features.
  ///
  /// This is a placeholder that currently falls back to the configured
  /// default language — full audio-based detection will be implemented
  /// when Nexa ASR exposes per-segment language scores.
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

    if (audioBuffer.isEmpty) {
      return LanguageDetectionResult(
        detectedLanguage: config.language,
        confidence: 1.0,
        languageScores: {config.language: 1.0},
      );
    }

    // Placeholder: return default language with reduced confidence
    // to signal that real audio-based detection is not yet available.
    // Full implementation will use Nexa ASR per-segment language scores.
    return LanguageDetectionResult(
      detectedLanguage: config.language,
      confidence: 0.5,
      languageScores: {config.language: 0.5},
    );
  }

  /// Detect language from transcribed text using word-frequency heuristics.
  static Future<LanguageDetectionResult?> detectLanguageFromText(
    String text,
    SpeechConfig config,
  ) async {
    if (!config.enableLanguageDetection) {
      return LanguageDetectionResult(
        detectedLanguage: config.language,
        confidence: 1.0,
        languageScores: {config.language: 1.0},
      );
    }

    if (text.trim().isEmpty) {
      return LanguageDetectionResult(
        detectedLanguage: config.language,
        confidence: 1.0,
        languageScores: {config.language: 1.0},
      );
    }

    final words = text.toLowerCase().split(RegExp(r'\s+'));
    final scores = <String, double>{};
    final supported = config.supportedLanguages;

    for (final lang in supported) {
      final markers = _languageMarkers[lang];
      if (markers == null) continue;
      int hits = 0;
      for (final word in words) {
        if (markers.contains(word)) hits++;
      }
      scores[lang] = words.isEmpty ? 0.0 : hits / words.length;
    }

    if (scores.isEmpty || scores.values.every((s) => s == 0.0)) {
      return LanguageDetectionResult(
        detectedLanguage: config.language,
        confidence: 0.5,
        languageScores: scores.isEmpty ? {config.language: 0.5} : scores,
      );
    }

    // Normalise scores so they sum to 1.
    final total = scores.values.fold(0.0, (a, b) => a + b);
    if (total > 0) {
      for (final key in scores.keys.toList()) {
        scores[key] = scores[key]! / total;
      }
    }

    final best = scores.entries.reduce((a, b) => a.value > b.value ? a : b);

    return LanguageDetectionResult(
      detectedLanguage: best.key,
      confidence: best.value,
      languageScores: scores,
    );
  }

}

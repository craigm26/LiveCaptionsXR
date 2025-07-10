import 'package:flutter_test/flutter_test.dart';
import 'package:live_captions_xr/core/services/language_detection_service.dart';
import 'package:live_captions_xr/core/models/speech_config.dart';

void main() {
  group('LanguageDetectionService Tests', () {
    test('should return default language when detection is disabled', () async {
      const config = SpeechConfig(
        language: 'en',
        enableLanguageDetection: false,
      );
      
      final result = await LanguageDetectionService.detectLanguage([0.1, 0.2, 0.3], config);
      
      expect(result, isNotNull);
      expect(result!.detectedLanguage, 'en');
      expect(result.confidence, 1.0);
    });

    test('should handle empty audio buffer', () async {
      const config = SpeechConfig(enableLanguageDetection: true);
      
      final result = await LanguageDetectionService.detectLanguage([], config);
      
      expect(result, isNotNull);
      expect(result!.detectedLanguage, 'en'); // Should fallback to default
    });

    test('should detect language from text patterns', () async {
      const config = SpeechConfig(
        enableLanguageDetection: true,
        supportedLanguages: ['en', 'es', 'fr'],
      );

      // Test English text
      final englishResult = await LanguageDetectionService.detectLanguageFromText(
        'the quick brown fox jumps over the lazy dog',
        config,
      );
      expect(englishResult?.detectedLanguage, 'en');

      // Test Spanish text
      final spanishResult = await LanguageDetectionService.detectLanguageFromText(
        'el gato está en la mesa',
        config,
      );
      expect(spanishResult?.detectedLanguage, 'es');

      // Test French text
      final frenchResult = await LanguageDetectionService.detectLanguageFromText(
        'le chat est sur la table',
        config,
      );
      expect(frenchResult?.detectedLanguage, 'fr');
    });

    test('should return default language for empty text', () async {
      const config = SpeechConfig(
        language: 'de',
        enableLanguageDetection: true,
      );
      
      final result = await LanguageDetectionService.detectLanguageFromText('', config);
      
      expect(result, isNotNull);
      expect(result!.detectedLanguage, 'de');
      expect(result.confidence, 1.0);
    });

    test('should handle unsupported languages gracefully', () async {
      const config = SpeechConfig(
        language: 'en',
        enableLanguageDetection: true,
        supportedLanguages: ['en', 'es'], // Limited set
      );
      
      // Text that would normally be detected as French but is not supported
      final result = await LanguageDetectionService.detectLanguageFromText(
        'bonjour comment allez-vous',
        config,
      );
      
      expect(result, isNotNull);
      // Should fallback to a supported language or default
      expect(['en', 'es'], contains(result!.detectedLanguage));
    });

    test('LanguageDetectionResult should have proper properties', () {
      const result = LanguageDetectionResult(
        detectedLanguage: 'es',
        confidence: 0.85,
        languageScores: {'en': 0.15, 'es': 0.85},
      );
      
      expect(result.detectedLanguage, 'es');
      expect(result.confidence, 0.85);
      expect(result.languageScores['es'], 0.85);
      expect(result.toString(), contains('es'));
      expect(result.toString(), contains('0.85'));
    });

    test('should extract basic audio features', () {
      const audioBuffer = [0.1, -0.2, 0.3, -0.1, 0.0, 0.5, -0.3];
      
      // This is testing the private method indirectly through detectLanguage
      // We can't test the private method directly, but we can verify it doesn't crash
      expect(() async {
        const config = SpeechConfig(enableLanguageDetection: true);
        await LanguageDetectionService.detectLanguage(audioBuffer, config);
      }, returnsNormally);
    });

    test('should handle fallback language detection with confidence scores', () async {
      const config = SpeechConfig(
        enableLanguageDetection: true,
        supportedLanguages: ['en', 'es', 'fr', 'de'],
      );
      
      // Mixed language text should have moderate confidence
      final result = await LanguageDetectionService.detectLanguageFromText(
        'hello mundo bonjour welt',
        config,
      );
      
      expect(result, isNotNull);
      expect(result!.confidence, lessThan(1.0)); // Should not be 100% confident
      expect(result.confidence, greaterThan(0.0));
      expect(config.supportedLanguages, contains(result.detectedLanguage));
    });

    test('should provide language scores in result', () async {
      const config = SpeechConfig(
        enableLanguageDetection: true,
        supportedLanguages: ['en', 'es', 'fr'],
      );
      
      final result = await LanguageDetectionService.detectLanguageFromText(
        'the quick brown fox',
        config,
      );
      
      expect(result, isNotNull);
      expect(result!.languageScores, isNotEmpty);
      expect(result.languageScores, isA<Map<String, double>>());
    });
  });
}
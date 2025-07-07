import 'package:flutter_test/flutter_test.dart';
import 'package:live_captions_xr/core/models/speech_config.dart';

void main() {
  group('SpeechConfig Tests', () {
    test('should create default configuration', () {
      const config = SpeechConfig();
      
      expect(config.voiceActivityThreshold, 0.01);
      expect(config.finalResultThreshold, 0.005);
      expect(config.language, 'en');
      expect(config.enableLanguageDetection, false);
      expect(config.enableRealTimeEnhancement, true);
    });

    test('should create configuration with custom parameters', () {
      const config = SpeechConfig(
        voiceActivityThreshold: 0.02,
        language: 'es',
        enableLanguageDetection: true,
      );
      
      expect(config.voiceActivityThreshold, 0.02);
      expect(config.language, 'es');
      expect(config.enableLanguageDetection, true);
    });

    test('should create copy with modified parameters', () {
      const originalConfig = SpeechConfig();
      final modifiedConfig = originalConfig.copyWith(
        voiceActivityThreshold: 0.03,
        language: 'fr',
      );
      
      expect(modifiedConfig.voiceActivityThreshold, 0.03);
      expect(modifiedConfig.language, 'fr');
      expect(modifiedConfig.enableRealTimeEnhancement, true); // Should keep original
    });

    test('should convert to and from map', () {
      const originalConfig = SpeechConfig(
        voiceActivityThreshold: 0.015,
        language: 'de',
        enableLanguageDetection: true,
        supportedLanguages: ['en', 'de', 'fr'],
      );
      
      final map = originalConfig.toMap();
      final restoredConfig = SpeechConfig.fromMap(map);
      
      expect(restoredConfig.voiceActivityThreshold, 0.015);
      expect(restoredConfig.language, 'de');
      expect(restoredConfig.enableLanguageDetection, true);
      expect(restoredConfig.supportedLanguages, ['en', 'de', 'fr']);
    });

    test('should provide preset configurations', () {
      // Low latency config
      expect(SpeechConfig.lowLatency.voiceActivityThreshold, 0.02);
      expect(SpeechConfig.lowLatency.bufferSizeMs, 1000);
      expect(SpeechConfig.lowLatency.enableRealTimeEnhancement, false);
      
      // High accuracy config
      expect(SpeechConfig.highAccuracy.voiceActivityThreshold, 0.005);
      expect(SpeechConfig.highAccuracy.bufferSizeMs, 3000);
      expect(SpeechConfig.highAccuracy.enhancementTemperature, 0.1);
      
      // Multilingual config
      expect(SpeechConfig.multilingual.enableLanguageDetection, true);
      expect(SpeechConfig.multilingual.supportedLanguages.length, greaterThan(7));
    });

    test('should have proper equality comparison', () {
      const config1 = SpeechConfig(voiceActivityThreshold: 0.02);
      const config2 = SpeechConfig(voiceActivityThreshold: 0.02);
      const config3 = SpeechConfig(voiceActivityThreshold: 0.03);
      
      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('should validate supported languages', () {
      const config = SpeechConfig();
      
      expect(config.supportedLanguages, contains('en'));
      expect(config.supportedLanguages, contains('es'));
      expect(config.supportedLanguages, contains('fr'));
      expect(config.supportedLanguages, contains('zh'));
    });

    test('should have reasonable default values', () {
      const config = SpeechConfig();
      
      expect(config.voiceActivityThreshold, greaterThan(0));
      expect(config.voiceActivityThreshold, lessThan(1));
      expect(config.finalResultThreshold, lessThan(config.voiceActivityThreshold));
      expect(config.bufferSizeMs, greaterThan(0));
      expect(config.interimResultIntervalMs, greaterThan(0));
      expect(config.finalResultIntervalMs, greaterThan(config.interimResultIntervalMs));
      expect(config.enhancementTemperature, greaterThan(0));
      expect(config.enhancementTemperature, lessThan(1));
    });

    test('should handle edge cases in fromMap', () {
      // Empty map should use defaults
      final config1 = SpeechConfig.fromMap({});
      expect(config1.voiceActivityThreshold, 0.01);
      expect(config1.language, 'en');
      
      // Invalid types should use defaults
      final config2 = SpeechConfig.fromMap({
        'voiceActivityThreshold': 'invalid',
        'language': 123,
        'enableLanguageDetection': 'not_a_bool',
      });
      expect(config2.voiceActivityThreshold, 0.01);
      expect(config2.language, 'en');
      expect(config2.enableLanguageDetection, false);
    });
  });
}
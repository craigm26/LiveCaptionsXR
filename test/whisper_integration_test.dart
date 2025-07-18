import 'package:flutter_test/flutter_test.dart';
import 'package:live_captions_xr/core/models/speech_config.dart';
import 'package:live_captions_xr/core/services/whisper_service.dart';

void main() {
  group('Whisper Integration Tests', () {
    test('should use base model by default', () {
      final config = const SpeechConfig();
      expect(config.whisperModel, equals('base'));
    });

    test('should create correct model filename', () {
      final config = const SpeechConfig(whisperModel: 'base');
      final expectedFilename = 'whisper_base.bin';
      expect(expectedFilename, equals('whisper_${config.whisperModel}.bin'));
    });

    test('should have reasonable default settings for base model', () {
      final config = const SpeechConfig();
      
      // Base model should have good defaults for real-time processing
      expect(config.whisperModel, equals('base'));
      expect(config.language, equals('en'));
      expect(config.whisperTranslateToEnglish, isFalse);
      expect(config.whisperSuppressNonSpeechTokens, isTrue);
      expect(config.whisperTemperature, equals(0.0)); // Deterministic output
    });

    test('should create WhisperService with base model config', () {
      final config = const SpeechConfig(whisperModel: 'base');
      final whisperService = WhisperService();
      
      // Verify the service can be created
      expect(whisperService, isNotNull);
      expect(whisperService.isInitialized, isFalse);
      expect(whisperService.isProcessing, isFalse);
    });
  });
} 
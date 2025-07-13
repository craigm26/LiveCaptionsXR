import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_captions_xr/core/models/speech_config.dart';
import 'package:live_captions_xr/core/models/speech_result.dart';
import 'package:live_captions_xr/core/services/gemma3n_service.dart';
import 'package:live_captions_xr/core/services/speech_processor.dart';
import 'package:live_captions_xr/core/services/visual_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'enhanced_speech_processor_test.mocks.dart';

@GenerateMocks([Gemma3nService, VisualService])
void main() {
  group('Enhanced SpeechProcessor Tests', () {
    late SpeechProcessor speechProcessor;
    late MockGemma3nService mockGemma3nService;
    late MockVisualService mockVisualService;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugin.csdcorp.com/speech_to_text'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'initialize') {
            return true;
          }
          return null;
        },
      );

      mockGemma3nService = MockGemma3nService();
      mockVisualService = MockVisualService();
      speechProcessor = SpeechProcessor(mockGemma3nService, mockVisualService);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugin.csdcorp.com/speech_to_text'),
        null,
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugin.csdcorp.com/speech_to_text'),
        null,
      );
    });

    test('should initialize with custom speech config', () async {
      const config = SpeechConfig(
        voiceActivityThreshold: 0.02,
        language: 'es',
        enableLanguageDetection: true,
      );

      final result = await speechProcessor.initialize(config: config);

      expect(result, true);
      expect(speechProcessor.isReady, true);
      expect(speechProcessor.config.voiceActivityThreshold, 0.02);
      expect(speechProcessor.config.language, 'es');
      expect(speechProcessor.config.enableLanguageDetection, true);
    });

    test('should start processing with updated config', () async {
      await speechProcessor.initialize();

      const newConfig = SpeechConfig(
        voiceActivityThreshold: 0.03,
        language: 'fr',
      );

      final result = await speechProcessor.startProcessing(config: newConfig);

      expect(result, true);
      expect(speechProcessor.isProcessing, true);
      expect(speechProcessor.config.voiceActivityThreshold, 0.03);
      expect(speechProcessor.config.language, 'fr');
    });

    test('should update configuration', () async {
      await speechProcessor.initialize();

      const newConfig = SpeechConfig(
        voiceActivityThreshold: 0.025,
        enableRealTimeEnhancement: false,
      );

      final result = await speechProcessor.updateConfig(newConfig);

      expect(result, true);
      expect(speechProcessor.config.voiceActivityThreshold, 0.025);
      expect(speechProcessor.config.enableRealTimeEnhancement, false);
    });

    test('should provide processing statistics', () async {
      await speechProcessor.initialize();
      await speechProcessor.startProcessing();

      final stats = speechProcessor.getStatistics();

      expect(stats['isInitialized'], true);
      expect(stats['isProcessing'], true);
      expect(stats['config'], isNotNull);
      expect(stats['currentLanguage'], isNotNull);
    });

    test('should enhance text with context and language awareness', () async {
      when(mockVisualService.captureVisualSnapshot())
          .thenAnswer((_) async => Uint8List(0));
      when(mockGemma3nService.runMultimodalInference(
        audioInput: anyNamed('audioInput'),
        imageInput: anyNamed('imageInput'),
        textContext: anyNamed('textContext'),
      )).thenAnswer((_) async => 'Enhanced text result');

      await speechProcessor.initialize(
        config: const SpeechConfig(
          language: 'en',
          enableRealTimeEnhancement: true,
        ),
      );

      final enhanced = await speechProcessor.enhanceText(
        'hello world',
        context: 'conversation about greetings',
      );

      expect(enhanced, 'Enhanced text result');
    });

    test('should handle text enhancement when disabled', () async {
      when(mockVisualService.captureVisualSnapshot())
          .thenAnswer((_) async => null);
      await speechProcessor.initialize(
        config: const SpeechConfig(enableRealTimeEnhancement: false),
      );

      final enhanced = await speechProcessor.enhanceText('test text');

      expect(enhanced, 'test text'); // Should return original text
    });

    test('should track current language', () async {
      const config = SpeechConfig(language: 'de');
      await speechProcessor.initialize(config: config);

      expect(speechProcessor.currentLanguage, 'de');
    });

    test('should provide preset configurations', () {
      expect(SpeechConfig.lowLatency.bufferSizeMs,
          lessThan(SpeechConfig.highAccuracy.bufferSizeMs));
      expect(SpeechConfig.multilingual.enableLanguageDetection, true);
      expect(SpeechConfig.highAccuracy.enhancementTemperature, lessThan(0.5));
    });

    test('should handle SpeechResult with metadata correctly', () {
      final result = SpeechResult(
        text: 'Test speech',
        confidence: 0.9,
        isFinal: true,
        timestamp: DateTime.now(),
        metadata: {
          'type': 'languageDetection',
          'language': 'es',
          'audioLevel': 0.5,
        },
      );

      expect(result.isLanguageDetection, true);
      expect(result.detectedLanguage, 'es');
      expect(result.audioLevel, 0.5);
      expect(
          result.hasActualSpeech, false); // Language detection is not actual speech
    });

    test('should identify actual speech content', () {
      final speechResult = SpeechResult(
        text: 'Hello, how are you?',
        confidence: 0.9,
        isFinal: true,
        timestamp: DateTime.now(),
      );

      final systemResult = SpeechResult(
        text: '[Language detected: Spanish]',
        confidence: 0.9,
        isFinal: false,
        timestamp: DateTime.now(),
        metadata: {'type': 'languageDetection'},
      );

      expect(speechResult.hasActualSpeech, true);
      expect(systemResult.hasActualSpeech, false);
    });
  });
}
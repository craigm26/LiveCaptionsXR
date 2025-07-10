import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:live_captions_xr/core/services/speech_processor.dart';
import 'package:live_captions_xr/core/models/speech_config.dart';
import 'package:live_captions_xr/core/models/speech_result.dart';

void main() {
  group('Enhanced SpeechProcessor Tests', () {
    late SpeechProcessor speechProcessor;
    late List<MethodCall> methodCalls;

    setUp(() {
      speechProcessor = SpeechProcessor();
      methodCalls = [];
      
      // Mock the method channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_gemma'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          
          switch (methodCall.method) {
            case 'loadModel':
              return {'success': true, 'modelPath': '/mock/path'};
            case 'startAudioCapture':
            case 'stopAudioCapture':
            case 'processAudioChunk':
            case 'updateConfig':
              return null;
            case 'generateText':
              return {
                'success': true,
                'text': 'Enhanced text result'
              };
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_gemma'),
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
      
      // Verify method was called with config
      final startCaptureCall = methodCalls.firstWhere(
        (call) => call.method == 'startAudioCapture',
      );
      expect(startCaptureCall.arguments['config'], isNotNull);
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
      await speechProcessor.initialize(
        config: const SpeechConfig(
          language: 'en',
          enableRealTimeEnhancement: true,
        ),
      );
      
      final enhanced = await speechProcessor.enhanceText(
        'hello world',
        context: 'conversation about greetings',
        speakerDirection: 'front',
      );
      
      expect(enhanced, 'Enhanced text result');
      
      // Verify the prompt includes language and context
      final generateCall = methodCalls.firstWhere(
        (call) => call.method == 'generateText',
      );
      final prompt = generateCall.arguments['prompt'] as String;
      expect(prompt, contains('Language: en'));
      expect(prompt, contains('conversation about greetings'));
      expect(prompt, contains('Speaker direction: front'));
    });

    test('should handle text enhancement when disabled', () async {
      await speechProcessor.initialize(
        config: const SpeechConfig(enableRealTimeEnhancement: false),
      );
      
      final enhanced = await speechProcessor.enhanceText('test text');
      
      expect(enhanced, 'test text'); // Should return original text
    });

    test('should process audio chunk with configuration', () async {
      await speechProcessor.initialize();
      await speechProcessor.startProcessing();
      
      final audioData = Float32List.fromList([0.1, 0.2, 0.3, 0.4]);
      await speechProcessor.processAudioChunk(audioData);
      
      final processCall = methodCalls.firstWhere(
        (call) => call.method == 'processAudioChunk',
      );
      expect(processCall.arguments['audioData'], audioData);
      expect(processCall.arguments['config'], isNotNull);
    });

    test('should track current language', () async {
      const config = SpeechConfig(language: 'de');
      await speechProcessor.initialize(config: config);
      
      expect(speechProcessor.currentLanguage, 'de');
    });

    test('should handle language detection results in speech stream', () async {
      await speechProcessor.initialize(
        config: const SpeechConfig(enableLanguageDetection: true),
      );
      
      bool languageDetectionReceived = false;
      speechProcessor.speechResults.listen((result) {
        if (result.isLanguageDetection) {
          languageDetectionReceived = true;
          expect(result.detectedLanguage, isNotNull);
        }
      });
      
      // This would normally be triggered by the native plugin
      // For testing, we can simulate it by calling detectLanguage
      await speechProcessor.detectLanguage([0.1, 0.2, 0.3]);
      
      // In a real scenario, language detection would be async
      // Here we just verify the method doesn't crash
      expect(() => speechProcessor.detectLanguage([0.1, 0.2]), returnsNormally);
    });

    test('should provide preset configurations', () {
      expect(SpeechConfig.lowLatency.bufferSizeMs, lessThan(SpeechConfig.highAccuracy.bufferSizeMs));
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
      expect(result.hasActualSpeech, false); // Language detection is not actual speech
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
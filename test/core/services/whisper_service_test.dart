import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_captions_xr/core/services/whisper_service.dart';
import 'package:live_captions_xr/core/models/speech_config.dart';
import 'package:live_captions_xr/core/models/speech_result.dart';

void main() {
  group('WhisperService', () {
    late WhisperService whisperService;

    setUp(() {
      whisperService = WhisperService();
    });

    tearDown(() async {
      await whisperService.dispose();
    });

    test('should initialize successfully', () async {
      final config = const SpeechConfig(
        whisperModel: 'base',
        language: 'en',
        whisperTranslateToEnglish: false,
      );

      final result = await whisperService.initialize(config: config);
      expect(result, isTrue);
      expect(whisperService.isInitialized, isTrue);
    });

    test('should start processing', () async {
      await whisperService.initialize();
      
      final result = await whisperService.startProcessing();
      expect(result, isTrue);
      expect(whisperService.isProcessing, isTrue);
    });

    test('should process audio buffer and return speech result', () async {
      await whisperService.initialize();
      await whisperService.startProcessing();

      // Create a dummy audio buffer
      final audioData = List<int>.filled(16000, 0).cast<int>();
      final uint8List = Uint8List.fromList(audioData);

      final result = await whisperService.processAudioBuffer(uint8List);
      
      expect(result, isA<SpeechResult>());
      expect(result.text, isNotEmpty);
      expect(result.confidence, isA<double>());
      expect(result.isFinal, isTrue);
      expect(result.timestamp, isA<DateTime>());
    });

    test('should emit speech results through stream', () async {
      await whisperService.initialize();
      await whisperService.startProcessing();

      final results = <SpeechResult>[];
      final subscription = whisperService.speechResults.listen(results.add);

      // Create a dummy audio buffer
      final audioData = List<int>.filled(16000, 0).cast<int>();
      final uint8List = Uint8List.fromList(audioData);

      await whisperService.processAudioBuffer(uint8List);
      
      // Wait a bit for the stream to emit
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(results, isNotEmpty);
      expect(results.first, isA<SpeechResult>());
      
      await subscription.cancel();
    });

    test('should update configuration', () async {
      await whisperService.initialize();
      
      final newConfig = const SpeechConfig(
        whisperModel: 'small',
        language: 'es',
        whisperTranslateToEnglish: true,
      );

      await whisperService.updateConfig(newConfig);
      // Configuration update should not throw an error
    });

    test('should stop processing', () async {
      await whisperService.initialize();
      await whisperService.startProcessing();
      
      expect(whisperService.isProcessing, isTrue);
      
      await whisperService.stopProcessing();
      expect(whisperService.isProcessing, isFalse);
    });

    test('should handle disposal correctly', () async {
      await whisperService.initialize();
      await whisperService.startProcessing();
      
      await whisperService.dispose();
      
      expect(whisperService.isInitialized, isFalse);
      expect(whisperService.isProcessing, isFalse);
    });

    test('should return fallback result when not initialized', () async {
      final audioData = List<int>.filled(16000, 0).cast<int>();
      final uint8List = Uint8List.fromList(audioData);

      final result = await whisperService.processAudioBuffer(uint8List);
      
      expect(result.text, equals('Whisper not initialized'));
      expect(result.confidence, equals(0.0));
      expect(result.isFinal, isTrue);
    });
  });
} 
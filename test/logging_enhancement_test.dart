import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:live_captions_xr/core/services/speech_processor.dart';
import 'package:live_captions_xr/core/services/stereo_audio_capture.dart';
import 'package:live_captions_xr/core/models/speech_config.dart';
import 'package:live_captions_xr/core/services/gemma3n_service.dart';
import 'package:live_captions_xr/core/services/visual_service.dart';
import 'package:mockito/mockito.dart';

class MockGemma3nService extends Mock implements Gemma3nService {}

class MockVisualService extends Mock implements VisualService {}

void main() {
  group('Enhanced Logging Tests', () {
    late SpeechProcessor speechProcessor;
    late MockGemma3nService mockGemma3nService;
    late MockVisualService mockVisualService;
    late List<MethodCall> methodCalls;

    setUp(() {
      mockGemma3nService = MockGemma3nService();
      mockVisualService = MockVisualService();
      speechProcessor = SpeechProcessor(mockGemma3nService, mockVisualService);
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
              return null;
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

    test('should handle stereo audio frame conversion correctly', () {
      final left = Float32List.fromList([1.0, 0.5, -0.5, -1.0]);
      final right = Float32List.fromList([0.0, 0.5, 0.5, 1.0]);
      final frame = StereoAudioFrame(left: left, right: right);

      final mono = frame.toMono();
      
      expect(mono.length, equals(4));
      expect(mono[0], equals(0.5)); // (1.0 + 0.0) / 2
      expect(mono[1], equals(0.5)); // (0.5 + 0.5) / 2
      expect(mono[2], equals(0.0)); // (-0.5 + 0.5) / 2
      expect(mono[3], equals(0.0)); // (-1.0 + 1.0) / 2
    });

    test('should properly configure voice activity threshold', () async {
      const config = SpeechConfig(voiceActivityThreshold: 0.05);
      await speechProcessor.initialize(config: config);
      
      expect(speechProcessor.config.voiceActivityThreshold, equals(0.05));
    });
  });
}

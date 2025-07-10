import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:live_captions_xr/core/services/speech_processor.dart';
import 'package:live_captions_xr/core/services/stereo_audio_capture.dart';
import 'package:live_captions_xr/core/models/speech_config.dart';

void main() {
  group('Enhanced Logging Tests', () {
    late SpeechProcessor speechProcessor;
    late List<MethodCall> methodCalls;

    setUp(() {
      speechProcessor = SpeechProcessor();
      methodCalls = [];
      
      // Mock the method channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('gemma3n_multimodal'),
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
        const MethodChannel('gemma3n_multimodal'),
        null,
      );
    });

    test('should log voice activity detection properly', () async {
      await speechProcessor.initialize();
      await speechProcessor.startProcessing();
      
      // Test with audio above threshold
      final loudAudio = Float32List.fromList([0.1, 0.2, 0.3, 0.4]); // High amplitude
      await speechProcessor.processAudioChunk(loudAudio);
      
      // Test with audio below threshold  
      final quietAudio = Float32List.fromList([0.001, 0.002, 0.001, 0.002]); // Low amplitude
      await speechProcessor.processAudioChunk(quietAudio);
      
      // Verify method calls were made appropriately
      final processChunkCalls = methodCalls.where(
        (call) => call.method == 'processAudioChunk',
      ).toList();
      
      // Should only have one call for the loud audio (above threshold)
      expect(processChunkCalls.length, equals(1));
      expect(processChunkCalls.first.arguments['audioData'], equals(loudAudio));
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
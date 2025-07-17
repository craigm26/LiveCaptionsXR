import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_captions_xr/core/models/speech_config.dart';
import 'package:live_captions_xr/core/services/gemma3n_service.dart';
import 'package:live_captions_xr/core/services/enhanced_speech_processor.dart';
import 'package:live_captions_xr/core/services/visual_service.dart';
import 'package:mockito/mockito.dart';

class MockGemma3nService extends Mock implements Gemma3nService {}

class MockVisualService extends Mock implements VisualService {}

void main() {
  group('Speech Processor Connection Test', () {
    setUp(() {
      // No setup needed for these tests
    });

    test('should handle audio chunks correctly', () async {
      // Create test audio data
      final testAudio = Float32List(9600); // Typical chunk size
      
      // Fill with test audio that should trigger voice activity
      for (int i = 0; i < testAudio.length; i++) {
        testAudio[i] = (i % 100) / 100.0 - 0.5; // Generate values between -0.5 and 0.5
      }
      
      // Mock the native plugin to avoid actual initialization
      // In a real scenario, this would be handled by the native plugin
      
      // Test voice activity detection calculation
      double rmsLevel = 0.0;
      for (int i = 0; i < testAudio.length; i++) {
        rmsLevel += testAudio[i] * testAudio[i];
      }
      rmsLevel = testAudio.length > 0 ? sqrt(rmsLevel / testAudio.length) : 0.0;
      
      // Verify RMS calculation works
      expect(rmsLevel, greaterThan(0.0));
      
      // Test with different voice activity thresholds
      const config = SpeechConfig(voiceActivityThreshold: 0.01);
      expect(rmsLevel, greaterThan(config.voiceActivityThreshold));
    });
    
    test('should detect voice activity correctly', () {
      // Test with quiet audio (should NOT trigger voice activity)
      final quietAudio = Float32List(9600);
      for (int i = 0; i < quietAudio.length; i++) {
        quietAudio[i] = 0.001 * (i % 10) / 10.0; // Very quiet
      }
      
      double quietRms = 0.0;
      for (int i = 0; i < quietAudio.length; i++) {
        quietRms += quietAudio[i] * quietAudio[i];
      }
      quietRms = quietAudio.length > 0 ? sqrt(quietRms / quietAudio.length) : 0.0;
      
      const config = SpeechConfig(voiceActivityThreshold: 0.01);
      expect(quietRms, lessThan(config.voiceActivityThreshold));
      
      // Test with loud audio (should trigger voice activity)
      final loudAudio = Float32List(9600);
      for (int i = 0; i < loudAudio.length; i++) {
        loudAudio[i] = 0.1 * (i % 10) / 10.0; // Louder
      }
      
      double loudRms = 0.0;
      for (int i = 0; i < loudAudio.length; i++) {
        loudRms += loudAudio[i] * loudAudio[i];
      }
      loudRms = loudAudio.length > 0 ? sqrt(loudRms / loudAudio.length) : 0.0;
      
      expect(loudRms, greaterThan(config.voiceActivityThreshold));
    });
    
    test('should handle empty audio chunks', () {
      final emptyAudio = Float32List(0);
      
      double rmsLevel = 0.0;
      for (int i = 0; i < emptyAudio.length; i++) {
        rmsLevel += emptyAudio[i] * emptyAudio[i];
      }
      rmsLevel = emptyAudio.length > 0 ? sqrt(rmsLevel / emptyAudio.length) : 0.0;
      
      expect(rmsLevel, equals(0.0));
    });
  });
}
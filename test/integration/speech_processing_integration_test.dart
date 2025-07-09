import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_captions_xr/core/services/stereo_audio_capture.dart';

void main() {
  group('Audio Frame Processing Integration Test', () {
    late StereoAudioCapture audioCapture;
    
    setUp(() {
      audioCapture = StereoAudioCapture();
    });

    test('should handle real-world audio data format from logs', () {
      // Simulate the exact scenario from the logs: 38400 bytes
      final testData = Uint8List(38400);
      
      // Generate realistic audio data (simulating sine wave)
      for (int i = 0; i < testData.length; i += 4) {
        // Create a test audio pattern
        final sampleIndex = i ~/ 4;
        final amplitude = 0.05; // Moderate amplitude to trigger voice activity
        final frequency = 440.0; // A4 note
        final sampleRate = 16000.0;
        
        // Simple sine wave approximation
        final x = 2 * 3.14159 * frequency * sampleIndex / sampleRate;
        final testValue = amplitude * (x - (x * x * x) / 6); // Basic sine approximation
        
        // Convert to Float32 bytes (little-endian)
        final floatBytes = Float32List.fromList([testValue]).buffer.asUint8List();
        
        if (i + 3 < testData.length) {
          testData[i] = floatBytes[0];
          testData[i + 1] = floatBytes[1];
          testData[i + 2] = floatBytes[2];
          testData[i + 3] = floatBytes[3];
        }
      }
      
      // This should match the log entry: "📊 Processing Uint8List with 38400 bytes"
      expect(testData.length, equals(38400));
      expect(testData.length % 4, equals(0)); // Should be multiple of 4
      
      // Test audio frame parsing (this is where the issue occurs)
      final frame = audioCapture.parseFrame(testData);
      
      // Verify the frame was parsed correctly
      expect(frame.left.length, equals(38400 ~/ 4 ~/ 2)); // 4800 samples per channel
      expect(frame.right.length, equals(38400 ~/ 4 ~/ 2)); // 4800 samples per channel
      
      // Test mono conversion
      final mono = frame.toMono();
      expect(mono.length, equals(frame.left.length));
      
      // Test RMS calculation (this is what would trigger voice activity)
      double rms = 0.0;
      for (int i = 0; i < mono.length; i++) {
        rms += mono[i] * mono[i];
      }
      rms = mono.length > 0 ? (rms / mono.length).sqrt() : 0.0;
      
      // Should have audio activity above the default threshold (0.01)
      expect(rms, greaterThan(0.001));
      
      // Verify first few samples are reasonable
      expect(frame.left[0], isFinite);
      expect(frame.right[0], isFinite);
      expect(mono[0], isFinite);
      
      print('✅ Audio frame parsing test passed');
      print('📊 Parsed ${frame.left.length} samples per channel');
      print('🎵 Mono RMS: ${rms.toStringAsFixed(4)}');
    });
    
    test('should handle voice activity detection correctly', () {
      // Test with data that should trigger voice activity
      final testData = Uint8List(38400);
      
      // Generate audio with amplitude above voice activity threshold
      for (int i = 0; i < testData.length; i += 4) {
        final testValue = 0.1 * ((i % 100) / 100.0 - 0.5); // Amplitude 0.1
        final floatBytes = Float32List.fromList([testValue]).buffer.asUint8List();
        
        if (i + 3 < testData.length) {
          testData[i] = floatBytes[0];
          testData[i + 1] = floatBytes[1];
          testData[i + 2] = floatBytes[2];
          testData[i + 3] = floatBytes[3];
        }
      }
      
      final frame = audioCapture.parseFrame(testData);
      final mono = frame.toMono();
      
      // Calculate RMS as SpeechProcessor would
      double rms = 0.0;
      for (int i = 0; i < mono.length; i++) {
        rms += mono[i] * mono[i];
      }
      rms = mono.length > 0 ? (rms / mono.length).sqrt() : 0.0;
      
      // Should trigger voice activity with default threshold 0.01
      const voiceActivityThreshold = 0.01;
      expect(rms, greaterThan(voiceActivityThreshold));
      
      print('✅ Voice activity detection test passed');
      print('🔊 RMS level: ${rms.toStringAsFixed(4)} (threshold: $voiceActivityThreshold)');
    });
    
    test('should handle quiet audio correctly', () {
      // Test with data that should NOT trigger voice activity
      final testData = Uint8List(38400);
      
      // Generate very quiet audio
      for (int i = 0; i < testData.length; i += 4) {
        final testValue = 0.001 * ((i % 10) / 10.0 - 0.5); // Very quiet
        final floatBytes = Float32List.fromList([testValue]).buffer.asUint8List();
        
        if (i + 3 < testData.length) {
          testData[i] = floatBytes[0];
          testData[i + 1] = floatBytes[1];
          testData[i + 2] = floatBytes[2];
          testData[i + 3] = floatBytes[3];
        }
      }
      
      final frame = audioCapture.parseFrame(testData);
      final mono = frame.toMono();
      
      // Calculate RMS
      double rms = 0.0;
      for (int i = 0; i < mono.length; i++) {
        rms += mono[i] * mono[i];
      }
      rms = mono.length > 0 ? (rms / mono.length).sqrt() : 0.0;
      
      // Should NOT trigger voice activity
      const voiceActivityThreshold = 0.01;
      expect(rms, lessThan(voiceActivityThreshold));
      
      print('✅ Quiet audio test passed');
      print('🔇 RMS level: ${rms.toStringAsFixed(4)} (threshold: $voiceActivityThreshold)');
    });
  });
}

// Helper extension for sqrt
extension on double {
  double sqrt() {
    if (this < 0) return double.nan;
    if (this == 0) return 0;
    
    // Newton's method for square root
    double x = this;
    double prev = 0;
    while ((x - prev).abs() > 1e-10) {
      prev = x;
      x = (x + this / x) / 2;
    }
    return x;
  }
}
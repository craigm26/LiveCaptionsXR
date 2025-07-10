import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_captions_xr/core/services/stereo_audio_capture.dart';

void main() {
  group('Speech Processing Debug Tests', () {
    late StereoAudioCapture audioCapture;
    
    setUp(() {
      audioCapture = StereoAudioCapture();
    });

    test('should parse Uint8List audio data correctly', () {
      // Create test audio data - 38400 bytes (typical from logs)
      final testData = Uint8List(38400);
      
      // Fill with test Float32 values in little-endian format
      for (int i = 0; i < testData.length; i += 4) {
        // Generate test values between -1.0 and 1.0
        final testValue = (i / 4000.0) - 1.0;
        final floatBytes = Float32List.fromList([testValue]).buffer.asUint8List();
        if (i + 3 < testData.length) {
          testData[i] = floatBytes[0];
          testData[i + 1] = floatBytes[1];
          testData[i + 2] = floatBytes[2];
          testData[i + 3] = floatBytes[3];
        }
      }
      
      // Test audio frame parsing
      final frame = audioCapture.parseFrame(testData);
      
      // Verify structure
      expect(frame.left.length, 38400 ~/ 4 ~/ 2); // 4800 samples per channel
      expect(frame.right.length, 38400 ~/ 4 ~/ 2); // 4800 samples per channel
      
      // Verify mono conversion works
      final mono = frame.toMono();
      expect(mono.length, frame.left.length);
      
      // Verify audio levels are reasonable
      double rms = 0.0;
      for (int i = 0; i < mono.length; i++) {
        rms += mono[i] * mono[i];
      }
      rms = mono.length > 0 ? sqrt(rms / mono.length) : 0.0;
      
      expect(rms, greaterThan(0.0)); // Should have some audio activity
    });
    
    test('should handle empty audio data', () {
      final emptyData = Uint8List(0);
      expect(() => audioCapture.parseFrame(emptyData), throwsA(isA<ArgumentError>()));
    });
    
    test('should handle invalid audio data length', () {
      final invalidData = Uint8List(37); // Not multiple of 4
      expect(() => audioCapture.parseFrame(invalidData), throwsA(isA<ArgumentError>()));
    });
    
    test('should handle odd number of samples', () {
      final oddData = Uint8List(12); // 3 Float32 values (odd)
      expect(() => audioCapture.parseFrame(oddData), throwsA(isA<ArgumentError>()));
    });
  });
}

// Remove the extension as the method is now public
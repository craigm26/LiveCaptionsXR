import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_captions_xr/core/services/stereo_audio_capture.dart';

void main() {
  group('Audio Buffer Fix Tests', () {
    late StereoAudioCapture audioCapture;

    setUp(() {
      audioCapture = StereoAudioCapture();
    });

    test('should handle even number of samples correctly', () {
      // Create a Uint8List with 9600 Float32 samples (38400 bytes)
      final evenSamples = Uint8List(38400);
      
      // Fill with test data (interleaved stereo)
      for (int i = 0; i < evenSamples.length; i += 8) {
        // Left channel sample (4 bytes)
        evenSamples[i] = 0x00;
        evenSamples[i + 1] = 0x00;
        evenSamples[i + 2] = 0x80;
        evenSamples[i + 3] = 0x3F; // 1.0 in Float32
        
        // Right channel sample (4 bytes)
        evenSamples[i + 4] = 0x00;
        evenSamples[i + 5] = 0x00;
        evenSamples[i + 6] = 0x00;
        evenSamples[i + 7] = 0x3F; // 0.5 in Float32
      }

      expect(() => audioCapture.parseFrame(evenSamples), returnsNormally);
      
      final frame = audioCapture.parseFrame(evenSamples);
      expect(frame.left.length, equals(4800));
      expect(frame.right.length, equals(4800));
    });

    test('should handle odd number of samples by truncating', () {
      // Create a Uint8List with 9601 Float32 samples (38404 bytes)
      final oddSamples = Uint8List(38404);
      
      // Fill with test data
      for (int i = 0; i < oddSamples.length - 4; i += 8) {
        // Left channel sample (4 bytes)
        oddSamples[i] = 0x00;
        oddSamples[i + 1] = 0x00;
        oddSamples[i + 2] = 0x80;
        oddSamples[i + 3] = 0x3F;
        
        // Right channel sample (4 bytes)
        oddSamples[i + 4] = 0x00;
        oddSamples[i + 5] = 0x00;
        oddSamples[i + 6] = 0x00;
        oddSamples[i + 7] = 0x3F;
      }

      expect(() => audioCapture.parseFrame(oddSamples), returnsNormally);
      
      final frame = audioCapture.parseFrame(oddSamples);
      // Should truncate to 9600 samples (4800 per channel)
      expect(frame.left.length, equals(4800));
      expect(frame.right.length, equals(4800));
    });

    test('should handle Float32List directly', () {
      // Create Float32List with even number of samples
      final samples = Float32List(9600);
      for (int i = 0; i < samples.length; i += 2) {
        samples[i] = 1.0;     // Left channel
        samples[i + 1] = 0.5; // Right channel
      }

      expect(() => audioCapture.parseFrame(samples), returnsNormally);
      
      final frame = audioCapture.parseFrame(samples);
      expect(frame.left.length, equals(4800));
      expect(frame.right.length, equals(4800));
      expect(frame.left[0], equals(1.0));
      expect(frame.right[0], equals(0.5));
    });

    test('should handle Float32List with odd samples by truncating', () {
      // Create Float32List with odd number of samples
      final samples = Float32List(9601);
      for (int i = 0; i < samples.length - 1; i += 2) {
        samples[i] = 1.0;     // Left channel
        samples[i + 1] = 0.5; // Right channel
      }
      samples[9600] = 0.75; // Extra sample

      expect(() => audioCapture.parseFrame(samples), returnsNormally);
      
      final frame = audioCapture.parseFrame(samples);
      // Should truncate to 9600 samples (4800 per channel)
      expect(frame.left.length, equals(4800));
      expect(frame.right.length, equals(4800));
    });

    test('should reject invalid data types', () {
      expect(() => audioCapture.parseFrame("invalid"), throwsArgumentError);
      expect(() => audioCapture.parseFrame(123), throwsArgumentError);
      expect(() => audioCapture.parseFrame(null), throwsArgumentError);
    });
  });
}
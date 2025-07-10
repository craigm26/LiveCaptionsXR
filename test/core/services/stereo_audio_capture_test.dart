import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:live_captions_xr/core/services/stereo_audio_capture.dart';

void main() {
  group('StereoAudioFrame', () {
    test('toMono() should correctly downmix stereo to mono', () {
      final left = Float32List.fromList([1.0, 0.5, -0.5, -1.0, 0.0]);
      final right = Float32List.fromList([0.0, 0.5, 0.5, 1.0, 0.0]);
      final frame = StereoAudioFrame(left: left, right: right);

      final mono = frame.toMono();

      expect(mono.length, left.length);
      expect(mono[0], (1.0 + 0.0) / 2.0); // 0.5
      expect(mono[1], (0.5 + 0.5) / 2.0); // 0.5
      expect(mono[2], (-0.5 + 0.5) / 2.0); // 0.0
      expect(mono[3], (-1.0 + 1.0) / 2.0); // 0.0
      expect(mono[4], (0.0 + 0.0) / 2.0); // 0.0
    });

    test('toMono() should handle empty lists', () {
      final left = Float32List.fromList([]);
      final right = Float32List.fromList([]);
      final frame = StereoAudioFrame(left: left, right: right);

      final mono = frame.toMono();

      expect(mono.length, 0);
    });

    test('toMono() should handle single element lists', () {
      final left = Float32List.fromList([0.7]);
      final right = Float32List.fromList([-0.3]);
      final frame = StereoAudioFrame(left: left, right: right);

      final mono = frame.toMono();

      expect(mono.length, 1);
      expect(mono[0], closeTo((0.7 + -0.3) / 2.0, 1e-4)); // 0.2
    });
  });
}

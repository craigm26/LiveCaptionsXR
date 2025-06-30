import 'dart:math' as math;
import 'dart:typed_data';

import 'stereo_audio_capture.dart';

/// Basic audio direction estimation using RMS amplitude comparison.
///
/// This implements the algorithm described in `prd/02_basic_audio_direction_estimation.md`.
/// It calculates the root mean square (RMS) value of the left and right channels
/// of a [StereoAudioFrame] and converts the normalized difference into a
/// horizontal angle in radians (negative = left, positive = right).
class SpeechLocalizer {
  /// Estimate horizontal angle from a stereo audio frame.
  ///
  /// Returns an angle in radians between `-pi/2` (full left) and `pi/2` (full right).
  double estimateDirection(StereoAudioFrame frame) {
    final leftRms = _rms(frame.left);
    final rightRms = _rms(frame.right);
    final sum = leftRms + rightRms;
    if (sum == 0) return 0;
    final diff = leftRms - rightRms;
    final normalized = (diff / sum).clamp(-1.0, 1.0);
    return normalized * (math.pi / 2);
  }

  /// Convert an angle in radians to a simple left/center/right label.
  String directionLabel(double angle) {
    const threshold = math.pi / 8; // ~22.5 degrees dead zone for "center"
    if (angle > threshold) return 'right';
    if (angle < -threshold) return 'left';
    return 'center';
  }

  double _rms(Float32List samples) {
    var sum = 0.0;
    for (var i = 0; i < samples.length; i++) {
      final v = samples[i];
      sum += v * v;
    }
    return math.sqrt(sum / samples.length);
  }
}

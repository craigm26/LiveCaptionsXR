import 'dart:math' as math;
import 'dart:typed_data';

import 'package:scidart/scidart.dart';

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

  /// Estimate horizontal angle using GCC-PHAT Time Difference of Arrival.
  ///
  /// [sampleRate] is the sampling rate of the audio buffers and
  /// [micDistance] is the spacing between device microphones in meters.
  double estimateDirectionAdvanced(
    StereoAudioFrame frame, {
    double sampleRate = 48000,
    double micDistance = 0.08,
    double soundSpeed = 343.0,
  }) {
    final n = frame.left.length;
    final left = Array(frame.left.toList());
    final right = Array(frame.right.toList());

    var leftFft = fft(arrayToComplexArray(left));
    var rightFft = fft(arrayToComplexArray(right));

    // Cross power spectrum with PHAT weighting
    var cross = ArrayComplex.fixed(n);
    for (var i = 0; i < n; i++) {
      final prod = leftFft[i] * complexConjugate(rightFft[i]);
      final mag = complexAbs(prod);
      cross[i] = mag > 0 ? prod / Complex(real: mag, imaginary: 0) : prod;
    }

    final corr = ifft(cross);

    var maxVal = -double.infinity;
    var maxIndex = 0;
    for (var i = 0; i < corr.length; i++) {
      final value = complexAbs(corr[i]);
      if (value > maxVal) {
        maxVal = value;
        maxIndex = i;
      }
    }

    var delay = maxIndex;
    if (maxIndex > n / 2) {
      delay = maxIndex - n;
    }

    final timeDelay = delay / sampleRate;
    final maxDelay = micDistance / soundSpeed;
    final clamped = (timeDelay / maxDelay).clamp(-1.0, 1.0);
    return math.asin(clamped);
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

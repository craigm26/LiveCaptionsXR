// import 'dart:ffi'; // Not available on web
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:scidart/numdart.dart';
import 'package:scidart/scidart.dart';
import 'package:flutter/services.dart';

import 'stereo_audio_capture.dart';
import 'debug_capturing_logger.dart';

/// Basic audio direction estimation using RMS amplitude comparison.
///
/// This implements the algorithm described in `prd/02_basic_audio_direction_estimation.md`.
/// It calculates the root mean square (RMS) value of the left and right channels
/// of a [StereoAudioFrame] and converts the normalized difference into a
/// horizontal angle in radians (negative = left, positive = right).
class SpeechLocalizer {
  static final DebugCapturingLogger _logger = DebugCapturingLogger();
  
  /// Minimum RMS to consider a frame as valid speech (tune as needed)
  final double minRmsThreshold;
  /// Smoothing factor for exponential moving average (0 = no smoothing, 1 = max smoothing)
  final double smoothing;

  double _lastAngle = 0.0;

  SpeechLocalizer({this.minRmsThreshold = 0.01, this.smoothing = 0.2}) {
    _logger.i('🏗️ Initializing SpeechLocalizer...');
    _logger.d('RMS threshold: $minRmsThreshold, Smoothing: $smoothing');
  }

  // static const MethodChannel _channel =
  //     MethodChannel('live_captions_xr/speech_localizer');

  // /// Basic amplitude-based direction estimation (native).
  // static Future<double> estimateDirectionNative({
  //   required Float32List left,
  //   required Float32List right,
  //   double sampleRate = 16000.0,
  // }) async {
  //   final result = await _channel.invokeMethod<double>(
  //     'estimateDirection',
  //     {
  //       'left': left,
  //       'right': right,
  //       'sampleRate': sampleRate,
  //     },
  //   );
  //   if (result == null) throw Exception('No result from native code');
  //   return result;
  // }

  // /// Advanced GCC-PHAT direction estimation (native).
  // static Future<double> estimateDirectionAdvancedNative({
  //   required Float32List left,
  //   required Float32List right,
  //   double sampleRate = 16000.0,
  //   double micDistance = 0.08,
  //   double soundSpeed = 343.0,
  // }) async {
  //   final result = await _channel.invokeMethod<double>(
  //     'estimateDirectionAdvanced',
  //     {
  //       'left': left,
  //       'right': right,
  //       'sampleRate': sampleRate,
  //       'micDistance': micDistance,
  //       'soundSpeed': soundSpeed,
  //     },
  //   );
  //   if (result == null) throw Exception('No result from native code');
  //   return result;
  // }

  /// Estimate horizontal angle from a stereo audio frame.
  ///
  /// Returns an angle in radians between `-pi/2` (full left) and `pi/2` (full right).
  double estimateDirection(StereoAudioFrame frame) {
    final leftRms = _rms(frame.left);
    final rightRms = _rms(frame.right);
    final sum = leftRms + rightRms;
    if (sum < minRmsThreshold) {
      // Too quiet, treat as center or hold last value
      return _lastAngle;
    }
    final diff = leftRms - rightRms;
    final normalized = (diff / sum).clamp(-1.0, 1.0);
    final angle = normalized * (math.pi / 2);

    // Exponential moving average smoothing
    _lastAngle = smoothing * _lastAngle + (1 - smoothing) * angle;
    return _lastAngle;
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
    final left = Array(frame.left.toList() as List<double>);
    final right = Array(frame.right.toList() as List<double>);

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
    double sum = 0.0;
    for (var i = 0; i < samples.length; i++) {
      final v = samples[i];
      sum += v * v;
    }
    return math.sqrt(sum / samples.length);
  }
}

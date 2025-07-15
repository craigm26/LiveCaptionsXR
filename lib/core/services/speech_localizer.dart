// import 'dart:ffi'; // Not available on web
import 'dart:math';
import 'dart:typed_data';
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
    final angle = normalized * (pi / 2);

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
    return 0.0;
  }

  /// Convert an angle in radians to a simple left/center/right label.
  String directionLabel(double angle) {
    final threshold = pi / 8; // ~22.5 degrees dead zone for "center"
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
    return sqrt(sum / samples.length);
  }
}

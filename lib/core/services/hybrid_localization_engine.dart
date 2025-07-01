import 'package:flutter/services.dart';

/// Dart wrapper for the native HybridLocalizationEngine (iOS/Android).
/// Provides Kalman filter fusion of audio, vision, and IMU for AR anchor placement.
class HybridLocalizationEngine {
  static const MethodChannel _channel = MethodChannel('live_captions_xr/hybrid_localization_methods');

  /// Predict step (advances state based on elapsed time).
  Future<void> predict() async {
    await _channel.invokeMethod('predict');
  }

  /// Update with audio measurement (angle in radians, confidence 0-1, deviceTransform as 16 doubles, row-major).
  Future<void> updateWithAudioMeasurement({
    required double angle,
    required double confidence,
    required List<double> deviceTransform,
  }) async {
    await _channel.invokeMethod('updateWithAudioMeasurement', {
      'angle': angle,
      'confidence': confidence,
      'deviceTransform': deviceTransform,
    });
  }

  /// Update with visual measurement (transform as 16 doubles, row-major, confidence 0-1).
  Future<void> updateWithVisualMeasurement({
    required List<double> transform,
    required double confidence,
  }) async {
    await _channel.invokeMethod('updateWithVisualMeasurement', {
      'transform': transform,
      'confidence': confidence,
    });
  }

  /// Get the fused world transform (returns 16 doubles, row-major 4x4 matrix).
  Future<List<double>> getFusedTransform() async {
    final result = await _channel.invokeMethod<List<dynamic>>('getFusedTransform');
    if (result == null) throw Exception('No fused transform returned');
    return result.cast<double>();
  }

  /// Place a caption at the current fused transform in AR (native).
  Future<void> placeCaption(String text) async {
    final transform = await getFusedTransform();
    await const MethodChannel('live_captions_xr/caption_methods').invokeMethod('placeCaption', {
      'transform': transform,
      'text': text,
    });
  }
} 
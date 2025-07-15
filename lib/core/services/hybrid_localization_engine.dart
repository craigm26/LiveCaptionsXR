import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'debug_capturing_logger.dart';

/// Dart wrapper for the native HybridLocalizationEngine (iOS/Android).
/// Provides Kalman filter fusion of audio, vision, and IMU for AR anchor placement.
class HybridLocalizationEngine {
  static const MethodChannel _channel =
      MethodChannel('live_captions_xr/hybrid_localization_methods');

  static final DebugCapturingLogger _logger = DebugCapturingLogger();

  /// Predict step (advances state based on elapsed time).
  Future<void> predict() async {
    try {
      _logger.d('🔮 Executing prediction step for hybrid localization...');
      await _channel.invokeMethod('predict');
      _logger.d('✅ Prediction step completed successfully');
    } on PlatformException catch (e, stackTrace) {
      _logger.e('❌ Platform error during prediction step',
          error: e, stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('❌ Unexpected error during prediction step',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Update with audio measurement (angle in radians, confidence 0-1, deviceTransform as 16 doubles, row-major).
  Future<void> updateWithAudioMeasurement({
    required double angle,
    required double confidence,
    required List<double> deviceTransform,
  }) async {
    try {
      _logger.d(
          '🎙️ Updating with audio measurement - angle: ${angle.toStringAsFixed(3)} rad, confidence: ${confidence.toStringAsFixed(3)}');
      await _channel.invokeMethod('updateWithAudioMeasurement', {
        'angle': angle,
        'confidence': confidence,
        'deviceTransform': deviceTransform,
      });
      _logger.d('✅ Audio measurement update completed successfully');
    } on PlatformException catch (e, stackTrace) {
      _logger.e('❌ Platform error updating audio measurement',
          error: e, stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('❌ Unexpected error updating audio measurement',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Update with visual measurement (transform as 16 doubles, row-major, confidence 0-1).
  Future<void> updateWithVisualMeasurement({
    required List<double> transform,
    required double confidence,
  }) async {
    try {
      _logger.d(
          '👁️ Updating with visual measurement - confidence: ${confidence.toStringAsFixed(3)}, transform length: ${transform.length}');
      await _channel.invokeMethod('updateWithVisualMeasurement', {
        'transform': transform,
        'confidence': confidence,
      });
      _logger.d('✅ Visual measurement update completed successfully');
    } on PlatformException catch (e, stackTrace) {
      _logger.e('❌ Platform error updating visual measurement',
          error: e, stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('❌ Unexpected error updating visual measurement',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Get the fused world transform (returns 16 doubles, row-major 4x4 matrix).
  Future<List<double>> getFusedTransform() async {
    try {
      _logger.d('🔄 Requesting fused transform from hybrid localization...');
      final result =
          await _channel.invokeMethod<List<dynamic>>('getFusedTransform');
      if (result == null) {
        _logger.e('❌ No fused transform returned from native side');
        throw Exception('No fused transform returned');
      }
      final fusedTransform = result.cast<double>();
      _logger.d(
          '✅ Fused transform retrieved successfully - length: ${fusedTransform.length}');
      return fusedTransform;
    } on PlatformException catch (e, stackTrace) {
      _logger.e('❌ Platform error getting fused transform',
          error: e, stackTrace: stackTrace);
      rethrow;
    } catch (e, stackTrace) {
      _logger.e('❌ Unexpected error getting fused transform',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Place a real-time caption at the current fused transform in AR.
  Future<void> placeRealtimeCaption(String text) async {
    try {
      _logger.i('🎯 Placing real-time caption in AR: "$text"');
      final transform = await getFusedTransform();
      
      await const MethodChannel('live_captions_xr/caption_methods')
          .invokeMethod('placeCaption', {
        'transform': transform,
        'text': text,
        'isSummary': false,
      });
      
      _logger.i('✅ Real-time caption placed successfully.');
    } on PlatformException catch (e) {
      _logger.e('❌ Platform error placing real-time caption: ${e.message}');
      throw Exception('Failed to place real-time caption: ${e.message}');
    }
  }

  /// Place a contextual summary at a stable, centered position.
  Future<void> placeContextualSummary(String text) async {
    try {
      _logger.i('✨ Placing contextual summary in AR: "$text"');
      
      // For summaries, we might use a default, stable transform 
      // (e.g., 2 meters in front of the user) instead of the dynamic fused transform.
      final stableTransform = List.generate(16, (i) => (i % 5 == 0) ? 1.0 : 0.0);
      stableTransform[14] = -2.0; // 2 meters in front

      await const MethodChannel('live_captions_xr/caption_methods')
          .invokeMethod('placeCaption', {
        'transform': stableTransform,
        'text': text,
        'isSummary': true,
      });
      
      _logger.i('✅ Contextual summary placed successfully.');
    } on PlatformException catch (e) {
      _logger.e('❌ Platform error placing contextual summary: ${e.message}');
      throw Exception('Failed to place contextual summary: ${e.message}');
    }
  }
}

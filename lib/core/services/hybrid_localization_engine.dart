import 'package:flutter/services.dart';
import 'app_logger.dart';

/// Dart wrapper for the native HybridLocalizationEngine (iOS/Android).
/// Provides Kalman filter fusion of audio, vision, and IMU for AR anchor placement.
class HybridLocalizationEngine {
  static const MethodChannel _channel =
      MethodChannel('live_captions_xr/hybrid_localization_methods');

  static final AppLogger _logger = AppLogger.instance;

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

  /// Feed audio direction measurement to the hybrid localization system
  /// This method integrates audio-based speaker localization with the spatial caption system
  Future<void> feedAudioDirection({
    required double angle,
    required double confidence,
    List<double>? deviceTransform,
  }) async {
    try {
      _logger.d('🎯 Feeding audio direction to hybrid localization: ${angle.toStringAsFixed(3)} rad');
      
      // If no device transform provided, use identity matrix
      final transform = deviceTransform ?? List.filled(16, 0.0)..setAll(0, [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
      
      // Update the hybrid localization engine
      await updateWithAudioMeasurement(
        angle: angle,
        confidence: confidence,
        deviceTransform: transform,
      );
      
      // Execute prediction step to update state
      await predict();
      
      _logger.d('✅ Audio direction successfully integrated with hybrid localization');
    } catch (e, stackTrace) {
      _logger.e('❌ Error feeding audio direction to hybrid localization',
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
      final result =
          await _channel.invokeMethod<List<dynamic>>('getFusedTransform');
      if (result == null) {
        _logger.e('❌ No fused transform returned from native side', category: LogCategory.ar);
        // Return default transform: identity matrix with 2m forward offset
        _logger.w('⚠️ Using default transform (2m in front of camera)', category: LogCategory.ar);
        final defaultTransform = List<double>.generate(16, (i) => (i % 5 == 0) ? 1.0 : 0.0);
        defaultTransform[14] = -0.5; // 0.5 meters in front (closer for better visibility)
        return defaultTransform;
      }
      final fusedTransform = result.cast<double>();
      return fusedTransform;
    } on PlatformException catch (e, stackTrace) {
      _logger.e('❌ Platform error getting fused transform: ${e.code} - ${e.message}',
          category: LogCategory.ar, error: e, stackTrace: stackTrace);
      // Return default transform on error
      _logger.w('⚠️ Using default transform due to error (2m in front of camera)', category: LogCategory.ar);
      final defaultTransform = List<double>.generate(16, (i) => (i % 5 == 0) ? 1.0 : 0.0);
      defaultTransform[14] = -2.0; // 2 meters in front
      return defaultTransform;
    } catch (e, stackTrace) {
      _logger.e('❌ Unexpected error getting fused transform',
          category: LogCategory.ar, error: e, stackTrace: stackTrace);
      // Return default transform on error
      _logger.w('⚠️ Using default transform due to error (2m in front of camera)', category: LogCategory.ar);
      final defaultTransform = List<double>.generate(16, (i) => (i % 5 == 0) ? 1.0 : 0.0);
      defaultTransform[14] = -2.0; // 2 meters in front
      return defaultTransform;
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
